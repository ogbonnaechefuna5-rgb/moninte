import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _categories = [
    _Cat('Food', 85000, Color(0xFFFF8C42), 35),
    _Cat('Transport', 45000, Color(0xFF4D9FFF), 18),
    _Cat('Bills', 62000, Color(0xFFA855F7), 25),
    _Cat('Airtime', 28000, Color(0xFFFFB830), 12),
    _Cat('Shopping', 25000, Color(0xFFFF69B4), 10),
  ];

  static const _weekly = [
    _Day('Mon', 32000), _Day('Tue', 28000), _Day('Wed', 45000),
    _Day('Thu', 38000), _Day('Fri', 52000), _Day('Sat', 48000), _Day('Sun', 42000),
  ];

  static const _merchants = [
    _Merchant('Shoprite', 45000, 12, '🛒'),
    _Merchant('Chicken Republic', 28500, 8, '🍗'),
    _Merchant('Bolt', 22000, 24, '🚗'),
    _Merchant('MTN', 15000, 6, '📱'),
  ];

  static String _fmt(int v) => fmtNumber(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            // Header
            const ScreenHeader(title: 'Analytics', subtitle: 'Spending insights'),

            const SizedBox(height: 20),

            // Period toggles
            Row(children: [
              _pill('Week', true), const SizedBox(width: 8),
              _pill('Month', false), const SizedBox(width: 8),
              _pill('Year', false),
            ]),

            const SizedBox(height: 20),

            // Total Spend
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Spend', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                Text('₦245,000', style: AppTheme.monoSized(34, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.trending_up, size: 16, color: AppColors.destructive),
                  const SizedBox(width: 4),
                  const Text('+12% vs last week', style: TextStyle(color: AppColors.destructive, fontSize: 14)),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // Category Breakdown Pie
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _categories.map((c) => PieChartSectionData(
                        value: c.value.toDouble(), color: c.color,
                        radius: 30, showTitle: false,
                      )).toList(),
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                  ),
                ),
                const SizedBox(height: 20),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: c.color)),
                    const SizedBox(width: 8),
                    SizedBox(width: 64, child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: c.pct / 100,
                            backgroundColor: AppColors.background.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation(c.color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('₦${_fmt(c.value)}', style: AppTheme.monoSized(12, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    SizedBox(width: 28, child: Text('${c.pct}%', textAlign: TextAlign.right,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                  ]),
                )),
              ]),
            ),

            const SizedBox(height: 20),

            // Weekly Trend
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: Text('Weekly Trend', style: Theme.of(context).textTheme.titleMedium)),
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
                          getTitlesWidget: (v, _) => Text(_weekly[v.toInt()].day,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )),
                      ),
                      barGroups: List.generate(_weekly.length, (i) => BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: _weekly[i].amount.toDouble(),
                          color: AppColors.accent, width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ])),
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Top Merchants
            Text('Top Merchants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._merchants.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceLight),
                      child: Center(child: Text(m.icon, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                          child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.background, fontSize: 12))),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: Text(m.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 2),
                      Text('${m.visits} transactions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                    Flexible(child: Text('₦${_fmt(m.amount)}', style: AppTheme.monoSized(16), overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: active ? AppColors.accent : AppColors.surfaceDark.withValues(alpha: 0.5),
        border: active ? null : Border.all(color: AppColors.borderDefault),
      ),
      child: Text(label, style: TextStyle(color: active ? AppColors.background : AppColors.textSecondary, fontSize: 14)),
    );
  }
}

class _Cat {
  final String name; final int value; final Color color; final int pct;
  const _Cat(this.name, this.value, this.color, this.pct);
}
class _Day {
  final String day; final int amount;
  const _Day(this.day, this.amount);
}
class _Merchant {
  final String name, icon; final int amount, visits;
  const _Merchant(this.name, this.amount, this.visits, this.icon);
}
