import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/transaction_alert.dart';
import 'vietnamese_number_to_words.dart';

class ParseResult {
  final bool isValidTransaction;
  final bool isCredit;
  final TransactionAlert? alert;
  final String? rejectReason;

  ParseResult({
    required this.isValidTransaction,
    required this.isCredit,
    this.alert,
    this.rejectReason,
  });
}

class NotificationParser {
  // Bộ lọc từ khóa bảo mật / quảng cáo cần loại bỏ ngay
  static final List<String> _ignoredKeywords = [
    'mã otp',
    'ma otp',
    'otp',
    'mật khẩu',
    'mat khau',
    'đăng nhập',
    'dang nhap',
    'cảnh báo',
    'canh bao',
    'ưu đãi',
    'uu dai',
    'khuyến mại',
    'khuyen mai',
    'quảng cáo',
    'quang cao',
    'tri ân',
    'chúc mừng',
    'chuc mung',
  ];

  // Từ khóa tiền ra (Debit)
  static final List<String> _debitKeywords = [
    'rút tiền',
    'rut tien',
    'thanh toán',
    'thanh toan',
    'trừ tiền',
    'tru tien',
    'chuyển tiền đến',
    'chuyen tien den',
    'phí duy trì',
    'phi dich vu',
  ];

  // Từ khóa tiền vào (Credit)
  static final List<String> _creditKeywords = [
    'nhận tiền',
    'nhan tien',
    'tiền vào',
    'tien vao',
    'cộng tiền',
    'cong tien',
    'vừa nhận',
    'vua nhan',
    'chuyển khoản đến',
    'tang',
  ];

  /// Phân tích thông báo từ Android StatusBarNotification
  static ParseResult parse({
    required String rawTitle,
    required String rawContent,
    String? subText,
    String? bigText,
    required String deviceId,
    DateTime? occurredAt,
  }) {
    // Kết hợp tất cả nội dung lại để phân tích
    final fullText = [
      rawTitle,
      rawContent,
      if (subText != null && subText.isNotEmpty) subText,
      if (bigText != null && bigText.isNotEmpty) bigText,
    ].join(' ').trim();

    final lowerText = fullText.toLowerCase();

    // 1. Kiểm tra từ khóa bỏ qua (OTP, khuyến mại, bảo mật...)
    for (final kw in _ignoredKeywords) {
      if (lowerText.contains(kw)) {
        return ParseResult(
          isValidTransaction: false,
          isCredit: false,
          rejectReason: 'Chứa từ khóa bỏ qua/bảo mật: $kw',
        );
      }
    }

    // 2. Kiểm tra dấu hiệu trừ tiền (Debit)
    bool hasMinusSign = lowerText.contains(RegExp(r'-\s*[0-9]+'));
    bool hasDebitKw = _debitKeywords.any((kw) => lowerText.contains(kw));

    if (hasMinusSign || hasDebitKw) {
      return ParseResult(
        isValidTransaction: true,
        isCredit: false,
        rejectReason: 'Giao dịch trừ tiền (Debit) - Hệ thống chỉ theo dõi tiền vào',
      );
    }

    // 3. Kiểm tra dấu hiệu tiền vào (Credit)
    bool hasPlusSign = lowerText.contains(RegExp(r'\+\s*[0-9]+'));
    bool hasCreditKw = _creditKeywords.any((kw) => lowerText.contains(kw));

    if (!hasPlusSign && !hasCreditKw) {
      return ParseResult(
        isValidTransaction: false,
        isCredit: false,
        rejectReason: 'Không tìm thấy dấu hiệu giao dịch nhận tiền (+ hoặc từ khóa nhận tiền)',
      );
    }

    // 4. Trích xuất số tiền
    final amount = _extractAmount(fullText);
    if (amount == null || amount <= 0) {
      return ParseResult(
        isValidTransaction: false,
        isCredit: true,
        rejectReason: 'Không trích xuất được số tiền hợp lệ',
      );
    }

    // 5. Trích xuất thông tin bổ sung (Số tài khoản, Nội dung giao dịch, Mã tham chiếu)
    final accountNumber = _extractAccountNumber(fullText);
    final senderName = _extractSenderOrContent(fullText);
    final referenceCode = _extractRefCode(fullText);

    // 6. Tạo Event ID duy nhất dựa trên hash (để chống gửi/đọc trùng)
    final time = occurredAt ?? DateTime.now();
    // Làm tròn thời gian trong phạm vi 3 phút để chống trùng lặp thông báo đẩy đúp
    final timeBucket = '${time.year}-${time.month}-${time.day} ${time.hour}:${(time.minute ~/ 3) * 3}';
    final rawHash = '$amount-$accountNumber-$referenceCode-$timeBucket';
    final eventId = md5.convert(utf8.encode(rawHash)).toString();

    // 7. Tạo văn bản đọc giọng nói tự nhiên
    final amountWords = VietnameseNumberToWords.convert(amount);
    final spokenText = 'Bạn vừa nhận $amountWords';

    final alert = TransactionAlert(
      eventId: eventId,
      deviceId: deviceId,
      amount: amount,
      currency: 'VND',
      direction: 'credit',
      occurredAt: time,
      accountNumber: accountNumber,
      senderName: senderName,
      referenceCode: referenceCode,
      rawTitle: rawTitle,
      rawContent: rawContent,
      bank: 'Agribank',
      spokenText: spokenText,
    );

    return ParseResult(
      isValidTransaction: true,
      isCredit: true,
      alert: alert,
    );
  }

