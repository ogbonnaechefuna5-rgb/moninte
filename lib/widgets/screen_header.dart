import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard screen header with a circular back button, title, and optional subtitle.
///
/// Pass [onBack] to make the back button tappable. If null, the button is
/// rendered but does nothing (useful for top-level screens).
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Optional trailing widget placed at the end of the header row.
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
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark.withValues(alpha: 0.5),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
