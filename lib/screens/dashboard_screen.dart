import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_badge.dart';
import '../widgets/notification_pane.dart';
import '../models/transaction.dart';
import '../models/budget_category.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _trendData = [45000.0, 52000.0, 48000.0, 61000.0, 55000.0, 67000.0, 58000.0];

  static const _transactions = [
    Transaction('Shoprite', 'Food', -12500, '2h ago', '🛒'),
    Transaction('Bolt', 'Transport', -2800, '5h ago', '🚗'),
    Transaction('Chicken Republic', 'Food', -4500, '1d ago', '🍗'),
    Transaction('MTN Airtime', 'Airtime', -1000, '1d ago', '📱'),
    Transaction('IKEDC Payment', 'Bills', -8500, '2d ago', '⚡'),
  ];

  static const _budgets = [
    BudgetCategory(category: 'Food', emoji: '', spent: 45000, total: 60000, color: Color(0xFFFF8C42), status: 'on-track'),
    BudgetCategory(category: 'Transport', emoji: '', spent: 18000, total: 25000, color: Color(0xFF4D9FFF), status: 'on-track'),
    BudgetCategory(category: 'Bills', emoji: '', spent: 32000, total: 40000, color: Color(0xFFA855F7), status: 'on-track'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good evening, Emmanuel 👋', style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 4),
                      const Text("Here's your financial overview", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const NotificationPane(),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark.withValues(alpha: 0.5),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.destructive)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.primaryGreen]),
                  ),
                  child: const Center(child: Text('EA', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.w600))),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Net Worth Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              animate: true,
              child: Stack(
                children: [
                  Positioned(top: -20, right: -20, child: Container(
                    width: 128, height: 128,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.05)),
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Net Worth', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('₦847,350', style: AppTheme.monoSized(34, weight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: ['GTBank', 'Kuda', 'Opay'].map((b) => _bankBadge(b)).toList()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3-column stats
            Row(
              children: [
                Expanded(child: _statCard('This Month', '₦245K', Icons.trending_up, AppColors.destructive, '+12%')),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Income', '₦450K', Icons.trending_up, AppColors.success, '+5%')),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Savings', '45%', Icons.trending_down, AppColors.textSecondary, '-2%')),
              ],
            ),

            const SizedBox(height: 16),

            // Spending Trend
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending Trend (7 days)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(_trendData.length, (i) => FlSpot(i.toDouble(), _trendData[i])),
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Text('See all', style: TextStyle(color: AppColors.accent, fontSize: 14)),
                    const Icon(Icons.chevron_right, color: AppColors.accent, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_transactions.map((tx) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceLight),
                      child: Center(child: Text(tx.icon, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.merchant, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: [
                            CategoryBadge(category: tx.category),
                            const SizedBox(width: 8),
                            Flexible(child: Text(tx.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${tx.amount < 0 ? "-" : "+"}₦${fmtNumber(tx.amount.abs())}',
                        style: AppTheme.monoSized(16, color: tx.amount < 0 ? AppColors.destructive : AppColors.success),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ))),

            const SizedBox(height: 24),

            // Budget Progress
            Text('Budget Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._budgets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(b.category, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                        Text('₦${fmtNumber(b.spent)} / ₦${fmtNumber(b.total)}',
                            style: AppTheme.monoSized(12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: b.spent / b.total,
                        backgroundColor: AppColors.background.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(b.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 16),

            // AI Insight
            GlassCard(
              padding: const EdgeInsets.all(20),
              animate: true,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.primaryGreen.withValues(alpha: 0.2)],
              ),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              child: Stack(
                children: [
                  Positioned(top: -40, right: -40, child: Container(
                    width: 128, height: 128,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.1)),
                  )),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.accent.withValues(alpha: 0.2)),
                        child: const Icon(Icons.auto_awesome, size: 20, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('You spend 40% more on weekends — want to set a weekend limit?',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent, foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: const Text('Set Limit', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: AppColors.primaryGreen.withValues(alpha: 0.3),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Text(name, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String change) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.monoSized(20)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(change, style: TextStyle(color: color, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  static String _fmt(int v) => fmtNumber(v);
}

class _Tx {
  final String merchant, category, time, icon;
  final int amount;
  const _Tx(this.merchant, this.category, this.amount, this.time, this.icon);
}

class _Budget {
  final String category;
  final int spent, total;
  final Color color;
  const _Budget(this.category, this.spent, this.total, this.color);
}
