import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SavingsProvider extends ChangeNotifier {
  final ApiService _api;

  Map<String, dynamic>? data;
  bool loading = false;
  bool _loaded = false;

  SavingsProvider(this._api);

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (_loaded && !force) return;
    loading = true;
    notifyListeners();
    try {
      data = await _api.getSavings();
      _loaded = true;
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  void invalidate() => _loaded = false;
}
