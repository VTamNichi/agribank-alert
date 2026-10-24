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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            info.pairCode ?? '------',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                            tooltip: 'Sao chép mã',
                            onPressed: () {
                              if (info.pairCode != null) {
                                Clipboard.setData(ClipboardData(text: info.pairCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép mã ghép nối!')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                            tooltip: 'Tạo mã mới',
                            onPressed: () => pairing.generateNewPairCode(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Định danh thiết bị: ${info.deviceId} (${settings.deviceName})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              // 3. Form nhập mã kết nối từ máy đối tác
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
                          label: const Text('Kết Nối Thiết Bị', style: TextStyle(fontWeight: FontWeight.bold)),
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

            // 4. Cấu hình Máy chủ / Cloud Functions (Tùy chọn)
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã lưu địa chỉ máy chủ')),
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
                          hintText: 'https://asia-southeast1-yourproject.cloudfunctions.net',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      )
                    else
                      Text(
                        (info.serverUrl != null && info.serverUrl!.isNotEmpty)
                            ? info.serverUrl!
                            : 'Mặc định (Chế độ mô phỏng mạng nội bộ / Peer-to-Peer)',
                        style: TextStyle(
                          fontSize: 13,
                          color: (info.serverUrl != null && info.serverUrl!.isNotEmpty)
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
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
                    '💡 Hướng dẫn ghép cặp 2 điện thoại:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Mở Agribank Alert trên cả Điện thoại A (có Agribank) và Điện thoại B (để đọc loa).\n'
                    '2. Trên Điện thoại A: sao chép hoặc đọc Mã Ghép Nối.\n'
                    '3. Trên Điện thoại B: nhập mã này vào ô "Kết Nối Đến Máy Đối Tác" và bấm nút Kết Nối.\n'
                    '4. Khi hiển thị trạng thái "ĐÃ KẾT NỐI", mọi biến động tiền vào trên máy A sẽ tự động chuyển sang máy B để phát loa!',
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
