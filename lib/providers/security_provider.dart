import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns biometric and passcode security settings only.
/// Kept separate from [PreferencesProvider] so security state
/// can be read independently (e.g. by the lock overlay in the router).
class SecurityProvider extends ChangeNotifier {
  bool biometricEnabled = false;
  bool passcodeEnabled  = false;

  SecurityProvider() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    biometricEnabled = p.getBool('pref_biometricEnabled') ?? false;
    passcodeEnabled  = p.getBool('pref_passcodeEnabled')  ?? false;
    notifyListeners();
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
}
