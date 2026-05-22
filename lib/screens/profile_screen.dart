import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../router.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input_field.dart';
import '../widgets/modal_sheet.dart';
import '../widgets/section_label.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/preferences_provider.dart';
import '../widgets/passcode_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _smsEnabled = true;
  bool _analyticsEnabled = true;
  bool _loading = true;
  bool _avatarUploading = false;

  String _firstName = '';
  String _middleName = '';
  String _lastName  = '';
  String _name = '';
  String _phone = '';
  String _email = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await context.read<ApiService>().getProfile();
      final user = data['user'] as Map<String, dynamic>? ?? data;
      if (mounted) {
        setState(() {
          _firstName = user['first_name'] as String? ?? '';
          _middleName = user['middle_name'] as String? ?? '';
          _lastName  = user['last_name']  as String? ?? '';
          _name = '$_firstName $_lastName'.trim();
          _phone = user['phone'] as String? ?? '';
          _email = user['email'] as String? ?? '';
          _avatarUrl = context.read<ApiService>().resolveUrl(user['avatar_url'] as String? ?? '');
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    // Load preferences
    try {
      final prefs = await context.read<ApiService>().getPreferences();
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

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 512);
    if (picked == null || !mounted) return;
    setState(() => _avatarUploading = true);
    try {
      final url = await context.read<ApiService>().uploadAvatar(File(picked.path));
      if (mounted) setState(() { _avatarUrl = context.read<ApiService>().resolveUrl(url); _avatarUploading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _avatarUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
  Future<void> _toggleBiometric(PreferencesProvider prefs) async {
    if (prefs.biometricEnabled) {
      await prefs.setSecurity('biometricEnabled', false);
      return;
    }
    final available = await BiometricService.isAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics not available on this device')),
      );
      return;
    }
    final ok = await BiometricService.authenticate(reason: 'Confirm identity to enable biometric login');
    if (!mounted) return;
    if (ok) await prefs.setSecurity('biometricEnabled', true);
  }

  Future<void> _togglePasscode(PreferencesProvider prefs) async {
    if (prefs.passcodeEnabled) {
      final ok = await showPasscodeScreen(context,
          mode: PasscodeMode.verify,
          title: 'Enter Current Passcode',
          subtitle: 'Confirm to disable passcode');
      if (!mounted || ok != true) return;
      await prefs.setSecurity('passcodeEnabled', false);
    } else {
      final ok = await showPasscodeScreen(context, mode: PasscodeMode.setup);
      if (!mounted || ok != true) return;
      await prefs.setSecurity('passcodeEnabled', true);
    }
  }

  void _showEditProfile() {
    final firstCtrl  = TextEditingController(text: _firstName);
    final middleCtrl = TextEditingController(text: _middleName);
    final lastCtrl   = TextEditingController(text: _lastName);
    final phoneCtrl  = TextEditingController(text: _phone);
    final emailCtrl  = TextEditingController(text: _email);
    String? sheetError;

    showAppSheet(
      context,
      title: 'Edit Profile',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(children: [
          Row(children: [
            Expanded(child: AppInputField(hint: 'First Name', controller: firstCtrl, icon: Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: AppInputField(hint: 'Last Name', controller: lastCtrl, icon: Icons.person_outline)),
          ]),
          const SizedBox(height: 12),
          AppInputField(hint: 'Middle Name (optional)', controller: middleCtrl, icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppInputField(hint: 'Phone Number', controller: phoneCtrl, icon: Icons.phone_outlined),
          const SizedBox(height: 12),
          AppInputField(hint: 'Email Address', controller: emailCtrl, icon: Icons.email_outlined),
          if (sheetError != null) ...[
            const SizedBox(height: 10),
            Text(sheetError!, style: const TextStyle(color: AppColors.destructive, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save Changes',
            onTap: () async {
              try {
                await context.read<ApiService>().updateProfile({
                  'first_name':  firstCtrl.text.trim(),
                  'middle_name': middleCtrl.text.trim(),
                  'last_name':   lastCtrl.text.trim(),
                  'phone':       phoneCtrl.text.trim(),
                  if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                });
                setState(() {
                  _firstName  = firstCtrl.text.trim();
                  _middleName = middleCtrl.text.trim();
                  _lastName   = lastCtrl.text.trim();
                  _name  = '$_firstName $_lastName'.trim();
                  _phone = phoneCtrl.text.trim();
                  _email = emailCtrl.text.trim();
                });
                if (mounted) Navigator.pop(context);
              } catch (e) {
                setSheet(() => sheetError = e.toString().replaceFirst('Exception: ', ''));
              }
            },
          ),
        ]),
      ),
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
              await context.read<ApiService>().changePassword(currentCtrl.text, newCtrl.text);
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
      final data = await context.read<ApiService>().getSessions();
      sessions = (data['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {}

    if (!mounted) return;
    final c = AppColors.of(context);
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
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: c.accent.withValues(alpha: 0.1)),
                  child: Icon(Icons.smartphone, size: 18, color: c.accent),
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
              await context.read<ApiService>().revokeAllSessions();
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
            await context.read<ApiService>().deleteAccount();
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
        body: Center(child: CircularProgressIndicator(color: c.accent)),
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
                onTap: () => context.go(Routes.home),
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
              SizedBox(width: 12),
              Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
            ]),

            const SizedBox(height: 20),

            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [c.accent, AppColors.primaryGreen]),
                        ),
                        child: _avatarUploading
                            ? Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                            : _avatarUrl.isNotEmpty
                                ? ClipOval(child: Image.network(_avatarUrl, width: 80, height: 80, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(child: Text(_initials,
                                        style: const TextStyle(color: AppColors.background, fontSize: 24, fontWeight: FontWeight.w700)))))
                                : Center(child: Text(_initials,
                                    style: const TextStyle(color: AppColors.background, fontSize: 24, fontWeight: FontWeight.w700))),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent, border: Border.all(color: c.background, width: 2)),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
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
                _menuItem(Icons.link, 'Linked Accounts', onTap: () => context.go(Routes.linkedAccounts)),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Preferences'),
            GlassCard(
              child: Column(children: [
                _toggleItem(Icons.notifications_outlined, 'SMS Detection', _smsEnabled, (v) {
                  setState(() => _smsEnabled = v);
                  context.read<ApiService>().savePreferences({'sms_detection': _smsEnabled, 'analytics': _analyticsEnabled, 'partner_offers': false});
                }),
                _divider(),
                _toggleItem(Icons.bar_chart_rounded, 'Analytics Tracking', _analyticsEnabled, (v) {
                  setState(() => _analyticsEnabled = v);
                  context.read<ApiService>().savePreferences({'sms_detection': _smsEnabled, 'analytics': _analyticsEnabled, 'partner_offers': false});
                }),
                _divider(),
                _menuItem(Icons.tune, 'All Preferences', onTap: () => context.go(Routes.preferences)),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Security'),
            Consumer<PreferencesProvider>(
              builder: (_, prefs, __) => GlassCard(
                child: Column(children: [
                  _toggleItem(Icons.fingerprint, 'Biometric Login', prefs.biometricEnabled, (_) => _toggleBiometric(prefs)),
                  _divider(),
                  _toggleItem(Icons.pin_outlined, 'Passcode', prefs.passcodeEnabled, (_) => _togglePasscode(prefs)),
                  _divider(),
                  _menuItem(Icons.shield, 'Active Sessions', onTap: _showActiveSessions),
                  _divider(),
                  _menuItem(Icons.settings, 'App Permissions', badge: 'Manage', onTap: () => context.go(Routes.permissions)),
                ]),
              ),
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
          SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: c.textPrimary))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: c.accent.withValues(alpha: 0.08),
              ),
              child: Text(badge, style: TextStyle(color: c.accent, fontSize: 12)),
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
