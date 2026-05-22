import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiService _api;

  List<Map<String, dynamic>> budgets = [];
  bool loading = false;
  bool _loaded = false;

  BudgetProvider(this._api);

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (_loaded && !force) return;
    loading = true;
    notifyListeners();
    try {
      final data = await _api.getBudgets();
      budgets = (data['budgets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loaded = true;
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  Future<void> create(String category, double amount, String period) async {
    await _api.createBudget(category, amount, period);
    await load(force: true);
  }

  Future<void> delete(String id) async {
    await _api.deleteBudget(id);
    budgets.removeWhere((b) => b['id'] == id);
    notifyListeners();
  }

  void invalidate() => _loaded = false;
}
