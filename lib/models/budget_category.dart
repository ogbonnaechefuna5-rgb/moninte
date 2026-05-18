import 'package:flutter/material.dart';

class BudgetCategory {
  final String category;
  final String emoji;
  final int spent;
  final int total;
  final Color color;
  final String status;

  const BudgetCategory({
    required this.category,
    required this.emoji,
    required this.spent,
    required this.total,
    required this.color,
    required this.status,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> j) => BudgetCategory(
        category: j['category'],
        emoji: j['emoji'] ?? '',
        spent: j['spent'],
        total: j['total'],
        color: Color(int.parse((j['color'] as String).replaceFirst('#', '0xFF'))),
        status: j['status'],
      );
}
