import 'dart:io';
import 'api_client.dart';

class TransactionApi {
  final ApiClient _client;
  TransactionApi(this._client);

  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) =>
      _client.get('/transactions?page=$page&limit=$limit');

  Future<Map<String, dynamic>> ingestSMSBatch(List<String> messages) =>
      _client.post('/transactions/ingest/sms/batch', {'messages': messages});

  Future<Map<String, dynamic>> ingestManual({
    required double amount,
    required String type,
    required String merchant,
    String? category,
    String? description,
  }) =>
      _client.post('/transactions/ingest/manual', {
        'amount': amount,
        'type': type,
        'merchant': merchant,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
      });

  Future<Map<String, dynamic>> uploadStatement(File file) =>
      _client.multipart('/transactions/ingest/upload', 'file', file);
}
