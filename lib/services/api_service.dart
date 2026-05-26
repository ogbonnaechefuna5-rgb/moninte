import 'dart:io';
import 'api_client.dart';
import 'auth_api.dart';
import 'transaction_api.dart';
import 'budget_api.dart';
import 'savings_api.dart';
import 'profile_api.dart';
import 'analytics_api.dart';

export 'api_client.dart';
export 'auth_api.dart';
export 'transaction_api.dart';
export 'budget_api.dart';
export 'savings_api.dart';
export 'profile_api.dart';
export 'analytics_api.dart';

/// Facade that preserves the existing injection interface.
/// Providers and screens continue to use [ApiService] unchanged.
/// Inject individual domain APIs directly for new code.
class ApiService {
  final ApiClient client;
  late final AuthApi _auth;
  late final TransactionApi _tx;
  late final BudgetApi _budget;
  late final SavingsApi _savings;
  late final ProfileApi _profile;
  late final AnalyticsApi _analytics;

  ApiService({String? baseUrl}) : client = ApiClient(baseUrl: baseUrl) {
    _auth = AuthApi(client);
    _tx = TransactionApi(client);
    _budget = BudgetApi(client);
    _savings = SavingsApi(client);
    _profile = ProfileApi(client);
    _analytics = AnalyticsApi(client);
  }

  // ── Token / auth state ──
  void setToken(String token) => client.setToken(token);
  String get baseUrl => client.baseUrl;
  String resolveUrl(String path) => client.resolveUrl(path);

  set onUnauthorized(Future<bool> Function()? fn) =>
      client.onUnauthorized = fn;

  // ── Auth ──
  Future<Map<String, dynamic>> login(String identifier, String password) =>
      _auth.login(identifier, password);

  Future<Map<String, dynamic>> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) =>
      _auth.signup(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        phone: phone,
        password: password,
        email: email,
      );

  Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _auth.refreshToken(refreshToken);

  Future<Map<String, dynamic>> oidcLogin(
          {required String provider, required String idToken}) =>
      _auth.oidcLogin(provider: provider, idToken: idToken);

  Future<void> logout(String? refreshToken) => _auth.logout(refreshToken);

  // ── Analytics / Categories / Dashboard / Health ──
  Future<Map<String, dynamic>> getAnalytics(String period) =>
      _analytics.getAnalytics(period);

  Future<Map<String, dynamic>> getCategories() => _analytics.getCategories();

  Future<Map<String, dynamic>> getCategoryBreakdown() =>
      _analytics.getCategoryBreakdown();

  Future<Map<String, dynamic>> getDashboard() => _analytics.getDashboard();

  Future<Map<String, dynamic>> getHealthScore() => _analytics.getHealthScore();

  // ── Budgets ──
  Future<Map<String, dynamic>> getBudgets({int page = 1, int limit = 20}) =>
      _budget.getBudgets(page: page, limit: limit);

  Future<Map<String, dynamic>> createBudget(
          String category, double amount, String period) =>
      _budget.createBudget(category, amount, period);

  Future<void> deleteBudget(String id) => _budget.deleteBudget(id);

  // ── Savings ──
  Future<Map<String, dynamic>> getSavings() => _savings.getSavings();

  Future<Map<String, dynamic>> createGoal(
          String name, double targetAmount, String? deadline) =>
      _savings.createGoal(name, targetAmount, deadline);

  Future<void> updateSavingsProgress(String id, double amount) =>
      _savings.updateSavingsProgress(id, amount);

  Future<void> deleteGoal(String id) => _savings.deleteGoal(id);

  // ── Transactions ──
  Future<Map<String, dynamic>> getTransactions(
          {int page = 1, int limit = 20}) =>
      _tx.getTransactions(page: page, limit: limit);

  Future<Map<String, dynamic>> ingestSMSBatch(List<String> messages) =>
      _tx.ingestSMSBatch(messages);

  Future<Map<String, dynamic>> ingestManual({
    required double amount,
    required String type,
    required String merchant,
    String? category,
    String? description,
  }) =>
      _tx.ingestManual(
        amount: amount,
        type: type,
        merchant: merchant,
        category: category,
        description: description,
      );

  Future<Map<String, dynamic>> uploadStatement(File file) =>
      _tx.uploadStatement(file);

  // ── Profile ──
  Future<Map<String, dynamic>> getProfile() => _profile.getProfile();

  Future<void> updateProfile(Map<String, dynamic> data) =>
      _profile.updateProfile(data);

  Future<void> changePassword(String oldPassword, String newPassword) =>
      _profile.changePassword(oldPassword, newPassword);

  Future<void> deleteAccount() => _profile.deleteAccount();

  Future<String> uploadAvatar(File file) => _profile.uploadAvatar(file);

  // ── Preferences ──
  Future<Map<String, dynamic>> getPreferences() => _profile.getPreferences();

  Future<void> savePreferences(Map<String, dynamic> prefs) =>
      _profile.savePreferences(prefs);

  // ── Linked Accounts ──
  Future<Map<String, dynamic>> getLinkedAccounts(
          {int page = 1, int limit = 20}) =>
      _profile.getLinkedAccounts(page: page, limit: limit);

  Future<void> syncAccount(String id) => _profile.syncAccount(id);

  Future<void> removeAccount(String id) => _profile.removeAccount(id);

  // ── Sessions ──
  Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 20}) =>
      _profile.getSessions(page: page, limit: limit);

  Future<void> revokeSession(String id) => _profile.revokeSession(id);

  Future<void> revokeAllSessions() => _profile.revokeAllSessions();
}
