import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../router.dart';
import '../widgets/glass_card.dart';
import '../widgets/transaction_tile.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/notification_pane.dart';
import '../utils/formatters.dart';
import '../providers/preferences_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().load(),
    );
  }

  Future<void> _refresh() => context.read<DashboardProvider>().load(force: true);

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // Only watch loading+data here to gate the spinner vs content.
    // All per-section provider reads are pushed down into each section widget.
    final dash = context.watch<DashboardProvider>();

    if (dash.loading && dash.data == null) {
      final c = AppColors.of(context);
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }

    final c = AppColors.of(context);
    final data = dash.data;
    final thisMonth = (data?['thisMonth'] as num?)?.toDouble() ?? 0;
    final income = (data?['income'] as num?)?.toDouble() ?? 0;
    final savingsPct = (data?['savingsPct'] as num?)?.toInt() ?? 0;
    final monthChange = (data?['monthChange'] as num?)?.toInt() ?? 0;
    final incomeChange = (data?['incomeChange'] as num?)?.toInt() ?? 0;
    final savingsChange = (data?['savingsChange'] as num?)?.toInt() ?? 0;
    final trendData = (data?['spendingTrend'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final transactions = (data?['transactions'] as List?) ?? [];
    final budgets = (data?['budgets'] as List?) ?? [];
    final aiInsight = data?['aiInsight'] as String? ?? '';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: c.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              // Reads AuthProvider.user — isolated so auth changes only rebuild header.
              _DashboardHeader(greeting: _greeting()),
              const SizedBox(height: 24),
              // Reads PreferencesProvider.hideBalances — isolated so toggling
              // hide-balances only rebuilds this card, not the whole screen.
              _NetWorthCard(
                netWorth: (data?['netWorth'] as num?)?.toDouble() ?? 0,
                banks: (data?['banks'] as List?)?.cast<String>() ?? [],
              ),
              const SizedBox(height: 16),
              _StatsRow(
                thisMonth: thisMonth,
                income: income,
                savingsPct: savingsPct,
                monthChange: monthChange,
                incomeChange: incomeChange,
                savingsChange: savingsChange,
              ),
              if (trendData.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SpendingTrendChart(trendData: trendData),
              ],
              if (transactions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _RecentTransactionsList(transactions: transactions),
              ],
              if (budgets.isNotEmpty) ...[
                const SizedBox(height: 24),
                _BudgetProgressSection(budgets: budgets),
              ],
              if (aiInsight.isNotEmpty) ...[
                const SizedBox(height: 16),
                _AiInsightCard(insight: aiInsight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  const _DashboardHeader({required this.greeting});

  @override
  Widget build(BuildContext context) {
    // Reads only first_name — auth changes rebuild only this widget.
    final firstName = context.select<AuthProvider, String>(
        (a) => a.user?['first_name'] as String? ?? '');
    final c = AppColors.of(context);
    return Row(
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
              Text('Here\'s your financial overview',
                  style: TextStyle(color: c.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
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
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.destructive),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Net Worth Card ────────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final double netWorth;
  final List<String> banks;
  const _NetWorthCard({
    required this.netWorth,
    required this.banks,
  });

  @override
  Widget build(BuildContext context) {
    // Reads only hideBalances — toggling it rebuilds only this card.
    final hideBalances = context.select<PreferencesProvider, bool>(
        (p) => p.hideBalances);
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      animate: true,
      blur: true,
      child: Stack(
        children: [
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 128, height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.05),
              ),
            ),
          ),
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
                      size: 18, color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hideBalances ? '₦ ****' : '₦${fmtNumber(netWorth.round())}',
                style: AppTheme.monoSized(34, weight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(height: 12),
              if (banks.isNotEmpty)
                Wrap(spacing: 8, children: banks.map((b) => _BankBadge(name: b)).toList()),
            ],
          ),
        ],
      ),
    );
  }
}

class _BankBadge extends StatelessWidget {
  final String name;
  const _BankBadge({required this.name});

  @override
  Widget build(BuildContext context) {
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
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final double thisMonth, income;
  final int savingsPct, monthChange, incomeChange, savingsChange;
  const _StatsRow({
    required this.thisMonth,
    required this.income,
    required this.savingsPct,
    required this.monthChange,
    required this.incomeChange,
    required this.savingsChange,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'This Month',
          value: fmtCurrencyShort(thisMonth),
          icon: Icons.trending_up,
          color: monthChange >= 0 ? AppColors.destructive : AppColors.success,
          change: '${monthChange >= 0 ? "+" : ""}$monthChange%',
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(
          label: 'Income',
          value: fmtCurrencyShort(income),
          icon: Icons.trending_up,
          color: incomeChange >= 0 ? AppColors.success : AppColors.destructive,
          change: '${incomeChange >= 0 ? "+" : ""}$incomeChange%',
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(
          label: 'Savings',
          value: '$savingsPct%',
          icon: savingsChange >= 0 ? Icons.trending_up : Icons.trending_down,
          color: savingsChange >= 0 ? AppColors.success : c.textSecondary,
          change: '${savingsChange >= 0 ? "+" : ""}$savingsChange%',
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, change;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ── Spending Trend Chart ──────────────────────────────────────────────────────

class _SpendingTrendChart extends StatelessWidget {
  final List<double> trendData;
  const _SpendingTrendChart({required this.trendData});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Trend (7 days)',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
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
                    spots: List.generate(
                        trendData.length, (i) => FlSpot(i.toDouble(), trendData[i])),
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
    );
  }
}

// ── Recent Transactions ───────────────────────────────────────────────────────

class _RecentTransactionsList extends StatelessWidget {
  final List transactions;
  const _RecentTransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
            GestureDetector(
              onTap: () => context.go(Routes.transactions),
              child: Row(children: [
                Text('See all', style: TextStyle(color: c.accent, fontSize: 14)),
                Icon(Icons.chevron_right, color: c.accent, size: 18),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TransactionTile(
            tx: tx as Map<String, dynamic>,
            showDate: false,
          ),
        )),
      ],
    );
  }
}

// ── Budget Progress ───────────────────────────────────────────────────────────

class _BudgetProgressSection extends StatelessWidget {
  final List budgets;
  const _BudgetProgressSection({required this.budgets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget Progress', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...budgets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BudgetProgressTile(budget: b as Map<String, dynamic>),
        )),
      ],
    );
  }
}

class _BudgetProgressTile extends StatelessWidget {
  final Map<String, dynamic> budget;
  const _BudgetProgressTile({required this.budget});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final category = budget['category'] ?? '';
    final spent = (budget['spent'] as num).toDouble();
    final total = (budget['total'] as num).toDouble();
    final pct = total > 0 ? spent / total : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      blur: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(category,
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
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
              valueColor: AlwaysStoppedAnimation(
                  pct > 0.9 ? AppColors.destructive : c.accent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Insight Card ───────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  final String insight;
  const _AiInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      animate: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c.accent.withValues(alpha: 0.1),
          AppColors.primaryGreen.withValues(alpha: 0.2),
        ],
      ),
      border: Border.all(color: c.accent.withValues(alpha: 0.2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: c.accent.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.auto_awesome, size: 20, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(insight, style: TextStyle(color: c.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
