import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ApiService _api;

  final Map<String, Map<String, dynamic>> _cache = {};
  bool loading = false;
  String _period = 'week';

  AnalyticsProvider(this._api);

  String get period => _period;
  Map<String, dynamic>? get data => _cache[_period];

  Future<void> load(String period, {bool force = false}) async {
    if (loading) return;
    if (_cache.containsKey(period) && !force) {
      if (_period != period) {
        _period = period;
        notifyListeners();
      }
      return;
    }
    _period = period;
    loading = true;
    notifyListeners();
    try {
      _cache[period] = await _api.getAnalytics(period);
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  void invalidate() => _cache.clear();
}
