import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_badge.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  /// When [showDate] is true the formatted date is shown beneath the badge.
  /// Dashboard passes false (compact); TransactionsScreen passes true.
  final bool showDate;

  const TransactionTile({super.key, required this.tx, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final merchant = tx['merchant'] as String? ?? 'Unknown';
    final category = tx['category'] as String? ?? 'Other';
    final amount   = (tx['amount'] as num).toDouble();
    final type     = tx['type'] as String? ?? 'debit';
    final date     = tx['transaction_date'] as String? ?? '';
    final isCredit = type == 'credit';
    final icon     = context.read<CategoryProvider>().forName(category).icon;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      blur: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: c.surfaceLight,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Merchant + badge + optional date — takes all remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Badge + date in a Wrap so they never overflow each other
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CategoryBadge(category: category),
                    if (showDate && date.isNotEmpty)
                      Text(
                        _formatDate(date),
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Amount — fixed to its intrinsic width, never compresses the left side
          Text(
            '${isCredit ? '+' : '-'}₦${fmtNumber(amount.abs().round())}',
            style: AppTheme.monoSized(
              15,
              color: isCredit ? AppColors.success : AppColors.destructive,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
