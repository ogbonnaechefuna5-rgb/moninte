import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String active;
  final ValueChanged<String> onNavigate;

  const BottomNav({
    super.key,
    required this.active,
    required this.onNavigate,
  });

  static const List<_NavItem> _items = [
    _NavItem(id: 'home', label: 'Home', icon: Icons.home_rounded),
    _NavItem(id: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    _NavItem(id: 'ai', label: 'AI', icon: Icons.auto_awesome_rounded),
    _NavItem(id: 'budget', label: 'Budget', icon: Icons.account_balance_wallet_rounded),
    _NavItem(id: 'savings', label: 'Savings', icon: Icons.track_changes_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: c.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) => _NavButton(
              item: item,
              isActive: active == item.id,
              onTap: () => onNavigate(item.id),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isActive ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 32 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Icon(
              item.icon,
              size: 22,
              color: isActive ? AppColors.accent : c.textSecondary,
              shadows: isActive
                  ? [Shadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.accent : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  const _NavItem({required this.id, required this.label, required this.icon});
}
