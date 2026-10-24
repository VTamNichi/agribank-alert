import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/alert_provider.dart';

class StatusIndicatorCard extends StatelessWidget {
  const StatusIndicatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
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
                  'TRẠNG THÁI HỆ THỐNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alertProvider.isListening
                        ? AppColors.creditGreen.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: alertProvider.isListening ? AppColors.creditGreen : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        alertProvider.isListening ? 'Đang giám sát' : 'Đã dừng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: alertProvider.isListening ? AppColors.creditGreen : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Quyền đọc thông báo (Notification Access)
            _buildStatusItem(
              title: 'Quyền đọc thông báo Android (Notification Access)',
              subtitle: alertProvider.hasNotificationPermission
                  ? 'Đã cấp quyền đọc biến động Agribank'
                  : 'Cần cấp quyền để đọc thông báo từ Agribank',
              isSuccess: alertProvider.hasNotificationPermission,
              actionText: alertProvider.hasNotificationPermission ? null : 'Cấp quyền',
              onAction: () => alertProvider.requestNotificationPermission(),
            ),
            const Divider(height: 20),

            // 2. Chạy ngầm / Tối ưu pin
            _buildStatusItem(
              title: 'Chạy ngầm liên tục (Không bị tắt nguồn)',
              subtitle: alertProvider.isBatteryOptIgnored
                  ? 'Đã bật chế độ không bị ngắt pin'
                  : 'Khuyến nghị bỏ qua tối ưu pin để không bị tắt khi khóa màn hình',
              isSuccess: alertProvider.isBatteryOptIgnored,
              actionText: alertProvider.isBatteryOptIgnored ? null : 'Cấu hình',
              onAction: () => alertProvider.requestBatteryOptimization(),
            ),

            if (alertProvider.lastLog != null && alertProvider.lastLog!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alertProvider.lastLog!,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required String title,
    required String subtitle,
    required bool isSuccess,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
          color: isSuccess ? AppColors.creditGreen : AppColors.warningOrange,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (actionText != null && onAction != null) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 30),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionText, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ],
    );
  }
}
