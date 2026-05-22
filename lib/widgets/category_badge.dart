import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CategoryProvider>().forName(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: cat.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        category,
        style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w400),
      ),
    );
  }
}

// Convenience helper used by screens that need icon/color without a widget
class CategoryHelper {
  static String icon(BuildContext context, String name) =>
      context.read<CategoryProvider>().forName(name).icon;

  static Color color(BuildContext context, String name) =>
      context.read<CategoryProvider>().forName(name).color;
}
