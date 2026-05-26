import 'dart:io';
import 'api_client.dart';

class ProfileApi {
  final ApiClient _client;
  ProfileApi(this._client);

  Future<Map<String, dynamic>> getProfile() => _client.get('/user/profile');

  Future<void> updateProfile(Map<String, dynamic> data) =>
      _client.put('/user/profile', data);

  Future<void> changePassword(String oldPassword, String newPassword) =>
      _client.post('/user/change-password', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

  Future<void> deleteAccount() => _client.delete('/user/account');

  Future<String> uploadAvatar(File file) async {
    final res = await _client.multipart('/user/avatar', 'avatar', file);
    return res['avatar_url'] as String;
  }

  Future<Map<String, dynamic>> getPreferences() =>
      _client.get('/user/preferences');

  Future<void> savePreferences(Map<String, dynamic> prefs) =>
      _client.put('/user/preferences', prefs);

  Future<Map<String, dynamic>> getLinkedAccounts(
          {int page = 1, int limit = 20}) =>
      _client.get('/user/linked-accounts?page=$page&limit=$limit');

  Future<void> syncAccount(String id) =>
      _client.post('/user/linked-accounts/$id/sync', {});

  Future<void> removeAccount(String id) =>
      _client.delete('/user/linked-accounts/$id');

  Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 20}) =>
      _client.get('/user/sessions?page=$page&limit=$limit');

  Future<void> revokeSession(String id) => _client.delete('/user/sessions/$id');

  Future<void> revokeAllSessions() => _client.delete('/user/sessions');
}
