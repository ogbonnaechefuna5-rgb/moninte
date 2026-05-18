import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'week';
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAnalytics(_period);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setPeriod(String p) {
    if (p == _period) return;
    _period = p;
    _load();
  }

  static const _catColors = [Color(0xFFFF8C42), Color(0xFF4D9FFF), Color(0xFFA855F7), Color(0xFFFFB830), Color(0xFFFF69B4)];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final totalSpend = (_data?['totalSpend'] as num?)?.toDouble() ?? 0;
    final totalSpendChange = (_data?['totalSpendChange'] as num?)?.toInt() ?? 0;
    final categories = (_data?['categories'] as List?) ?? [];
    final weekly = (_data?['weekly'] as List?) ?? [];
    final merchants = (_data?['merchants'] as List?) ?? [];

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              const ScreenHeader(title: 'Analytics', subtitle: 'Spending insights'),
              const SizedBox(height: 20),

              // Period pills
              Row(children: [
                _pill(context, 'Week', _period == 'week', () => _setPeriod('week')),
                const SizedBox(width: 8),
                _pill(context, 'Month', _period == 'month', () => _setPeriod('month')),
                const SizedBox(width: 8),
                _pill(context, 'Year', _period == 'year', () => _setPeriod('year')),
              ]),

              const SizedBox(height: 20),

              if (_loading)
                const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
              else ...[
                // Total Spend
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Spend', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('₦${fmtNumber(totalSpend.round())}', style: AppTheme.monoSized(34, weight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(totalSpendChange >= 0 ? Icons.trending_up : Icons.trending_down, size: 16, color: totalSpendChange >= 0 ? AppColors.destructive : AppColors.success),
                      const SizedBox(width: 4),
                      Text('${totalSpendChange >= 0 ? "+" : ""}$totalSpendChange% vs last $_period', style: TextStyle(color: totalSpendChange >= 0 ? AppColors.destructive : AppColors.success, fontSize: 14)),
                    ]),
                  ]),
                ),

                // Category Breakdown
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                            sections: categories.asMap().entries.map((e) {
                              final cat = e.value;
                              final color = _catColors[e.key % _catColors.length];
                              return PieChartSectionData(
                                value: (cat['amount'] as num).toDouble(),
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
                            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                            const SizedBox(width: 8),
                            SizedBox(width: 64, child: Text(cat['name'] ?? '', style: TextStyle(color: c.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
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
                            Text('₦${fmtNumber(amount.round())}', style: AppTheme.monoSized(12, color: c.textSecondary)),
                            const SizedBox(width: 6),
                            SizedBox(width: 28, child: Text('$pct%', textAlign: TextAlign.right, style: TextStyle(color: c.textSecondary, fontSize: 11))),
                          ]),
                        );
                      }),
                    ]),
                  ),
                ],

                // Weekly Trend
                if (weekly.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= weekly.length) return const SizedBox.shrink();
                                  return Text(weekly[idx]['day'] ?? '', style: TextStyle(color: c.textSecondary, fontSize: 12));
                                },
                              )),
                            ),
                            barGroups: List.generate(weekly.length, (i) => BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: (weekly[i]['amount'] as num).toDouble(),
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
                ],

                // Top Merchants
                if (merchants.isNotEmpty) ...[
                  const SizedBox(height: 24),
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
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.surfaceLight),
                            child: Center(child: Text('${i + 1}', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m['name'] ?? '', style: TextStyle(color: c.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${m['visits'] ?? 0} transactions', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                          ])),
                          Flexible(child: Text('₦${fmtNumber((m['amount'] as num).toInt())}', style: AppTheme.monoSized(16, color: c.textPrimary), overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, bool active, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: active ? AppColors.accent : c.surfaceDark.withValues(alpha: 0.5),
          border: active ? null : Border.all(color: c.borderDefault),
        ),
        child: Text(label, style: TextStyle(color: active ? c.background : c.textSecondary, fontSize: 14)),
      ),
    );
  }
}
