import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hover;
  final bool animate;
  final bool blur;
  final BoxBorder? border;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final String? className;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.hover = false,
    this.animate = false,
    this.blur = false,
    this.border,
    this.gradient,
    this.onTap,
    this.className,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Only initialised when widget.animate == true

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    if (widget.animate) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final decoration = BoxDecoration(
      gradient: widget.gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.surfaceLight.withValues(alpha: 0.4),
              c.surfaceDark.withValues(alpha: 0.6),
            ],
          ),
      borderRadius: BorderRadius.circular(16),
      border: widget.border ?? Border.all(color: c.borderDefault),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
    Widget card = widget.blur
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(padding: widget.padding, decoration: decoration, child: widget.child),
            ),
          )
        : Container(padding: widget.padding, decoration: decoration, child: widget.child);

    if (widget.onTap != null) {
      card = GestureDetector(onTap: widget.onTap, child: card);
    }

    if (!widget.animate) return card;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: card),
    );
  }
}