  /// Trích xuất số tiền nhận được
  static double? _extractAmount(String text) {
    // Ưu tiên mẫu có dấu + đằng trước: +500,000 VND hoặc +500.000 đ
    final plusRegex = RegExp(
      r'\+\s*([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]+)\s*(?:VND|VNĐ|đ|d)?',
      caseSensitive: false,
    );
    final plusMatch = plusRegex.firstMatch(text);
    if (plusMatch != null) {
      final rawNum = plusMatch.group(1)!;
      return _cleanNumber(rawNum);
    }

    // Mẫu thông báo: nhận 500,000 VND hoặc vừa nhận 1.000.000 đ
    final kwRegex = RegExp(
      r'(?:nhận|nhan|cộng|cong|vào|tang)\s*[:\s]*([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]+)\s*(?:VND|VNĐ|đ|d)',
      caseSensitive: false,
    );
    final kwMatch = kwRegex.firstMatch(text);
    if (kwMatch != null) {
      final rawNum = kwMatch.group(1)!;
      return _cleanNumber(rawNum);
    }

    // Mẫu bất kỳ có số tiền với đơn vị VND/đ
    final genericRegex = RegExp(
      r'([0-9]{1,3}(?:[.,][0-9]{3})+)\s*(?:VND|VNĐ|đ|d)',
      caseSensitive: false,
    );
    final genericMatch = genericRegex.firstMatch(text);
    if (genericMatch != null) {
      final rawNum = genericMatch.group(1)!;
      return _cleanNumber(rawNum);
    }

    return null;
  }

  static double? _cleanNumber(String raw) {
    // Loại bỏ dấu chấm, phẩy phân cách hàng nghìn
    String cleaned = raw.replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned);
  }

  static String? _extractAccountNumber(String text) {
    final regex = RegExp(
      r'(?:TK|Tài khoản|Tai khoan)\s*([0-9xX]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  static String? _extractSenderOrContent(String text) {
    final regex = RegExp(
      r'(?:ND|Nội dung|Noi dung|từ|tu)\s*:\s*([^.\n]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String? _extractRefCode(String text) {
    final regex = RegExp(
      r'(?:Ref|Mã GD|Ma GD|Số GD)\s*:\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }
}
