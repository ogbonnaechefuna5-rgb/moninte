import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input_field.dart';
import '../widgets/modal_sheet.dart';
import '../widgets/section_label.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<String> onNavigate;
  const ProfileScreen({super.key, required this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _smsEnabled = true;
  bool _analyticsEnabled = true;
  bool _biometricEnabled = true;
  bool _loading = true;

  String _name = '';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      final user = data['user'] as Map<String, dynamic>? ?? data;
      if (mounted) {
        setState(() {
          final first = user['first_name'] ?? '';
          final last = user['last_name'] ?? '';
          _name = '$first $last'.trim();
          _phone = user['phone'] ?? '';
          _email = user['email'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    // Load preferences
    try {
      final prefs = await ApiService.getPreferences();
      final p = prefs['preferences'] as Map<String, dynamic>? ?? prefs;
      if (mounted) {
        setState(() {
          _smsEnabled = p['sms_detection'] ?? true;
          _analyticsEnabled = p['analytics'] ?? true;
        });
      }
    } catch (_) {}
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final available = await BiometricService.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrics not available on this device')),
        );
        return;
      }
      final authenticated = await BiometricService.authenticate(
        reason: 'Confirm your identity to enable biometric login',
      );
      if (!mounted) return;
      if (authenticated) setState(() => _biometricEnabled = true);
    } else {
      final authenticated = await BiometricService.authenticate(
        reason: 'Confirm your identity to disable biometric login',
      );
      if (!mounted) return;
      if (authenticated) setState(() => _biometricEnabled = false);
    }
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);

    showAppSheet(
      context,
      title: 'Edit Profile',
      child: Column(children: [
        AppInputField(hint: 'Full Name', controller: nameCtrl, icon: Icons.person_outline),
        const SizedBox(height: 12),
        AppInputField(hint: 'Phone Number', controller: phoneCtrl, icon: Icons.phone_outlined),
        const SizedBox(height: 12),
        AppInputField(hint: 'Email Address', controller: emailCtrl, icon: Icons.email_outlined),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save Changes',
          onTap: () async {
            final nameParts = nameCtrl.text.trim().split(RegExp(r'\s+'));
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            try {
              await ApiService.updateProfile({
                'first_name': firstName,
                'last_name': lastName,
                'phone': phoneCtrl.text.trim(),
              });
              setState(() {
                _name = nameCtrl.text.trim();
                _phone = phoneCtrl.text.trim();
                _email = emailCtrl.text.trim();
              });
            } catch (_) {}
            if (mounted) Navigator.pop(context);
          },
        ),
      ]),
    );
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showAppSheet(
      context,
      title: 'Change Password',
      child: Column(children: [
        AppInputField(hint: 'Current Password', controller: currentCtrl, icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 12),
        AppInputField(hint: 'New Password', controller: newCtrl, icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 12),
        AppInputField(hint: 'Confirm New Password', controller: confirmCtrl, icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Update Password',
          onTap: () async {
            if (newCtrl.text != confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
              return;
            }
            try {
              await ApiService.changePassword(currentCtrl.text, newCtrl.text);
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        ),
      ]),
    );
  }

  void _showActiveSessions() async {
    List<Map<String, dynamic>> sessions = [];
    try {
      final data = await ApiService.getSessions();
      sessions = (data['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {}

    if (!mounted) return;
    showAppSheet(
      context,
      title: 'Active Sessions',
      child: Column(children: [
        if (sessions.isEmpty)
          Text('No active sessions', style: TextStyle(color: AppColors.textSecondary))
        else
          ...sessions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.accent.withValues(alpha: 0.1)),
                  child: const Icon(Icons.smartphone, size: 18, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['device'] ?? 'Unknown device', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  Text('${s['os'] ?? ''} · ${s['ip_address'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
              ]),
            ),
          )),
        const SizedBox(height: 20),
        OutlineButton(
          label: 'Sign Out All Other Sessions',
          onTap: () async {
            try {
              await ApiService.revokeAllSessions();
            } catch (_) {}
            if (mounted) Navigator.pop(context);
          },
          color: AppColors.destructive,
        ),
      ]),
    );
  }

  void _showLogOut() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmSheet(
        icon: Icons.logout,
        iconColor: AppColors.warning,
        title: 'Log Out?',
        body: 'You will be signed out of your account. Your data will remain safe.',
        confirmLabel: 'Log Out',
        confirmColor: AppColors.warning,
        onConfirm: () {
          Navigator.pop(context);
          context.read<AuthProvider>().logout();
        },
      ),
    );
  }

  void _showDeleteAccount() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmSheet(
        icon: Icons.delete_outline,
        iconColor: AppColors.destructive,
        title: 'Delete Account?',
        body: 'This will permanently delete your account and all associated data. This action cannot be undone.',
        confirmLabel: 'Delete Account',
        confirmColor: AppColors.destructive,
        onConfirm: () async {
          try {
            await ApiService.deleteAccount();
            if (mounted) {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            }
          } catch (_) {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => widget.onNavigate('home'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceDark.withValues(alpha: 0.5),
                    border: Border.all(color: c.borderDefault),
                  ),
                  child: Icon(Icons.arrow_back, size: 20, color: c.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
            ]),

            const SizedBox(height: 20),

            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.primaryGreen]),
                  ),
                  child: Center(
                    child: Text(_initials,
                        style: const TextStyle(color: AppColors.background, fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(_phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    if (_email.isNotEmpty)
                      Text(_email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Account'),
            GlassCard(
              child: Column(children: [
                _menuItem(Icons.person_outline, 'Edit Profile', onTap: _showEditProfile),
                _divider(),
                _menuItem(Icons.lock_outline, 'Change Password', onTap: _showChangePassword),
                _divider(),
                _menuItem(Icons.link, 'Linked Accounts', onTap: () => widget.onNavigate('linked-accounts')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Preferences'),
            GlassCard(
              child: Column(children: [
                _toggleItem(Icons.notifications_outlined, 'SMS Detection', _smsEnabled, (v) {
                  setState(() => _smsEnabled = v);
                  ApiService.savePreferences(_smsEnabled, _analyticsEnabled, false);
                }),
                _divider(),
                _toggleItem(Icons.bar_chart_rounded, 'Analytics Tracking', _analyticsEnabled, (v) {
                  setState(() => _analyticsEnabled = v);
                  ApiService.savePreferences(_smsEnabled, _analyticsEnabled, false);
                }),
                _divider(),
                _menuItem(Icons.tune, 'All Preferences', onTap: () => widget.onNavigate('preferences')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Security'),
            GlassCard(
              child: Column(children: [
                _toggleItem(Icons.shield_outlined, 'Biometric Login', _biometricEnabled, (v) => _toggleBiometric(v)),
                _divider(),
                _menuItem(Icons.shield, 'Active Sessions', onTap: _showActiveSessions),
                _divider(),
                _menuItem(Icons.settings, 'App Permissions', badge: 'Manage', onTap: () => widget.onNavigate('permissions')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Actions'),
            GlassCard(
              child: Column(children: [
                _menuItem(Icons.logout, 'Log Out', onTap: _showLogOut),
                _divider(),
                _menuItemDanger(Icons.delete_outline, 'Delete Account', onTap: _showDeleteAccount),
              ]),
            ),

            const SizedBox(height: 24),
            const Center(child: Text('Moninte v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.of(context).borderDefault, indent: 20, endIndent: 20);

  Widget _menuItem(IconData icon, String label, {String? badge, VoidCallback? onTap}) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: c.textPrimary))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
              child: Text(badge, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
            ),
          Icon(Icons.chevron_right, size: 20, color: c.textSecondary),
        ]),
      ),
    );
  }

  Widget _menuItemDanger(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.destructive),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.destructive))),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.destructive),
        ]),
      ),
    );
  }

  Widget _toggleItem(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: c.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: c.textPrimary))),
        AppToggle(enabled: value, onChanged: () => onChanged(!value)),
      ]),
    );
  }
}

/// A confirmation bottom sheet used for destructive actions.
class ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const ConfirmSheet({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceLight, AppColors.surfaceDark],
        ),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.2))),
        const SizedBox(height: 20),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.15)),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ]),
      ]),
    );
  }
}
