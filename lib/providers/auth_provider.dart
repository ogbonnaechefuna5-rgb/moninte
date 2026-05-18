import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _loading = true;

  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refresh_token');
    if (_token != null) {
      ApiService.setToken(_token!);
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String identifier, String password) async {
    try {
      final res = await ApiService.login(identifier, password);
      _token = res['token'];
      _refreshToken = res['refresh_token'];
      _user = res['user'] as Map<String, dynamic>?;
      ApiService.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> signup({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      await ApiService.signup(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        email: email,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> refresh() async {
    if (_refreshToken == null) return logout();
    try {
      final res = await ApiService.refreshToken(_refreshToken!);
      _token = res['token'];
      _refreshToken = res['refresh_token'];
      ApiService.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await ApiService.logout(_refreshToken);
      } catch (_) {}
    }
    _token = null;
    _refreshToken = null;
    _user = null;
    ApiService.setToken('');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    notifyListeners();
  }
}
