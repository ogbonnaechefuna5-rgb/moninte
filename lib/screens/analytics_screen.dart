import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../providers/analytics_provider.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AnalyticsProvider>().load(_period),
    );
  }

  void _setPeriod(String p) {
    if (p == _period) return;
    setState(() => _period = p);
    context.read<AnalyticsProvider>().load(p);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              context.read<AnalyticsProvider>().load(_period, force: true),
          color: c.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              const ScreenHeader(title: 'Analytics', subtitle: 'Spending insights'),
              const SizedBox(height: 20),
              // Period pills live outside Consumer — they never need to rebuild
              // when analytics data loads, only when _period changes (setState above).
              Row(children: [
                _PeriodPill(label: 'Week',  active: _period == 'week',  onTap: () => _setPeriod('week')),
                const SizedBox(width: 8),
                _PeriodPill(label: 'Month', active: _period == 'month', onTap: () => _setPeriod('month')),
                const SizedBox(width: 8),
                _PeriodPill(label: 'Year',  active: _period == 'year',  onTap: () => _setPeriod('year')),
              ]),
              const SizedBox(height: 20),
              // Only this Consumer rebuilds when analytics data or loading state changes.
              Consumer<AnalyticsProvider>(
                builder: (context, analytics, _) {
                  if (analytics.loading && analytics.data == null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator(color: c.accent)),
                    );
                  }
                  final data = analytics.data;
                  final totalSpend = (data?['totalSpend'] as num?)?.toDouble() ?? 0;
                  final totalSpendChange = (data?['totalSpendChange'] as num?)?.toInt() ?? 0;
                  final categories = (data?['categories'] as List?) ?? [];
                  final weekly = (data?['weekly'] as List?) ?? [];
                  final merchants = (data?['merchants'] as List?) ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TotalSpendCard(
                        totalSpend: totalSpend,
                        totalSpendChange: totalSpendChange,
                        period: _period,
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _CategoryBreakdownCard(categories: categories),
                      ],
                      if (weekly.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _WeeklyTrendCard(weekly: weekly),
                      ],
                      if (merchants.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _TopMerchantsList(merchants: merchants),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Period Pill ───────────────────────────────────────────────────────────────

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PeriodPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: active ? c.accent : c.surfaceDark.withValues(alpha: 0.5),
          border: active ? null : Border.all(color: c.borderDefault),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? c.background : c.textSecondary, fontSize: 14)),
      ),
    );
  }
}

// ── Total Spend Card ──────────────────────────────────────────────────────────

class _TotalSpendCard extends StatelessWidget {
  final double totalSpend;
  final int totalSpendChange;
  final String period;
  const _TotalSpendCard({
    required this.totalSpend,
    required this.totalSpendChange,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total Spend', style: TextStyle(color: c.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('₦${fmtNumber(totalSpend.round())}',
            style: AppTheme.monoSized(34, weight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(
            totalSpendChange >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: totalSpendChange >= 0 ? AppColors.destructive : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            '${totalSpendChange >= 0 ? "+" : ""}$totalSpendChange% vs last $period',
            style: TextStyle(
              color: totalSpendChange >= 0 ? AppColors.destructive : AppColors.success,
              fontSize: 14,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Category Breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdownCard extends StatelessWidget {
  final List categories;
  const _CategoryBreakdownCard({required this.categories});

  static const _catColors = [
    Color(0xFFFF8C42), Color(0xFF4D9FFF), Color(0xFFA855F7),
    Color(0xFFFFB830), Color(0xFFFF69B4),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: categories.asMap().entries.map((e) {
                final color = _catColors[e.key % _catColors.length];
                return PieChartSectionData(
                  value: (e.value['amount'] as num).toDouble(),
                  color: color, radius: 30, showTitle: false,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 20),
        ...categories.asMap().entries.map((e) {
          final cat = e.value;
          final color = _catColors[e.key % _catColors.length];
          final pct = (cat['percent'] as num?)?.toInt() ?? 0;
          final amount = (cat['amount'] as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(cat['name'] ?? '',
                    style: TextStyle(color: c.textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: c.background.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('₦${fmtNumber(amount.round())}',
                  style: AppTheme.monoSized(12, color: c.textSecondary)),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text('$pct%',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: c.textSecondary, fontSize: 11)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Weekly Trend ──────────────────────────────────────────────────────────────

class _WeeklyTrendCard extends StatelessWidget {
  final List weekly;
  const _WeeklyTrendCard({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Weekly Trend', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= weekly.length) return const SizedBox.shrink();
                    return Text(weekly[idx]['day'] ?? '',
                        style: TextStyle(color: c.textSecondary, fontSize: 12));
                  },
                )),
              ),
              barGroups: List.generate(weekly.length, (i) => BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(
                  toY: (weekly[i]['amount'] as num).toDouble(),
                  color: c.accent, width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                )],
              )),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          ),
        ),
      ]),
    );
  }
}

// ── Top Merchants ─────────────────────────────────────────────────────────────

class _TopMerchantsList extends StatelessWidget {
  final List merchants;
  const _TopMerchantsList({required this.merchants});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Merchants', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...merchants.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12), color: c.surfaceLight),
                  child: Center(child: Text('${i + 1}',
                      style: TextStyle(color: c.accent, fontSize: 16, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['name'] ?? '',
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${m['visits'] ?? 0} transactions',
                      style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ])),
                Flexible(child: Text(
                  '₦${fmtNumber((m['amount'] as num).toInt())}',
                  style: AppTheme.monoSized(16, color: c.textPrimary),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          );
        }),
      ],
    );
  }
}
