import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_header.dart';
import '../models/savings_goal.dart';
import '../utils/formatters.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  static const _goals = [
    SavingsGoal(id: 1, name: 'Emergency Fund', emoji: '🛡️', current: 450000, target: 1000000, deadline: 'Dec 2026', status: 'active'),
    SavingsGoal(id: 2, name: 'New Laptop', emoji: '💻', current: 280000, target: 800000, deadline: 'Aug 2026', status: 'active'),
    SavingsGoal(id: 3, name: 'Vacation to Dubai', emoji: '✈️', current: 150000, target: 500000, deadline: 'Dec 2026', status: 'active'),
    SavingsGoal(id: 4, name: 'iPhone 16 Pro', emoji: '📱', current: 750000, target: 750000, deadline: 'Completed', status: 'completed'),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _goals.where((g) => g.status == 'active').toList();
    final completed = _goals.where((g) => g.status == 'completed').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            // Header
            const ScreenHeader(title: 'Savings Goals', subtitle: 'Track your financial targets'),

            const SizedBox(height: 20),

            // Total Saved
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Saved', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₦1,630,000', style: AppTheme.monoSized(28, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: const [
                    Icon(Icons.trending_up, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Flexible(child: Text('+₦85,000 this month', style: TextStyle(color: AppColors.success, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  ]),
                ])),
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.primaryGreen]),
                  ),
                  child: const Icon(Icons.track_changes, size: 32, color: AppColors.background),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            Text('Active Goals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...active.map((g) {
              final pct = g.current / g.target;
              final remaining = g.target - g.current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.surfaceLight),
                      child: Center(child: Text(g.emoji, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(g.name, style: const TextStyle(color: AppColors.textPrimary)),
                        Text('${(pct * 100).round()}%', style: const TextStyle(color: AppColors.accent, fontSize: 14)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(g.deadline, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 10,
                          backgroundColor: AppColors.background.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(child: Text('₦${fmtNumber(g.current)} / ₦${fmtNumber(g.target)}', style: AppTheme.monoSized(13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text('₦${fmtNumber(remaining)} to go', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ]),
                    ])),
                  ]),
                ),
              );
            }),

            if (completed.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Completed', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...completed.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  gradient: LinearGradient(colors: [AppColors.success.withValues(alpha: 0.1), AppColors.surfaceDark.withValues(alpha: 0.6)]),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  child: Row(children: [
                    Stack(children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.success.withValues(alpha: 0.2)),
                        child: Center(child: Text(g.emoji, style: const TextStyle(fontSize: 28))),
                      ),
                      Positioned(top: -2, right: -2, child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                        child: const Icon(Icons.check, size: 14, color: AppColors.background),
                      )),
                    ]),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name, style: const TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Goal achieved! 🎉', style: TextStyle(color: AppColors.success, fontSize: 14)),
                    ])),
                    Text('₦${fmtNumber(g.target)}', style: AppTheme.monoSized(16)),
                  ]),
                ),
              )),
            ],

            const SizedBox(height: 16),

            // Create new goal
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 28),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.1), width: 1.5),
              child: Column(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.2)),
                  child: const Icon(Icons.add, size: 24, color: AppColors.accent),
                ),
                const SizedBox(height: 12),
                const Text('Create New Goal', style: TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Start saving for something special', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
