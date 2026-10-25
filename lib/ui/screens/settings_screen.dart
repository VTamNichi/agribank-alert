import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/device_role.dart';
import '../../providers/alert_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _nameController.text = settings.deviceName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt Hệ Thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Vai trò thiết bị
          _buildSectionHeader('VAI TRÒ THIẾT BỊ NÀY'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: RadioGroup<DeviceRole>(
              groupValue: settings.role,
              onChanged: (newRole) {
                if (newRole != null) {
                  settings.setRole(newRole);
                }
              },
              child: Column(
                children: DeviceRole.values.map((role) {
                  return RadioListTile<DeviceRole>(
                    title: Text(role.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(role.description, style: const TextStyle(fontSize: 11)),
                    value: role,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Tên thiết bị & Mã định danh
          _buildSectionHeader('ĐỊNH DANH THIẾT BỊ'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên thiết bị',
                      hintText: 'VD: Máy Quầy Thu Ngân 1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: AppColors.primary),
                        onPressed: () {
                          settings.setDeviceName(_nameController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật tên thiết bị!')),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Device ID: ${settings.deviceId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Cài đặt Giọng nói tiếng Việt (TTS)
          _buildSectionHeader('GIỌNG NÓI & PHÁT LOA (TEXT-TO-SPEECH)'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bật giọng đọc số tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Đọc to số tiền bằng tiếng Việt khi nhận biến động số dư', style: TextStyle(fontSize: 12)),
                    value: settings.ttsEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => settings.setTtsEnabled(val),
                  ),
                  const Divider(),
                  const Text('Câu mở đầu thông báo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPrefixChip('Bạn vừa nhận', settings),
                      _buildPrefixChip('Tài khoản vừa cộng', settings),
                      _buildPrefixChip('Agribank thông báo', settings),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Âm lượng:', style: TextStyle(fontSize: 13)),
                      Text('${(settings.ttsVolume * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.ttsVolume,
                    min: 0.1,
                    max: 1.0,
                    activeColor: AppColors.primary,
                    onChanged: (val) => settings.setTtsVolume(val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tốc độ đọc:', style: TextStyle(fontSize: 13)),
                      Text('${settings.ttsRate.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.ttsRate,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    activeColor: AppColors.primary,
                    onChanged: (val) => settings.setTtsRate(val),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Nghe thử phát âm thanh mẫu'),
                      onPressed: () => settings.testTtsVoice(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Bộ lọc hạn mức số tiền (Chỉ bắn thông báo dưới 10 triệu)
          _buildSectionHeader('BỘ LỌC HẠN MỨC SỐ TIỀN'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ bắn thông báo dưới hạn mức', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Tự động bỏ qua các giao dịch từ ${currencyFormat.format(settings.maxAmountLimit)} đ trở lên',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: settings.maxAmountFilterEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => settings.setMaxAmountFilterEnabled(val),
                  ),
                  if (settings.maxAmountFilterEnabled) ...[
                    const Divider(),
                    const Text('Chọn mức trần tối đa:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildLimitChip(5000000, 'Dưới 5 triệu', settings),
                        _buildLimitChip(10000000, 'Dưới 10 triệu (Mặc định)', settings),
                        _buildLimitChip(20000000, 'Dưới 20 triệu', settings),
                        _buildLimitChip(50000000, 'Dưới 50 triệu', settings),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Quyền hệ thống Android
          _buildSectionHeader('QUYỀN HỆ THỐNG ANDROID'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    alertProvider.hasNotificationPermission ? Icons.check_circle : Icons.warning_rounded,
                    color: alertProvider.hasNotificationPermission ? AppColors.creditGreen : AppColors.warningOrange,
                  ),
                  title: const Text('Quyền Notification Access', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cho phép ứng dụng đọc biến động số dư Agribank', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () => alertProvider.requestNotificationPermission(),
                    child: Text(alertProvider.hasNotificationPermission ? 'Cấu hình lại' : 'Cấp quyền'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    alertProvider.isBatteryOptIgnored ? Icons.check_circle : Icons.warning_rounded,
                    color: alertProvider.isBatteryOptIgnored ? AppColors.creditGreen : AppColors.warningOrange,
                  ),
                  title: const Text('Bỏ qua tối ưu pin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Giữ ứng dụng chạy liên tục khi màn hình khóa', style: TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () => alertProvider.requestBatteryOptimization(),
                    child: Text(alertProvider.isBatteryOptIgnored ? 'Đã bật' : 'Bật ngay'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Ứng dụng theo dõi
          _buildSectionHeader('DANH SÁCH PACKAGE THEO DÕI'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Các ứng dụng mà Agribank Alert sẽ lắng nghe thông báo:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...settings.monitoredPackages.map((pkg) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(pkg, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            settings.setMonitoredPackages([
                              'com.vnpay.Agribank3g',
                              'com.google.android.apps.messaging',
                              'com.samsung.android.messaging',
                              'com.android.mms',
                              'com.agribankalert.agribank_alert',
                            ]);
                          },
                          child: const Text('Mặc định (Agribank + SMS)', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            settings.setMonitoredPackages(['*']);
                          },
                          child: const Text('Bắt tất cả để debug (*)', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildPrefixChip(String prefix, SettingsProvider settings) {
    final isSelected = settings.ttsPrefix == prefix;
    return ChoiceChip(
      label: Text(prefix, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (selected) {
        if (selected) settings.setTtsPrefix(prefix);
      },
    );
  }

  Widget _buildLimitChip(double amount, String label, SettingsProvider settings) {
    final isSelected = (settings.maxAmountLimit - amount).abs() < 1;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (selected) {
        if (selected) settings.setMaxAmountLimit(amount);
      },
    );
  }
}
