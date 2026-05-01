import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/status_badge.dart';
import '../models/budget_category.dart';
import '../utils/formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {

  static const _budgets = [
    BudgetCategory(category: 'Food', emoji: '🍔', spent: 45000, total: 60000, color: Color(0xFFFF8C42), status: 'on-track'),
    BudgetCategory(category: 'Transport', emoji: '🚗', spent: 18000, total: 25000, color: Color(0xFF4D9FFF), status: 'on-track'),
    BudgetCategory(category: 'Bills', emoji: '⚡', spent: 38000, total: 40000, color: Color(0xFFA855F7), status: 'warning'),
    BudgetCategory(category: 'Airtime', emoji: '📱', spent: 12500, total: 10000, color: Color(0xFFFFB830), status: 'over'),
    BudgetCategory(category: 'Shopping', emoji: '🛍️', spent: 22000, total: 35000, color: Color(0xFFFF69B4), status: 'on-track'),
  ];

  DateTime _selectedMonth = DateTime(2026, 4);

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    const startYear = 1990;
    const endYear = 2050;
    int tempMonth = _selectedMonth.month;
    int tempYear = _selectedMonth.year;

    final yearController = FixedExtentScrollController(
      initialItem: tempYear - startYear,
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: AppColors.surfaceLight,
            border: Border.all(color: AppColors.borderDefault),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.2))),
              const SizedBox(height: 20),
              // Year scroll wheel
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.accent.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: yearController,
                      itemExtent: 40,
                      perspective: 0.003,
                      diameterRatio: 2.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setLocal(() => tempYear = startYear + i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: endYear - startYear + 1,
                        builder: (_, i) {
                          final year = startYear + i;
                          final selected = year == tempYear;
                          return Center(
                            child: Text(
                              '$year',
                              style: TextStyle(
                                color: selected ? AppColors.accent : AppColors.textSecondary,
                                fontSize: selected ? 20 : 16,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Month grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(12, (i) {
                  final selected = tempMonth == i + 1;
                  return GestureDetector(
                    onTap: () => setLocal(() => tempMonth = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected ? AppColors.accent : AppColors.surfaceDark,
                        border: Border.all(color: selected ? AppColors.accent : AppColors.borderDefault),
                      ),
                      child: Center(
                        child: Text(_months[i].substring(0, 3),
                            style: TextStyle(color: selected ? AppColors.background : AppColors.textSecondary, fontSize: 13)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedMonth = DateTime(tempYear, tempMonth));
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent, foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  @override
  Widget build(BuildContext context) {
    final totalBudget = _budgets.fold<int>(0, (s, b) => s + b.total);
    final totalSpent = _budgets.fold<int>(0, (s, b) => s + b.spent);
    final healthPct = totalSpent / totalBudget;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              children: [
                // Header
                const ScreenHeader(title: 'Budget', subtitle: 'Track your spending limits'),

                const SizedBox(height: 20),

                // Month nav
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  GestureDetector(onTap: () => _changeMonth(-1), child: _navBtn(Icons.chevron_left)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _pickMonth(context),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(onTap: () => _changeMonth(1), child: _navBtn(Icons.chevron_right)),
                ]),

                const SizedBox(height: 20),

                // Gauge
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const Text('Overall Budget Health', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160, height: 160,
                      child: CustomPaint(
                        painter: _GaugePainter(healthPct),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${(healthPct * 100).round()}%', style: AppTheme.monoSized(24)),
                            const Text('used', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('₦${fmtNumber(totalSpent)} / ₦${fmtNumber(totalBudget)}', style: AppTheme.monoSized(20)),
                    const SizedBox(height: 4),
                    Text('₦${fmtNumber(totalBudget - totalSpent)} remaining', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                ),

                const SizedBox(height: 24),

                Text('Category Budgets', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ..._budgets.map((b) {
                  final pct = b.spent / b.total;
                  final isOver = b.status == 'over';
                  final isWarning = b.status == 'warning';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      border: isOver ? Border.all(color: AppColors.destructive.withValues(alpha: 0.3)) : null,
                      gradient: isOver ? LinearGradient(colors: [AppColors.destructive.withValues(alpha: 0.1), AppColors.surfaceDark.withValues(alpha: 0.6)]) : null,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surfaceLight),
                          child: Center(child: Text(b.emoji, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(b.category, style: const TextStyle(color: AppColors.textPrimary)),
                            if (isOver) const Icon(Icons.error_outline, size: 16, color: AppColors.destructive),
                            if (b.status == 'on-track') const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          ]),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: min(pct, 1.0),
                              backgroundColor: AppColors.background.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation(b.color),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Flexible(child: Text('₦${fmtNumber(b.spent)} / ₦${fmtNumber(b.total)}', style: AppTheme.monoSized(13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            if (isOver) StatusBadge(text: 'Over by ₦${fmtNumber(b.spent - b.total)}', color: AppColors.destructive),
                            if (isWarning) const StatusBadge(text: 'Warning', color: AppColors.warning),
                            if (b.status == 'on-track') const StatusBadge(text: 'On Track', color: AppColors.success),
                          ]),
                        ])),
                      ]),
                    ),
                  );
                }),
              ],
            ),
            // FAB
            Positioned(
              bottom: 96, right: 24,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.accent,
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: const Icon(Icons.add, size: 28, color: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceDark.withValues(alpha: 0.5), border: Border.all(color: AppColors.borderDefault)),
    child: Icon(icon, size: 16, color: AppColors.textSecondary),
  );
}

class _GaugePainter extends CustomPainter {  final double pct;
  _GaugePainter(this.pct);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bgPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.1)..strokeWidth = 12..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final color = pct > 0.9 ? AppColors.destructive : pct > 0.75 ? AppColors.warning : AppColors.accent;
    final fgPaint = Paint()..color = color..strokeWidth = 12..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * pct, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.pct != pct;
}
