import 'package:flutter_test/flutter_test.dart';
import 'package:agribank_alert/core/services/vietnamese_number_to_words.dart';
import 'package:agribank_alert/core/services/notification_parser.dart';

void main() {
  group('VietnameseNumberToWords Tests', () {
    test('Converts 500,000 correctly', () {
      final words = VietnameseNumberToWords.convert(500000);
      expect(words, equals('năm trăm nghìn đồng'));
    });

    test('Converts 1,250,000 correctly', () {
      final words = VietnameseNumberToWords.convert(1250000);
      expect(words, equals('một triệu hai trăm năm mươi nghìn đồng'));
    });

    test('Converts 10,000,000 correctly', () {
      final words = VietnameseNumberToWords.convert(10000000);
      expect(words, equals('mười triệu đồng'));
    });

    test('Converts 205,000 correctly', () {
      final words = VietnameseNumberToWords.convert(205000);
      expect(words, equals('hai trăm lẻ năm nghìn đồng'));
    });
  });

  group('NotificationParser Tests', () {
    test('Parses Agribank OTT money received notification', () {
      const title = 'Agribank Alert';
      const body = 'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien';

      final result = NotificationParser.parse(
        rawTitle: title,
        rawContent: body,
        deviceId: 'device-test',
      );

      expect(result.isValidTransaction, isTrue);
      expect(result.isCredit, isTrue);
      expect(result.alert, isNotNull);
      expect(result.alert!.amount, equals(500000));
      expect(result.alert!.accountNumber, equals('1500205123456'));
      expect(result.alert!.senderName, contains('NGUYEN VAN A chuyen tien'));
    });

    test('Rejects Debit (tiền ra) transaction', () {
      const title = 'Agribank';
      const body = 'TK 1500205xxxxxx: -200,000 VND lúc 10:00. ND: Rut tien ATM';

      final result = NotificationParser.parse(
        rawTitle: title,
        rawContent: body,
        deviceId: 'device-test',
      );

      expect(result.isCredit, isFalse);
      expect(result.rejectReason, contains('Debit'));
    });

    test('Rejects OTP / Security message', () {
      const title = 'Agribank';
      const body = 'Ma OTP cua quy khach la 849201. Khong chia se ma nay cho bat ky ai.';

      final result = NotificationParser.parse(
        rawTitle: title,
        rawContent: body,
        deviceId: 'device-test',
      );

      expect(result.isValidTransaction, isFalse);
      expect(result.rejectReason, contains('từ khóa bỏ qua/bảo mật'));
    });
  });
}
