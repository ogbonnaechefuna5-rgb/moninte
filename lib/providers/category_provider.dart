import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const AppCategory({required this.id, required this.name, required this.icon, required this.color});

  factory AppCategory.fromJson(Map<String, dynamic> j) {
    Color color = const Color(0xFF8A9E90);
    try {
      final hex = (j['color'] as String? ?? '').replaceFirst('#', '');
      if (hex.length == 6) color = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return AppCategory(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      icon: j['icon'] as String? ?? '📦',
      color: color,
    );
  }
}

class CategoryProvider extends ChangeNotifier {
  final ApiService _api;
  List<AppCategory> _categories = [];
  bool _loaded = false;

  List<AppCategory> get categories => _categories;

  // Fallback list used before API responds or on error
  static final _fallback = [
    AppCategory(id: '', name: 'Food & Dining',  icon: '🍔', color: const Color(0xFFFF8C42)),
    AppCategory(id: '', name: 'Transportation', icon: '🚗', color: const Color(0xFF4D9FFF)),
    AppCategory(id: '', name: 'Shopping',       icon: '🛒', color: const Color(0xFFA855F7)),
    AppCategory(id: '', name: 'Entertainment',  icon: '🎬', color: const Color(0xFFFF69B4)),
    AppCategory(id: '', name: 'Utilities',      icon: '⚡', color: const Color(0xFFFFB830)),
    AppCategory(id: '', name: 'Airtime & Data', icon: '📱', color: const Color(0xFF4DFF91)),
    AppCategory(id: '', name: 'Transfers',      icon: '💸', color: const Color(0xFF8A9E90)),
    AppCategory(id: '', name: 'Income',         icon: '💰', color: const Color(0xFFA8FF3E)),
    AppCategory(id: '', name: 'Health',         icon: '🏥', color: const Color(0xFFFF6B6B)),
    AppCategory(id: '', name: 'Education',      icon: '📚', color: const Color(0xFF6BC5FF)),
    AppCategory(id: '', name: 'Other',          icon: '📦', color: const Color(0xFF8A9E90)),
  ];

  CategoryProvider(this._api) {
    _categories = _fallback;
    load();
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final data = await _api.getCategories();
      final list = (data['categories'] as List?)
          ?.map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      if (list.isNotEmpty) {
        _categories = list;
        _loaded = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  AppCategory forName(String name) {
    return _categories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => _fallback.last,
    );
  }
}
