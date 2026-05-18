import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class _Notif {
  final IconData icon;
  final Color iconColor;
  final String title, body, time;
  bool read;
  _Notif(this.icon, this.iconColor, this.title, this.body, this.time, {this.read = false});
}

class NotificationPane extends StatefulWidget {
  const NotificationPane({super.key});

  @override
  State<NotificationPane> createState() => _NotificationPaneState();
}

class _NotificationPaneState extends State<NotificationPane> {
  final List<_Notif> _notifs = [
    _Notif(Icons.trending_up, AppColors.destructive, 'Budget Alert', 'You\'ve used 95% of your Bills budget.', '2m ago'),
    _Notif(Icons.auto_awesome, AppColors.accent, 'AI Insight', 'You spend 40% more on weekends. Want to set a limit?', '1h ago'),
    _Notif(Icons.sync, AppColors.success, 'Sync Complete', 'All 3 accounts synced successfully.', '3h ago'),
    _Notif(Icons.receipt_long, AppColors.chart2, 'New Transaction', 'Shoprite — ₦12,500 debited from GTBank.', 'Yesterday'),
    _Notif(Icons.savings, AppColors.success, 'Savings Milestone', 'You\'re 45% toward your Emergency Fund goal!', '2d ago', read: true),
  ];

  int get _unread => _notifs.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.surfaceLight, c.surfaceDark],
        ),
        border: Border.all(color: c.borderDefault),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: c.textSecondary.withValues(alpha: 0.3))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
                if (_unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: AppColors.destructive),
                    child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ]),
              if (_unread > 0)
                GestureDetector(
                  onTap: () => setState(() { for (final n in _notifs) { n.read = true; } }),
                  child: const Text('Mark all read', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = _notifs[i];
                return GestureDetector(
                  onTap: () => setState(() => n.read = true),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    gradient: n.read ? null : LinearGradient(colors: [
                      AppColors.accent.withValues(alpha: 0.05),
                      AppColors.surfaceDark.withValues(alpha: 0.6),
                    ]),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: n.iconColor.withValues(alpha: 0.15)),
                        child: Icon(n.icon, size: 20, color: n.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(n.title, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                          Text(n.time, style: TextStyle(color: c.textSecondary, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        Text(n.body, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4)),
                      ])),
                      if (!n.read) ...[
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
