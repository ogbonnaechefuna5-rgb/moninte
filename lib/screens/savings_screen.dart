import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../providers/savings_provider.dart';
import '../utils/formatters.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SavingsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final savings = context.watch<SavingsProvider>();
    final _data = savings.data;

    if (savings.loading && _data == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.accent)),
      );
    }

    final totalSaved = (_data?['totalSaved'] as num?)?.toDouble() ?? 0;
    final monthlyGain = (_data?['monthlyGain'] as num?)?.toDouble() ?? 0;
    final goals = (_data?['goals'] as List?) ?? [];
    final active = goals.where((g) => g['status'] != 'completed').toList();
    final completed = goals.where((g) => g['status'] == 'completed').toList();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<SavingsProvider>().load(force: true),
          color: c.accent,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            itemCount: 1 + 1 + (active.isNotEmpty ? 1 + active.length : 0) + (completed.isNotEmpty ? 1 + completed.length : 0) + 1,
            itemBuilder: (_, i) {
              // header
              if (i == 0) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const ScreenHeader(title: 'Savings Goals', subtitle: 'Track your financial targets'),
                const SizedBox(height: 20),
              ]);
              // summary card
              if (i == 1) return GlassCard(
                padding: const EdgeInsets.all(24),
                blur: true,
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Saved', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('₦${fmtNumber(totalSaved.round())}', style: AppTheme.monoSized(28, weight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 8),
                    if (monthlyGain > 0)
                      Row(children: [
                        const Icon(Icons.trending_up, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Flexible(child: Text('+₦${fmtNumber(monthlyGain.round())} this month', style: const TextStyle(color: AppColors.success, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      ]),
                  ])),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [c.accent, AppColors.primaryGreen]),
                    ),
                    child: Icon(Icons.track_changes, size: 32, color: c.background),
                  ),
                ]),
              );

              int cursor = 2;

              if (active.isNotEmpty) {
                if (i == cursor) return Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Text('Active Goals', style: Theme.of(context).textTheme.titleMedium));
                cursor++;
                if (i < cursor + active.length) {
                  final g = active[i - cursor];
                  final current = (g['current_amount'] as num?)?.toDouble() ?? 0;
                  final target = (g['target_amount'] as num?)?.toDouble() ?? 1;
                  final pct = current / target;
                  final remaining = target - current;
                  final name = g['name'] ?? '';
                  final deadline = g['deadline'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        blur: false,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(name, style: TextStyle(color: c.textPrimary), overflow: TextOverflow.ellipsis)),
                            Text('${(pct * 100).round()}%', style: TextStyle(color: c.accent, fontSize: 14)),
                          ]),
                          if (deadline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.calendar_today, size: 12, color: c.textSecondary),
                              const SizedBox(width: 4),
                              Text(deadline, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                            ]),
                          ],
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0), minHeight: 10,
                              backgroundColor: c.background.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation(c.accent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Flexible(child: Text('₦${fmtNumber(current.round())} / ₦${fmtNumber(target.round())}', style: AppTheme.monoSized(13, color: c.textSecondary), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Text('₦${fmtNumber(remaining.round())} to go', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                }
                cursor += active.length;
              }

              if (completed.isNotEmpty) {
                if (i == cursor) return Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Text('Completed', style: Theme.of(context).textTheme.titleMedium));
                cursor++;
                if (i < cursor + completed.length) {
                  final g = completed[i - cursor];
                  final target = (g['target_amount'] as num?)?.toDouble() ?? 0;
                  final name = g['name'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RepaintBoundary(
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        blur: false,
                        gradient: LinearGradient(colors: [AppColors.success.withValues(alpha: 0.1), c.surfaceDark.withValues(alpha: 0.6)]),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                        child: Row(children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.success.withValues(alpha: 0.2)),
                            child: const Center(child: Icon(Icons.check, color: AppColors.success)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: TextStyle(color: c.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('Goal achieved! 🎉', style: TextStyle(color: AppColors.success, fontSize: 14)),
                          ])),
                          Text('₦${fmtNumber(target.round())}', style: AppTheme.monoSized(16, color: c.textPrimary)),
                        ]),
                      ),
                    ),
                  );
                }
              }

              // Create new goal button (last item)
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  border: Border.all(color: c.accent.withValues(alpha: 0.1), width: 1.5),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.2)),
                      child: Icon(Icons.add, size: 24, color: c.accent),
                    ),
                    const SizedBox(height: 12),
                    Text('Create New Goal', style: TextStyle(color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Start saving for something special', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
