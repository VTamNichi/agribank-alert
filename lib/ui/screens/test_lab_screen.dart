import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_listener_service.dart';
import '../../core/services/notification_parser.dart';
import '../../core/services/vietnamese_number_to_words.dart';
import '../../providers/alert_provider.dart';

class TestLabScreen extends StatefulWidget {
  const TestLabScreen({super.key});

  @override
  State<TestLabScreen> createState() => _TestLabScreenState();
}

class _TestLabScreenState extends State<TestLabScreen> {
  final TextEditingController _customTitleController = TextEditingController(text: 'Agribank Alert');
  final TextEditingController _customContentController = TextEditingController(
    text: 'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien',
  );

  ParseResult? _lastResult;
  final NativeNotificationListenerService _nativeListener = NativeNotificationListenerService();

  @override
  void dispose() {
    _customTitleController.dispose();
    _customContentController.dispose();
    super.dispose();
  }

  void _runParserTest(String title, String content) {
    final result = NotificationParser.parse(
      rawTitle: title,
      rawContent: content,
      deviceId: 'test-device-id',
    );
    setState(() {
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Kiểm Thử (Test Lab)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Giới thiệu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.science_rounded, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kiểm tra khả năng nhận diện mẫu thông báo Agribank, bộ lọc chống trùng và phát giọng đọc tiếng Việt tức thì mà không cần chuyển tiền thật.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Kịch bản mẫu thông dụng (1-Click Test Scenarios)
            const Text(
              'CÁC KỊCH BẢN MẪU CHUẨN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),

            // Kịch bản 1: OTT Tiền vào +500K
            _buildScenarioTile(
              title: '1. Agribank OTT (+500,000 VND)',
              description: 'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien',
              expected: 'Hợp lệ -> Tiền vào -> Đọc "năm trăm nghìn đồng"',
              isCredit: true,
              onTest: () {
                _customTitleController.text = 'Agribank Alert';
                _customContentController.text =
                    'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien';
                _runParserTest(_customTitleController.text, _customContentController.text);
                alertProvider.simulateNotification(_customTitleController.text, _customContentController.text);
              },
            ),

            // Kịch bản 2: SMS Tiền vào +1.250.000VND
            _buildScenarioTile(
              title: '2. Agribank SMS (+1.250.000 VND)',
              description: 'TK 1500205xxxxxx +1.250.000VND vao 14:00. So du: 3.500.000VND. Ref: FT260982',
              expected: 'Hợp lệ -> Tiền vào -> Đọc "một triệu hai trăm năm mươi nghìn đồng"',
              isCredit: true,
              onTest: () {
                _customTitleController.text = 'Agribank';
                _customContentController.text =
                    'TK 1500205xxxxxx +1.250.000VND vao 14:00. So du: 3.500.000VND. Ref: FT260982';
                _runParserTest(_customTitleController.text, _customContentController.text);
                alertProvider.simulateNotification(_customTitleController.text, _customContentController.text);
              },
            ),

            // Kịch bản 3: Tiền ra / Debit (-200,000 VND)
            _buildScenarioTile(
              title: '3. Giao dịch rút tiền (-200,000 VND)',
              description: 'TK 1500205xxxxxx: -200,000 VND lúc 10:00. ND: Rut tien ATM',
              expected: 'TỪ CHỐI (Hệ thống tự động bỏ qua vì là tiền ra)',
              isCredit: false,
              onTest: () {
                _customTitleController.text = 'Agribank';
                _customContentController.text =
                    'TK 1500205xxxxxx: -200,000 VND lúc 10:00. ND: Rut tien ATM';
                _runParserTest(_customTitleController.text, _customContentController.text);
                alertProvider.simulateNotification(_customTitleController.text, _customContentController.text);
              },
            ),

            // Kịch bản 4: Tin nhắn OTP / Quảng cáo
            _buildScenarioTile(
              title: '4. Tin nhắn OTP / Khuyến mại',
              description: 'Ma OTP cua quy khach la 849201. Khong chia se ma nay cho bat ky ai.',
              expected: 'TỪ CHỐI (Hệ thống tự động bỏ qua vì chứa từ khóa OTP)',
              isCredit: false,
              onTest: () {
                _customTitleController.text = 'Agribank';
                _customContentController.text =
                    'Ma OTP cua quy khach la 849201. Khong chia se ma nay cho bat ky ai.';
                _runParserTest(_customTitleController.text, _customContentController.text);
                alertProvider.simulateNotification(_customTitleController.text, _customContentController.text);
              },
            ),

            // Kịch bản 5: Giao dịch trên 10 triệu (+15,000,000 VND)
            _buildScenarioTile(
              title: '5. Giao dịch lớn (+15,000,000 VND)',
              description: 'Biến động số dư TK 1500205123456: +15,000,000 VND lúc 15:30. ND: Chuyen tien hop dong',
              expected: 'TỪ CHỐI / BỎ QUA (Chỉ bắn thông báo dưới 10 triệu)',
              isCredit: false,
              onTest: () {
                _customTitleController.text = 'Agribank Alert';
                _customContentController.text =
                    'Biến động số dư TK 1500205123456: +15,000,000 VND lúc 15:30. ND: Chuyen tien hop dong';
                _runParserTest(_customTitleController.text, _customContentController.text);
                alertProvider.simulateNotification(_customTitleController.text, _customContentController.text);
              },
            ),

            const SizedBox(height: 16),

            // 2. Tự nhập mẫu để kiểm tra (Custom Input)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỰ NHẬP NỘI DUNG THÔNG BÁO BẤT KỲ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customTitleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề thông báo (Title)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customContentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Nội dung thông báo (Body / Content)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text('Phân tích'),
                            onPressed: () {
                              _runParserTest(_customTitleController.text, _customContentController.text);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Chạy & Đọc Loa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _runParserTest(_customTitleController.text, _customContentController.text);
                              alertProvider.simulateNotification(
                                _customTitleController.text,
                                _customContentController.text,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Kết quả phân tích (Parser Diagnostics Result)
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _lastResult!.isValidTransaction && _lastResult!.isCredit
                    ? AppColors.creditGreen.withValues(alpha: 0.08)
                    : AppColors.debitRed.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _lastResult!.isValidTransaction && _lastResult!.isCredit
                        ? AppColors.creditGreen
                        : AppColors.debitRed,
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult!.isValidTransaction && _lastResult!.isCredit
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _lastResult!.isValidTransaction && _lastResult!.isCredit
                                ? AppColors.creditGreen
                                : AppColors.debitRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastResult!.isValidTransaction && _lastResult!.isCredit
                                ? 'KẾT QUẢ: HỢP LỆ (TIỀN VÀO)'
                                : 'KẾT QUẢ: TỪ CHỐI / BỎ QUA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _lastResult!.isValidTransaction && _lastResult!.isCredit
                                  ? AppColors.creditGreen
                                  : AppColors.debitRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_lastResult!.rejectReason != null)
                        Text(
                          'Lý do: ${_lastResult!.rejectReason}',
                          style: const TextStyle(fontSize: 12, color: AppColors.debitRed, fontWeight: FontWeight.w600),
                        ),
                      if (_lastResult!.alert != null) ...[
                        Text(
                          'Số tiền nhận: +${currencyFormat.format(_lastResult!.alert!.amount)} VND',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đọc chữ số: ${VietnameseNumberToWords.convert(_lastResult!.alert!.amount)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tài khoản: ${_lastResult!.alert!.accountNumber ?? "Không tìm thấy"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nội dung: ${_lastResult!.alert!.senderName ?? "Không tìm thấy"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Event ID (Chống trùng): ${_lastResult!.alert!.eventId}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 4. Kiểm tra Android Native Notification thật
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KIỂM TRA NOTIFICATION THẬT TRÊN HỆ ĐIỀU HÀNH',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo thông báo thật xuất hiện trên thanh trạng thái Android để kiểm tra xem NotificationListenerService có bắt được không.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('Bắn Thông Báo Thật Vào Thanh Trạng Thái Android'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final success = await _nativeListener.sendTestNotification(
                            title: _customTitleController.text,
                            content: _customContentController.text,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Đã bắn thông báo vào thanh trạng thái Android!'
                                      : 'Không thể bắn thông báo test',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioTile({
    required String title,
    required String description,
    required String expected,
    required bool isCredit,
    required VoidCallback onTest,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(60, 28),
                    backgroundColor: isCredit ? AppColors.creditGreen : Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: onTest,
                  child: const Text('Test ngay', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Kỳ vọng: $expected',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCredit ? AppColors.creditGreen : AppColors.debitRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
