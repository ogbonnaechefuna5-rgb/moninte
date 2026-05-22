import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Injectable HTTP client for the Moninte API.
///
/// Register a single instance at the root provider and inject it into
/// providers and screens via [context.read<ApiService>()].
class ApiService {
  final String baseUrl;
  String _token = '';
  Future<bool> Function()? onUnauthorized;

  ApiService({
    String? baseUrl,
  }) : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE',
              defaultValue: 'http://localhost:8080/api/v1',
            );

  /// Resolves a relative path like /uploads/avatars/x.jpg to a full URL.
  String resolveUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final host = baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return '$host$path';
  }

  void setToken(String token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<void> _handle401() async {
    final refreshed = await onUnauthorized?.call() ?? false;
    if (!refreshed) throw Exception('unauthorized');
  }

  // Raw post that bypasses the 401 interceptor — used for auth endpoints.
  Future<Map<String, dynamic>> _postRaw(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    var res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) {
      await _handle401();
      res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    }
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    var res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) {
      await _handle401();
      res = await http.post(Uri.parse('$baseUrl$path'),
          headers: _headers, body: jsonEncode(body));
    }
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _delete(String path) async {
    var res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) {
      await _handle401();
      res =
          await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    }
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    var res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) {
      await _handle401();
      res = await http.put(Uri.parse('$baseUrl$path'),
          headers: _headers, body: jsonEncode(body));
    }
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth ──
  Future<Map<String, dynamic>> login(String identifier, String password) =>
      _postRaw('/auth/login', {'identifier': identifier, 'password': password});

  Future<Map<String, dynamic>> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) =>
      _postRaw('/auth/signup', {
        'first_name': firstName,
        if (middleName != null && middleName.isNotEmpty)
          'middle_name': middleName,
        'last_name': lastName,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });

  Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _postRaw('/auth/refresh', {'refresh_token': refreshToken});

  Future<Map<String, dynamic>> oidcLogin(
          {required String provider, required String idToken}) =>
      _postRaw('/auth/oidc', {'provider': provider, 'id_token': idToken});

  Future<void> logout(String? refreshToken) async {
    try {
      await _postRaw('/auth/logout', {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } catch (_) {}
  }

  // ── Categories ──
  Future<Map<String, dynamic>> getCategories() => _get('/categories');

  Future<Map<String, dynamic>> getCategoryBreakdown() =>
      _get('/categories/breakdown');

  Future<Map<String, dynamic>> getDashboard() => _get('/dashboard');

  // ── Analytics ──
  Future<Map<String, dynamic>> getAnalytics(String period) =>
      _get('/analytics?period=$period');

  // ── Budgets ──
  Future<Map<String, dynamic>> getBudgets({int page = 1, int limit = 20}) =>
      _get('/budgets?page=$page&limit=$limit');

  Future<Map<String, dynamic>> createBudget(
          String category, double amount, String period) =>
      _post('/budgets', {
        'category': category,
        'amount': amount,
        'period': period,
      });

  Future<void> deleteBudget(String id) => _delete('/budgets/$id');

  // ── Savings ──
  Future<Map<String, dynamic>> getSavings() => _get('/savings');

  Future<Map<String, dynamic>> createGoal(
          String name, double targetAmount, String? deadline) =>
      _post('/savings', {
        'name': name,
        'target_amount': targetAmount,
        if (deadline != null) 'deadline': deadline,
      });

  Future<void> updateSavingsProgress(String id, double amount) async {
    await _put('/savings/$id/progress', {'amount': amount});
  }

  Future<void> deleteGoal(String id) => _delete('/savings/$id');

  // ── Transactions ──
  Future<Map<String, dynamic>> getTransactions(
          {int page = 1, int limit = 20}) =>
      _get('/transactions?page=$page&limit=$limit');

  Future<Map<String, dynamic>> ingestSMSBatch(List<String> messages) =>
      _post('/transactions/ingest/sms/batch', {'messages': messages});

  Future<Map<String, dynamic>> ingestManual({
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

  Future<Map<String, dynamic>> uploadStatement(File file) async {
    final uri = Uri.parse('$baseUrl/transactions/ingest/upload');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401) throw Exception('unauthorized');
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Upload failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Profile ──
  Future<Map<String, dynamic>> getProfile() => _get('/user/profile');

  Future<String> uploadAvatar(File file) async {
    final uri = Uri.parse('$baseUrl/user/avatar');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer $_token'})
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401) {
      final refreshed = await onUnauthorized?.call() ?? false;
      if (!refreshed) throw Exception('unauthorized');
      // retry
      final req2 = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer $_token'})
        ..files.add(await http.MultipartFile.fromPath('avatar', file.path));
      final streamed2 = await req2.send();
      final res2 = await http.Response.fromStream(streamed2);
      final b = jsonDecode(res2.body);
      if (res2.statusCode != 200) throw Exception(b['error'] ?? 'Upload failed');
      return b['avatar_url'] as String;
    }
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Upload failed');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['avatar_url']
        as String;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _put('/user/profile', data);
  }

  Future<void> changePassword(
      String oldPassword, String newPassword) async {
    await _post('/user/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount() => _delete('/user/account');

  // ── Preferences ──
  Future<Map<String, dynamic>> getPreferences() => _get('/user/preferences');

  Future<void> savePreferences(Map<String, dynamic> prefs) =>
      _put('/user/preferences', prefs);

  // ── Linked Accounts ──
  Future<Map<String, dynamic>> getLinkedAccounts(
          {int page = 1, int limit = 20}) =>
      _get('/user/linked-accounts?page=$page&limit=$limit');

  Future<void> syncAccount(String id) async {
    await _post('/user/linked-accounts/$id/sync', {});
  }

  Future<void> removeAccount(String id) => _delete('/user/linked-accounts/$id');

  // ── Sessions ──
  Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 20}) =>
      _get('/user/sessions?page=$page&limit=$limit');

  Future<void> revokeSession(String id) => _delete('/user/sessions/$id');

  Future<void> revokeAllSessions() => _delete('/user/sessions');

  // ── Health Score ──
  Future<Map<String, dynamic>> getHealthScore() => _get('/health/score');
}
