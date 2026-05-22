import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  Map<String, dynamic>? data;
  bool loading = false;
  bool _loaded = false;

  DashboardProvider(this._api);

  /// Fetches only if not already loaded. Pass [force]=true to always refresh.
  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (_loaded && !force) return;
    loading = true;
    notifyListeners();
    try {
      data = await _api.getDashboard();
      _loaded = true;
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  void invalidate() => _loaded = false;
}
