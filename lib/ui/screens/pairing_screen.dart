import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pairing_provider.dart';
import '../../providers/settings_provider.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();
  bool _isEditingServer = false;
  bool _isTestingServer = false;
  String? _serverTestResult;
  bool? _serverTestSuccess;

  @override
  void initState() {
    super.initState();
    final pairing = context.read<PairingProvider>();
    _serverController.text = pairing.pairingInfo.serverUrl ?? '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _handleTestServer() async {
    final pairing = context.read<PairingProvider>();
    final urlToTest = _serverController.text.trim();
    if (urlToTest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ server trước khi kiểm tra')),
      );
      return;
    }

    setState(() {
      _isTestingServer = true;
      _serverTestResult = 'Đang kết nối tới server (chờ tối đa 45s)...';
      _serverTestSuccess = null;
    });

    final result = await pairing.testServerConnection(urlToTest);

    if (mounted) {
      setState(() {
        _isTestingServer = false;
        _serverTestSuccess = result.success;
        _serverTestResult = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairing = context.watch<PairingProvider>();
    final settings = context.watch<SettingsProvider>();
    final info = pairing.pairingInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép Cặp Thiết Bị'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mã ghép nối của thiết bị này
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    const Text(
                      'MÃ GHÉP NỐI CỦA MÁY NÀY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                info.pairCode ?? '------',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                            tooltip: 'Sao chép mã',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (info.pairCode != null) {
                                Clipboard.setData(ClipboardData(text: info.pairCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép mã ghép nối!')),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 20),
                            tooltip: 'Tạo mã mới',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => pairing.generateNewPairCode(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Định danh thiết bị: ${info.deviceId} (${settings.deviceName})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Trạng thái ghép cặp hiện tại
            if (info.isPaired) ...[
              Card(
                color: AppColors.creditGreen.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.creditGreen, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: AppColors.creditGreen),
                          SizedBox(width: 8),
                          Text(
                            'ĐÃ KẾT NỐI VỚI THIẾT BỊ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.creditGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tên máy đối tác: ${info.pairedDeviceName ?? 'Thiết bị Agribank B'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID đối tác: ${info.pairedDeviceId ?? 'Không xác định'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.link_off_rounded, color: AppColors.debitRed),
                          label: const Text('Hủy ghép cặp', style: TextStyle(color: AppColors.debitRed)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.debitRed),
                          ),
                          onPressed: () => pairing.unpair(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // 3. Form kết nối đến máy đối tác
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KẾT NỐI ĐẾN MÁY ĐỐI TÁC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cách 1: Nút Tự động kết nối 1-click
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: pairing.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.bolt_rounded),
                          label: const Text(
                            'Ghép Cặp Tự Động (Auto-Pair)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pairing.isLoading
                              ? null
                              : () async {
                                  final success = await pairing.autoPair();
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(pairing.successMessage ?? 'Ghép cặp thành công!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(pairing.errorMessage ?? 'Không tìm thấy thiết bị đối tác'),
                                          backgroundColor: AppColors.debitRed,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 Tự động ghép 2 máy đang cùng kết nối vào Server mà không cần gõ mã.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'HOẶC NHẬP MÃ',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã ghép nối (VD: AG-5832)',
                          prefixIcon: const Icon(Icons.vpn_key_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: pairing.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.link_rounded),
                          label: const Text('Kết Nối Bằng Mã', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pairing.isLoading
                              ? null
                              : () async {
                                  final code = _codeController.text.trim();
                                  if (code.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng nhập mã ghép nối')),
                                    );
                                    return;
                                  }
                                  final success = await pairing.pairWithCode(code);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(pairing.successMessage ?? 'Ghép cặp thành công!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(pairing.errorMessage ?? 'Ghép cặp thất bại'),
                                          backgroundColor: AppColors.debitRed,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Cấu hình Máy chủ / Cloud Relay (Render.com)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CẤU HÌNH MÁY CHỦ CHUYỂN TIẾP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isEditingServer ? Icons.check_circle : Icons.edit_note_rounded),
                          onPressed: () async {
                            if (_isEditingServer) {
                              await pairing.setServerUrl(_serverController.text);
                              _serverController.text = pairing.pairingInfo.serverUrl ?? '';
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã chuẩn hóa và lưu địa chỉ máy chủ')),
                                );
                              }
                            }
                            setState(() => _isEditingServer = !_isEditingServer);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_isEditingServer)
                      TextField(
                        controller: _serverController,
                        decoration: InputDecoration(
                          hintText: 'https://ten-app-cua-ban.onrender.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      )
                    else
                      Text(
                        (info.serverUrl != null && info.serverUrl!.isNotEmpty)
                            ? info.serverUrl!
                            : 'Chưa cấu hình (Hãy nhập link Render.com để hoạt động từ xa)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (info.serverUrl != null && info.serverUrl!.isNotEmpty)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: (info.serverUrl != null && info.serverUrl!.isNotEmpty)
                              ? Colors.black87
                              : Colors.orange.shade800,
                        ),
                      ),

                    const SizedBox(height: 12),
                    // Nút kiểm tra kết nối Server
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: _isTestingServer
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering_rounded, size: 18),
                          label: Text(_isTestingServer ? 'Đang kiểm tra...' : 'Kiểm tra Server'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _isTestingServer ? null : _handleTestServer,
                        ),
                        const SizedBox(width: 8),
                        if (_serverTestSuccess != null)
                          Expanded(
                            child: Text(
                              _serverTestSuccess! ? '✅ Hoạt động tốt' : '❌ Lỗi kết nối',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _serverTestSuccess! ? AppColors.creditGreen : AppColors.debitRed,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (_serverTestResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_serverTestSuccess == true)
                              ? Colors.green.shade50
                              : (_serverTestSuccess == false)
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _serverTestResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: (_serverTestSuccess == true)
                                ? Colors.green.shade900
                                : (_serverTestSuccess == false)
                                    ? Colors.red.shade900
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Hướng dẫn sử dụng
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '💡 Hướng dẫn ghép cặp 2 điện thoại qua Render.com:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Cả Điện thoại A (có Agribank) và Điện thoại B (Loa) cùng nhập link Server (VD: https://agribank-alert.onrender.com).\n'
                    '2. Bấm "Kiểm tra Server" xem máy chủ đã sẵn sàng chưa (gói Render miễn phí mất ~40s để thức dậy nếu lâu không dùng).\n'
                    '3. Bấm nút "Ghép Cặp Tự Động (Auto-Pair)" trên một trong 2 máy để tự động kết nối ngay lập tức!\n'
                    '4. Khi đã ghép cặp thành công, máy A sẽ gửi tức thì thông báo tiền vào sang máy B.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
