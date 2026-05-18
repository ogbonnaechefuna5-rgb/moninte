import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A styled text input field used in modals and forms throughout the app.
class AppInputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;

  const AppInputField({
    super.key,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderDefault),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary),
          prefixIcon: Icon(icon, size: 18, color: c.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
