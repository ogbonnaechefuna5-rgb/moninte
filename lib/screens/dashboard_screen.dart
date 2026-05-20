import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_badge.dart';
import '../widgets/notification_pane.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../providers/preferences_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const DashboardScreen({super.key, this.onProfileTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hideBalances = context.watch<PreferencesProvider>().hideBalances;
    final user = context.watch<AuthProvider>().user;
    final firstName = user?['first_name'] as String? ?? '';
    final lastName = user?['last_name'] as String? ?? '';
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
    final greeting = _greeting();

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }

    final netWorth = (_data?['netWorth'] as num?)?.toDouble() ?? 0;
    final banks = (_data?['banks'] as List?)?.cast<String>() ?? [];
    final thisMonth = (_data?['thisMonth'] as num?)?.toDouble() ?? 0;
    final income = (_data?['income'] as num?)?.toDouble() ?? 0;
    final savingsPct = (_data?['savingsPct'] as num?)?.toInt() ?? 0;
    final monthChange = (_data?['monthChange'] as num?)?.toInt() ?? 0;
    final incomeChange = (_data?['incomeChange'] as num?)?.toInt() ?? 0;
    final savingsChange = (_data?['savingsChange'] as num?)?.toInt() ?? 0;
    final trendData = (_data?['spendingTrend'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final transactions = (_data?['transactions'] as List?) ?? [];
    final budgets = (_data?['budgets'] as List?) ?? [];
    final aiInsight = _data?['aiInsight'] as String? ?? '';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              // ── Greeting header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,\n${firstName.isNotEmpty ? firstName : 'there'} 👋',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text('Here\'s your financial overview', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification bell
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.surfaceDark.withValues(alpha: 0.5),
                            border: Border.all(color: c.borderDefault),
                          ),
                          child: Icon(Icons.notifications_outlined, size: 20, color: c.textSecondary),
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.destructive)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent.withValues(alpha: 0.15),
                        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          initials.isNotEmpty ? initials : '?',
                          style: TextStyle(color: c.accent, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
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
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.05)),
                    )),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Net Worth', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.read<PreferencesProvider>().toggle('hideBalances'),
                              child: Icon(
                                hideBalances ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(hideBalances ? '₦ ****' : '₦${fmtNumber(netWorth.round())}', style: AppTheme.monoSized(34, weight: FontWeight.w700, color: c.textPrimary)),
                        const SizedBox(height: 12),
                        if (banks.isNotEmpty)
                          Wrap(spacing: 8, children: banks.map((b) => _bankBadge(b)).toList()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  Expanded(child: _statCard(context, 'This Month', fmtCurrencyShort(thisMonth), Icons.trending_up, monthChange >= 0 ? AppColors.destructive : AppColors.success, '${monthChange >= 0 ? "+" : ""}$monthChange%')),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard(context, 'Income', fmtCurrencyShort(income), Icons.trending_up, incomeChange >= 0 ? AppColors.success : AppColors.destructive, '${incomeChange >= 0 ? "+" : ""}$incomeChange%')),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard(context, 'Savings', '$savingsPct%', savingsChange >= 0 ? Icons.trending_up : Icons.trending_down, savingsChange >= 0 ? AppColors.success : c.textSecondary, '${savingsChange >= 0 ? "+" : ""}$savingsChange%')),
                ],
              ),

              // Spending Trend
              if (trendData.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spending Trend (7 days)', style: TextStyle(color: c.textSecondary, fontSize: 12)),
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
                                spots: List.generate(trendData.length, (i) => FlSpot(i.toDouble(), trendData[i])),
                                isCurved: true,
                                color: c.accent,
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
              ],

              const SizedBox(height: 24),

              // Recent Transactions
              if (transactions.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                    Row(children: [
                      Text('See all', style: TextStyle(color: c.accent, fontSize: 14)),
                      Icon(Icons.chevron_right, color: c.accent, size: 18),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                ...transactions.map((tx) {
                  final merchant = tx['merchant'] ?? 'Unknown';
                  final category = tx['category'] ?? 'Other';
                  final amount = (tx['amount'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.surfaceLight),
                            child: Center(child: Text(_categoryIcon(category), style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(merchant, style: TextStyle(color: c.textPrimary, fontSize: 14)),
                                const SizedBox(height: 4),
                                CategoryBadge(category: category),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${amount < 0 ? "-" : "+"}₦${fmtNumber(amount.abs().round())}',
                              style: AppTheme.monoSized(16, color: amount < 0 ? AppColors.destructive : AppColors.success),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // Budget Progress
              if (budgets.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Budget Progress', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...budgets.map((b) {
                  final category = b['category'] ?? '';
                  final spent = (b['spent'] as num).toDouble();
                  final total = (b['total'] as num).toDouble();
                  final pct = total > 0 ? spent / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(category, style: TextStyle(color: c.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                              Text('₦${fmtNumber(spent.round())} / ₦${fmtNumber(total.round())}',
                                  style: AppTheme.monoSized(12, color: c.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              backgroundColor: c.background.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation(pct > 0.9 ? AppColors.destructive : c.accent),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // AI Insight
              if (aiInsight.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  animate: true,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [c.accent.withValues(alpha: 0.1), AppColors.primaryGreen.withValues(alpha: 0.2)],
                  ),
                  border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.accent.withValues(alpha: 0.2)),
                        child: Icon(Icons.auto_awesome, size: 20, color: c.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(aiInsight, style: TextStyle(color: c.textPrimary, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _bankBadge(String name) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: AppColors.primaryGreen.withValues(alpha: 0.3),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
      ),
      child: Text(name, style: TextStyle(color: c.accent, fontSize: 12)),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color, String change) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.monoSized(20, color: c.textPrimary)),
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

  String _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'food & dining': return '🍔';
      case 'transport': case 'transportation': return '🚗';
      case 'shopping': return '🛒';
      case 'bills': case 'utilities': return '⚡';
      case 'airtime': return '📱';
      case 'entertainment': return '🎬';
      default: return '📦';
    }
  }
}
