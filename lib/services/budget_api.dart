import 'api_client.dart';

class BudgetApi {
  final ApiClient _client;
  BudgetApi(this._client);

  Future<Map<String, dynamic>> getBudgets({int page = 1, int limit = 20}) =>
      _client.get('/budgets?page=$page&limit=$limit');

  Future<Map<String, dynamic>> createBudget(
          String category, double amount, String period) =>
      _client.post('/budgets', {
        'category': category,
        'amount': amount,
        'period': period,
      });

  Future<void> deleteBudget(String id) => _client.delete('/budgets/$id');
}
