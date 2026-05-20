import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const _base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  static String _token = '';

  static void setToken(String token) => _token = token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'), headers: _headers);
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> login(String identifier, String password) =>
      _post('/auth/login', {'identifier': identifier, 'password': password});

  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) =>
      _post('/auth/signup', {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _post('/auth/refresh', {'refresh_token': refreshToken});

  static Future<void> logout(String? refreshToken) async {
    await _post('/auth/logout', {
      if (refreshToken != null) 'refresh_token': refreshToken,
    });
  }

  // ── Dashboard ──
  static Future<Map<String, dynamic>> getDashboard() => _get('/dashboard');

  // ── Analytics ──
  static Future<Map<String, dynamic>> getAnalytics(String period) =>
      _get('/analytics?period=$period');

  // ── Budgets ──
  static Future<Map<String, dynamic>> getBudgets({int page = 1, int limit = 20}) =>
      _get('/budgets?page=$page&limit=$limit');

  static Future<Map<String, dynamic>> createBudget(String category, double amount, String period) =>
      _post('/budgets', {'category': category, 'amount': amount, 'period': period});

  static Future<void> deleteBudget(String id) => _delete('/budgets/$id');

  // ── Savings ──
  static Future<Map<String, dynamic>> getSavings() => _get('/savings');

  static Future<Map<String, dynamic>> createGoal(String name, double targetAmount, String? deadline) =>
      _post('/savings', {
        'name': name,
        'target_amount': targetAmount,
        if (deadline != null) 'deadline': deadline,
      });

  static Future<void> updateSavingsProgress(String id, double amount) async {
    await _put('/savings/$id/progress', {'amount': amount});
  }

  static Future<void> deleteGoal(String id) => _delete('/savings/$id');

  // ── Transactions ──
  static Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) =>
      _get('/transactions?page=$page&limit=$limit');

  static Future<Map<String, dynamic>> ingestSMSBatch(List<String> messages) =>
      _post('/transactions/ingest/sms/batch', {'messages': messages});

  static Future<Map<String, dynamic>> ingestManual({
    required double amount,
    required String type,
    required String merchant,
    String? category,
    String? description,
  }) =>
      _post('/transactions/ingest/manual', {
        'amount': amount,
        'type': type,
        'merchant': merchant,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
      });

  static Future<Map<String, dynamic>> uploadStatement(File file) async {
    final uri = Uri.parse('$_base/transactions/ingest/upload');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Upload failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Profile ──
  static Future<Map<String, dynamic>> getProfile() => _get('/user/profile');

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await _put('/user/profile', data);
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    await _post('/user/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  static Future<void> deleteAccount() => _delete('/user/account');

  // ── Preferences ──
  static Future<Map<String, dynamic>> getPreferences() => _get('/user/preferences');

  static Future<void> savePreferences(Map<String, dynamic> prefs) =>
      _put('/user/preferences', prefs);

  // ── Linked Accounts ──
  static Future<Map<String, dynamic>> getLinkedAccounts({int page = 1, int limit = 20}) =>
      _get('/user/linked-accounts?page=$page&limit=$limit');

  static Future<void> syncAccount(String id) async {
    await _post('/user/linked-accounts/$id/sync', {});
  }

  static Future<void> removeAccount(String id) => _delete('/user/linked-accounts/$id');

  // ── Sessions ──
  static Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 20}) =>
      _get('/user/sessions?page=$page&limit=$limit');

  static Future<void> revokeSession(String id) => _delete('/user/sessions/$id');

  static Future<void> revokeAllSessions() => _delete('/user/sessions');

  // ── Health Score ──
  static Future<Map<String, dynamic>> getHealthScore() => _get('/health/score');
}
