import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<Map<String, dynamic>> login(String identifier, String password) =>
      _client.postRaw(
          '/auth/login', {'identifier': identifier, 'password': password});

  Future<Map<String, dynamic>> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) =>
      _client.postRaw('/auth/signup', {
        'first_name': firstName,
        if (middleName != null && middleName.isNotEmpty)
          'middle_name': middleName,
        'last_name': lastName,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });

  Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _client.postRaw('/auth/refresh', {'refresh_token': refreshToken});

  Future<Map<String, dynamic>> oidcLogin(
          {required String provider, required String idToken}) =>
      _client.postRaw('/auth/oidc', {'provider': provider, 'id_token': idToken});

  Future<void> logout(String? refreshToken) async {
    try {
      await _client.postRaw('/auth/logout', {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } catch (_) {}
  }
}
