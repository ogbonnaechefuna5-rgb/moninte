import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Map<String, dynamic>> _budgets = [];
  bool _loading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getBudgets();
      final list = (data['budgets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _budgets = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

    if (_loading) {
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
              onRefresh: _load,
              color: c.accent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                children: [
                  Text('Budget', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text('Track your spending limits', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),

                  // Month nav
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    GestureDetector(onTap: () => _changeMonth(-1), child: _navBtn(Icons.chevron_left)),
                    const SizedBox(width: 16),
                    Text('${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        style: TextStyle(color: c.textPrimary, fontSize: 16)),
                    const SizedBox(width: 16),
                    GestureDetector(onTap: () => _changeMonth(1), child: _navBtn(Icons.chevron_right)),
                  ]),

                  const SizedBox(height: 20),

                  // Budget list
                  if (_budgets.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48, color: c.textSecondary),
                        const SizedBox(height: 12),
                        Text('No budgets yet', style: TextStyle(color: c.textPrimary, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Tap + to create your first budget', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                      ]),
                    )
                  else
                    ..._budgets.asMap().entries.map((e) {
                      final b = e.value;
                      final category = b['category'] ?? '';
                      final amount = (b['amount'] as num?)?.toDouble() ?? 0;
                      final period = b['period'] ?? 'monthly';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.surfaceLight),
                              child: Center(child: Text(_categoryEmoji(category), style: const TextStyle(fontSize: 24))),
                            ),
                            SizedBox(width: 12),
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
                      );
                    }),
                ],
              ),
            ),
            // FAB
            Positioned(
              bottom: 96, right: 24,
              child: GestureDetector(
                onTap: () {
                  // TODO: show create budget sheet
                },
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

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food': case 'food & dining': return '🍔';
      case 'transport': case 'transportation': return '🚗';
      case 'shopping': return '🛍️';
      case 'bills': case 'utilities': return '⚡';
      case 'airtime': return '📱';
      case 'entertainment': return '🎬';
      default: return '📦';
    }
  }
}
