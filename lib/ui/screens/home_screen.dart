import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/device_role.dart';
import '../../providers/alert_provider.dart';
import '../../providers/pairing_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/status_indicator_card.dart';
import '../widgets/transaction_card.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final pairingProvider = context.watch<PairingProvider>();

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final formattedTotal = currencyFormat.format(alertProvider.totalReceivedToday);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Agribank Alert',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Phòng kiểm thử',
            onPressed: () => onNavigateTab(3), // Tab Test Lab
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => onNavigateTab(4), // Tab Settings
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await alertProvider.checkPermissions();
          await alertProvider.drainPendingNotifications();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thẻ chào mừng & Thông tin vai trò thiết bị
              _buildRoleHeader(context, settingsProvider, pairingProvider),

              // 2. Thẻ Thống kê biến động trong ngày
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TỔNG TIỀN VÀO HÔM NAY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+$formattedTotal đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GIAO DỊCH',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${alertProvider.transactionCountToday}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.creditGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Thẻ Trạng thái hệ thống (Permissions, Listener, Battery)
              const StatusIndicatorCard(),

              // 4. Các nút thao tác nhanh
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text('Thử Loa TTS', style: TextStyle(fontSize: 12)),
                        onPressed: () => settingsProvider.testTtsVoice(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('Giả Lập +500K', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          alertProvider.simulateNotification(
                            'Agribank Alert',
                            'Biến động số dư TK 1500205123456: +500,000 VND lúc 12:30. ND: NGUYEN VAN A chuyen tien',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Giao dịch gần nhất
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giao dịch nhận tiền gần đây',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(1), // Tab History
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),

              if (alertProvider.history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có giao dịch nhận tiền nào',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhấn "Giả Lập +500K" ở trên hoặc chờ thông báo từ Agribank',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...alertProvider.history.take(3).map(
                      (alert) => TransactionCard(
                        alert: alert,
                        onReplayVoice: () => alertProvider.replayAlertVoice(alert),
                      ),
                    ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeader(
    BuildContext context,
    SettingsProvider settings,
    PairingProvider pairing,
  ) {
    final role = settings.role;
    final isPaired = pairing.pairingInfo.isPaired;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              role == DeviceRole.sender
                  ? Icons.phonelink_ring_rounded
                  : (role == DeviceRole.receiver ? Icons.speaker_phone_rounded : Icons.phone_android_rounded),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      role.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaired ? AppColors.creditGreen.withValues(alpha: 0.2) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPaired ? 'Đã ghép cặp' : 'Độc lập',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPaired ? AppColors.creditGreen : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  settings.deviceName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => onNavigateTab(2), // Tab Pairing
            child: const Text('Ghép cặp', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
