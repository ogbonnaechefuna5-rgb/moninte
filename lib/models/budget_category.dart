import 'package:flutter/material.dart';

/// A budget category with spending data and status.
class BudgetCategory {
  final String category;
  final String emoji;
  final int spent;
  final int total;
  final Color color;
  final String status; // 'on-track' | 'warning' | 'over'

  const BudgetCategory({
    required this.category,
    required this.emoji,
    required this.spent,
    required this.total,
    required this.color,
    required this.status,
  });
}
