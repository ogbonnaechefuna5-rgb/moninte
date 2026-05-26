import 'api_client.dart';

class AnalyticsApi {
  final ApiClient _client;
  AnalyticsApi(this._client);

  Future<Map<String, dynamic>> getAnalytics(String period) =>
      _client.get('/analytics?period=$period');

  Future<Map<String, dynamic>> getCategories() => _client.get('/categories');

  Future<Map<String, dynamic>> getCategoryBreakdown() =>
      _client.get('/categories/breakdown');

  Future<Map<String, dynamic>> getDashboard() => _client.get('/dashboard');

  Future<Map<String, dynamic>> getHealthScore() => _client.get('/health/score');
}
