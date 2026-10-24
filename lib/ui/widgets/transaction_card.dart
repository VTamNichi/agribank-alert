import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/transaction_alert.dart';

class TransactionCard extends StatelessWidget {
  final TransactionAlert alert;
  final VoidCallback? onReplayVoice;

  const TransactionCard({
    super.key,
    required this.alert,
    this.onReplayVoice,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final formattedAmount = currencyFormat.format(alert.amount);
    final timeFormat = DateFormat('HH:mm - dd/MM/yyyy');
    final formattedTime = timeFormat.format(alert.occurredAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: alert.isCredit
              ? AppColors.creditGreen.withValues(alpha: 0.3)
              : AppColors.debitRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alert.isCredit
                            ? AppColors.creditGreen.withValues(alpha: 0.15)
                            : AppColors.debitRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alert.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: alert.isCredit ? AppColors.creditGreen : AppColors.debitRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.isCredit ? 'TIỀN VÀO TÀI KHOẢN' : 'TIỀN RA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: alert.isCredit ? AppColors.creditGreen : AppColors.debitRed,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (onReplayVoice != null && alert.isCredit)
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                    tooltip: 'Đọc lại số tiền',
                    onPressed: onReplayVoice,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${alert.isCredit ? '+' : '-'}$formattedAmount ${alert.currency}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: alert.isCredit ? AppColors.creditGreen : AppColors.debitRed,
              ),
            ),
            const SizedBox(height: 8),
            if (alert.accountNumber != null) ...[
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Tài khoản: ${alert.accountNumber}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (alert.senderName != null && alert.senderName!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nội dung: ${alert.senderName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (alert.referenceCode != null) ...[
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Mã GD: ${alert.referenceCode}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
