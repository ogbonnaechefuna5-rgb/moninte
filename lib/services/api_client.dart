import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// HTTP primitives: headers, token management, 401 retry, multipart.
/// All domain APIs accept this as a dependency.
class ApiClient {
  final String baseUrl;
  String _token = '';
  Future<bool> Function()? onUnauthorized;

  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE',
              defaultValue: 'http://172.20.10.2:8080/api/v1',
            );

  void setToken(String token) => _token = token;

  String resolveUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final host = baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return '$host$path';
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<void> _handle401() async {
    final refreshed = await onUnauthorized?.call() ?? false;
    if (!refreshed) throw Exception('unauthorized');
  }

  Future<Map<String, dynamic>> postRaw(
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

  Future<Map<String, dynamic>> get(String path) async {
    var res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) {
      await _handle401();
      res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    }
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
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

  Future<Map<String, dynamic>> put(
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

  Future<void> delete(String path) async {
    var res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) {
      await _handle401();
      res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    }
    if (res.statusCode != 200) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Request failed');
    }
  }

  /// Sends a multipart POST. Retries once on 401.
  Future<Map<String, dynamic>> multipart(
      String path, String field, File file) async {
    Future<http.Response> send() async {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll({'Authorization': 'Bearer $_token'})
        ..files.add(await http.MultipartFile.fromPath(field, file.path));
      return http.Response.fromStream(await req.send());
    }

    var res = await send();
    if (res.statusCode == 401) {
      await _handle401();
      res = await send();
    }
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 202) {
      final b = jsonDecode(res.body);
      throw Exception(b['error'] ?? 'Upload failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
