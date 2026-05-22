import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _sessionExpired = false;

  AuthProvider(this._api);

  // isLoggedIn is true only when we have a confirmed access token.
  // During init() the loading flag is true — the redirect holds on splash
  // until init completes, so we never need to count a bare refresh token
  // as "logged in" for routing purposes.
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  bool get sessionExpired => _sessionExpired;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    _api.onUnauthorized = _handleUnauthorized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _loading = false;
    notifyListeners();
  }

  /// Called by ApiService on every 401. Tries to refresh; returns true if
  /// a new token was obtained (so the caller can retry), false otherwise.
  /// Sets [sessionExpired] when the user was previously logged in so the UI
  /// can show a "session expired" message instead of silently redirecting.
  Future<bool> _handleUnauthorized() async {
    if (_refreshToken == null) {
      await logout();
      return false;
    }
    final wasLoggedIn = _token != null;
    try {
      final res = await _api.refreshToken(_refreshToken!);
      _token = res['token'];
      _refreshToken = res['refresh_token'];
      _api.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      notifyListeners();
      return true;
    } catch (_) {
      if (wasLoggedIn) _sessionExpired = true;
      await logout();
      return false;
    }
  }

  Future<String?> login(String identifier, String password) async {
    try {
      final res = await _api.login(identifier, password);
      _token = res['token'] as String?;
      _refreshToken = res['refresh_token'] as String?;
      _user = res['user'] as Map<String, dynamic>?;
      _api.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      await _cacheUser();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      await _api.signup(
        firstName: firstName,
        middleName: middleName,
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

  Future<bool> refreshFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRefresh = prefs.getString('refresh_token');
    if (storedRefresh == null) return false;
    try {
      final res = await _api.refreshToken(storedRefresh);
      _token = res['token'];
      _refreshToken = res['refresh_token'];
      _api.setToken(_token!);
      await prefs.setString('token', _token!);
      await prefs.setString('refresh_token', _refreshToken!);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => _handleUnauthorized();

  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Sign-in cancelled';
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return 'Could not get Google ID token';
      final res = await _api.oidcLogin(provider: 'google', idToken: idToken);
      return _applyOIDCResult(res);
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) return 'Could not get Apple ID token';
      final res = await _api.oidcLogin(provider: 'apple', idToken: idToken);
      return _applyOIDCResult(res);
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> _applyOIDCResult(Map<String, dynamic> res) async {
    _token = res['token'] as String?;
    _refreshToken = res['refresh_token'] as String?;
    _user = res['user'] as Map<String, dynamic>?;
    if (_token == null) return 'Invalid server response';
    _api.setToken(_token!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
    await _cacheUser();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _api.logout(_refreshToken);
      } catch (_) {}
    }
    _token = null;
    _refreshToken = null;
    _user = null;
    _sessionExpired = false;
    _api.setToken('');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    notifyListeners();
  }

  Future<void> _cacheUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_first_name', _user!['first_name'] as String? ?? '');
    await prefs.setString(
        'user_last_name', _user!['last_name'] as String? ?? '');
  }
}
