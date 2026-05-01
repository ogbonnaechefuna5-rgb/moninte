import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String category;

  const CategoryBadge({super.key, required this.category});

  static const Map<String, _BadgeColors> _colorMap = {
    'Food': _BadgeColors(Color(0x33FF8C42), Color(0xFFFF8C42), Color(0x4DFF8C42)),
    'Transport': _BadgeColors(Color(0x334D9FFF), Color(0xFF4D9FFF), Color(0x4D4D9FFF)),
    'Bills': _BadgeColors(Color(0x33A855F7), Color(0xFFA855F7), Color(0x4DA855F7)),
    'Airtime': _BadgeColors(Color(0x33FFB830), Color(0xFFFFB830), Color(0x4DFFB830)),
    'Shopping': _BadgeColors(Color(0x33FF69B4), Color(0xFFFF69B4), Color(0x4DFF69B4)),
    'Entertainment': _BadgeColors(Color(0x334DFF91), Color(0xFF4DFF91), Color(0x4D4DFF91)),
  };

  static const _BadgeColors _defaultColors =
      _BadgeColors(Color(0x338A9E90), Color(0xFF8A9E90), Color(0x4D8A9E90));

  @override
  Widget build(BuildContext context) {
    final colors = _colorMap[category] ?? _defaultColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _BadgeColors {
  final Color background;
  final Color text;
  final Color border;

  const _BadgeColors(this.background, this.text, this.border);
}
