import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/alert_provider.dart';
import '../widgets/transaction_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final history = alertProvider.history.where((alert) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final amountStr = alert.amount.toInt().toString();
      final sender = alert.senderName?.toLowerCase() ?? '';
      final acc = alert.accountNumber?.toLowerCase() ?? '';
      return amountStr.contains(q) || sender.contains(q) || acc.contains(q);
    }).toList();

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final totalAmount = history.fold(0.0, (sum, a) => sum + (a.isCredit ? a.amount : 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Biến Động Số Dư'),
        actions: [
          if (alertProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Xóa lịch sử',
              onPressed: () => _confirmClearHistory(context, alertProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo số tiền, nội dung, tài khoản...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          // Total Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${history.length} giao dịch',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tổng: +${currencyFormat.format(totalAmount)} VND',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.creditGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // List of Transactions
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy giao dịch nào khớp với tìm kiếm'
                              : 'Chưa có lịch sử giao dịch nào được ghi nhận',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final alert = history[index];
                      return TransactionCard(
                        alert: alert,
                        onReplayVoice: () => alertProvider.replayAlertVoice(alert),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, AlertProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text('Hành động này sẽ xóa danh sách tất cả các biến động số dư đã lưu trên thiết bị này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.debitRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
