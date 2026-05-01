import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-width primary button with the app accent colour.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const PrimaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Full-width outlined button. Defaults to the standard border colour;
/// pass [color] to use a destructive or warning variant.
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const OutlineButton({super.key, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.textPrimary;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedColor,
          side: BorderSide(color: (color ?? AppColors.borderDefault).withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: Text(label),
      ),
    );
  }
}
