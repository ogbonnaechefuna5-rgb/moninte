import 'api_client.dart';

class SavingsApi {
  final ApiClient _client;
  SavingsApi(this._client);

  Future<Map<String, dynamic>> getSavings() => _client.get('/savings');

  Future<Map<String, dynamic>> createGoal(
          String name, double targetAmount, String? deadline) =>
      _client.post('/savings', {
        'name': name,
        'target_amount': targetAmount,
        if (deadline != null) 'deadline': deadline,
      });

  Future<void> updateSavingsProgress(String id, double amount) =>
      _client.put('/savings/$id/progress', {'amount': amount});

  Future<void> deleteGoal(String id) => _client.delete('/savings/$id');
}
