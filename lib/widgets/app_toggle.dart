import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable animated toggle switch used throughout the app.
class AppToggle extends StatelessWidget {
  final bool enabled;
  final VoidCallback onChanged;
  final bool locked;

  const AppToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: locked ? null : onChanged,
      child: Opacity(
        opacity: locked ? 0.6 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: enabled ? c.accent : c.surfaceLight,
            border: enabled ? null : Border.all(color: c.borderDefault),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
