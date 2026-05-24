import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PreferencesProvider extends ChangeNotifier {
  final ApiService _api;

  bool transactionAlerts = true;
  bool budgetWarnings    = true;
  bool aiInsights        = true;
  bool weeklyReport      = false;
  bool savingsReminders  = true;
  bool promotions        = false;
  bool hideBalances      = false;
  bool shareAnalytics    = true;
  bool crashReports      = true;
  bool biometricEnabled  = false;
  bool passcodeEnabled   = false;

  PreferencesProvider(this._api) {
    _loadLocal().then((_) => _fetchRemote());
  }

  // ── Load from SharedPreferences (instant, used while remote loads) ──

  Future<void> _loadLocal() async {
    final p = await SharedPreferences.getInstance();
    transactionAlerts = p.getBool('pref_transactionAlerts') ?? true;
    budgetWarnings    = p.getBool('pref_budgetWarnings')    ?? true;
    aiInsights        = p.getBool('pref_aiInsights')        ?? true;
    weeklyReport      = p.getBool('pref_weeklyReport')      ?? false;
    savingsReminders  = p.getBool('pref_savingsReminders')  ?? true;
    promotions        = p.getBool('pref_promotions')        ?? false;
    hideBalances      = p.getBool('pref_hideBalances')      ?? false;
    shareAnalytics    = p.getBool('pref_shareAnalytics')    ?? true;
    crashReports      = p.getBool('pref_crashReports')      ?? true;
    biometricEnabled  = p.getBool('pref_biometricEnabled')  ?? false;
    passcodeEnabled   = p.getBool('pref_passcodeEnabled')   ?? false;
    notifyListeners();
  }

  // ── Fetch from backend and overwrite local cache ──

  Future<void> _fetchRemote() async {
    try {
      final data = await _api.getPreferences();
      final p = data['preferences'] as Map<String, dynamic>? ?? data;
      transactionAlerts = p['transaction_alerts'] as bool? ?? transactionAlerts;
      budgetWarnings    = p['budget_warnings']    as bool? ?? budgetWarnings;
      aiInsights        = p['ai_insights']        as bool? ?? aiInsights;
      weeklyReport      = p['weekly_report']      as bool? ?? weeklyReport;
      savingsReminders  = p['savings_reminders']  as bool? ?? savingsReminders;
      promotions        = p['promotions']         as bool? ?? promotions;
      hideBalances      = p['hide_balances']      as bool? ?? hideBalances;
      shareAnalytics    = p['analytics']          as bool? ?? shareAnalytics;
      crashReports      = p['crash_reports']      as bool? ?? crashReports;
      await _saveLocal();
      notifyListeners();
    } catch (_) {
      // Offline — local values remain
    }
  }

  // ── Toggle a preference, persist locally and remotely ──

  Future<void> toggle(String key) async {
    switch (key) {
      case 'transactionAlerts': transactionAlerts = !transactionAlerts; break;
      case 'budgetWarnings':    budgetWarnings    = !budgetWarnings;    break;
      case 'aiInsights':        aiInsights        = !aiInsights;        break;
      case 'weeklyReport':      weeklyReport      = !weeklyReport;      break;
      case 'savingsReminders':  savingsReminders  = !savingsReminders;  break;
      case 'promotions':        promotions        = !promotions;        break;
      case 'hideBalances':      hideBalances      = !hideBalances;      break;
      case 'shareAnalytics':    shareAnalytics    = !shareAnalytics;    break;
      case 'crashReports':      crashReports      = !crashReports;      break;
    }
    notifyListeners();
    await _saveLocal();
    _saveRemote();
  }

  Future<void> setSecurity(String key, bool value) async {
    if (key == 'biometricEnabled') biometricEnabled = value;
    if (key == 'passcodeEnabled')  passcodeEnabled  = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_$key', value);
    if (!value && key == 'passcodeEnabled') {
      await p.remove('app_passcode');
    }
  }

  bool valueOf(String key) {
    switch (key) {
      case 'transactionAlerts': return transactionAlerts;
      case 'budgetWarnings':    return budgetWarnings;
      case 'aiInsights':        return aiInsights;
      case 'weeklyReport':      return weeklyReport;
      case 'savingsReminders':  return savingsReminders;
      case 'promotions':        return promotions;
      case 'hideBalances':      return hideBalances;
      case 'shareAnalytics':    return shareAnalytics;
      case 'crashReports':      return crashReports;
      case 'biometricEnabled':  return biometricEnabled;
      case 'passcodeEnabled':   return passcodeEnabled;
      default:                  return false;
    }
  }

  Future<void> _saveLocal() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_transactionAlerts', transactionAlerts);
    await p.setBool('pref_budgetWarnings',    budgetWarnings);
    await p.setBool('pref_aiInsights',        aiInsights);
    await p.setBool('pref_weeklyReport',      weeklyReport);
    await p.setBool('pref_savingsReminders',  savingsReminders);
    await p.setBool('pref_promotions',        promotions);
    await p.setBool('pref_hideBalances',      hideBalances);
    await p.setBool('pref_shareAnalytics',    shareAnalytics);
    await p.setBool('pref_crashReports',      crashReports);
    await p.setBool('pref_biometricEnabled',  biometricEnabled);
    await p.setBool('pref_passcodeEnabled',   passcodeEnabled);
  }

  Future<void> _saveRemote() async {
    try {
      await _api.savePreferences({
        'transaction_alerts':  transactionAlerts,
        'budget_warnings':     budgetWarnings,
        'ai_insights':         aiInsights,
        'weekly_report':       weeklyReport,
        'savings_reminders':   savingsReminders,
        'promotions':          promotions,
        'hide_balances':       hideBalances,
        'analytics':           shareAnalytics,
        'crash_reports':       crashReports,
      });
    } catch (_) {
      // Offline — local already saved, will sync next time
    }
  }
}
