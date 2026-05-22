import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceDark.withValues(alpha: 0.5),
                border: Border.all(color: c.borderDefault),
              ),
              child: Icon(Icons.arrow_back, size: 20, color: c.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: c.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
