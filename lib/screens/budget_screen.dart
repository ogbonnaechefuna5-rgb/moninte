import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/status_badge.dart';
import '../utils/formatters.dart';
import '../widgets/app_button.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BudgetProvider>().load(),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  static const _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final budget = context.watch<BudgetProvider>();
    final _budgets = budget.budgets;

    if (budget.loading && _budgets.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }



    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => context.read<BudgetProvider>().load(force: true),
              color: c.accent,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                itemCount: 1 + (_budgets.isEmpty ? 1 : _budgets.length),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const ScreenHeader(title: 'Budget', subtitle: 'Track your spending limits'),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        GestureDetector(onTap: () => _changeMonth(-1), child: _navBtn(Icons.chevron_left)),
                        const SizedBox(width: 16),
                        Text('${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                            style: TextStyle(color: c.textPrimary, fontSize: 16)),
                        const SizedBox(width: 16),
                        GestureDetector(onTap: () => _changeMonth(1), child: _navBtn(Icons.chevron_right)),
                      ]),
                      const SizedBox(height: 20),
                    ]);
                  }
                  if (_budgets.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48, color: c.textSecondary),
                        const SizedBox(height: 12),
                        Text('No budgets yet', style: TextStyle(color: c.textPrimary, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Tap + to create your first budget', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                      ]),
                    );
                  }
                  final b = _budgets[i - 1];
                  final category = b['category'] ?? '';
                  final amount = (b['amount'] as num?)?.toDouble() ?? 0;
                  final period = b['period'] ?? 'monthly';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        blur: false,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.surfaceLight),
                            child: Center(child: Text(_categoryEmoji(category), style: const TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(category, style: TextStyle(color: c.textPrimary)),
                              StatusBadge(text: period, color: c.accent),
                            ]),
                            const SizedBox(height: 8),
                            Text('₦${fmtNumber(amount.round())} limit', style: AppTheme.monoSized(14, color: c.textSecondary)),
                          ])),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            // FAB
            Positioned(
              bottom: 96, right: 24,
              child: GestureDetector(
                onTap: _showCreateBudget,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: c.accent,
                    boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.3), blurRadius: 16)],
                  ),
                  child: Icon(Icons.add, size: 28, color: c.background),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceDark.withValues(alpha: 0.5), border: Border.all(color: c.borderDefault)),
      child: Icon(icon, size: 16, color: c.textSecondary),
    );
  }

  String _categoryEmoji(String category) =>
      context.read<CategoryProvider>().forName(category).icon;

  Future<void> _showCreateBudget() async {
    final cats = context.read<CategoryProvider>().categories;
    String? selectedCat;
    double? amount;
    final amountCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final c = AppColors.of(ctx);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: c.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: c.borderDefault),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: c.textSecondary.withValues(alpha: 0.3)))),
                  const SizedBox(height: 20),
                  Text('Create Budget', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text('Category', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: cats.map((cat) {
                      final selected = selectedCat == cat.name;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedCat = cat.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: selected ? cat.color.withValues(alpha: 0.2) : c.surfaceLight.withValues(alpha: 0.4),
                            border: Border.all(color: selected ? cat.color : c.borderDefault),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(cat.name, style: TextStyle(color: selected ? cat.color : c.textPrimary, fontSize: 13)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Monthly Limit (₦)', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: c.surfaceLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.borderDefault)),
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: c.textSecondary),
                        prefixText: '₦ ',
                        prefixStyle: TextStyle(color: c.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (v) => amount = double.tryParse(v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Create Budget',
                    onTap: () async {
                      if (selectedCat == null || amount == null || amount! <= 0) return;
                      Navigator.pop(ctx);
                      try {
                        await context.read<BudgetProvider>().create(selectedCat!, amount!, 'monthly');
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    amountCtrl.dispose();
  }
}
