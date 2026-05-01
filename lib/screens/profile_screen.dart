import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input_field.dart';
import '../widgets/modal_sheet.dart';
import '../widgets/section_label.dart';
import '../services/biometric_service.dart';

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

  String _name = 'Emmanuel Adeyemi';
  String _phone = '+234 813 456 7890';
  String _email = 'emmanuel.a@email.com';

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
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
      if (authenticated) {
        setState(() => _biometricEnabled = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed')),
        );
      }
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
      child: StatefulBuilder(
        builder: (ctx, _) => Column(children: [
          Center(
            child: Stack(children: [
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
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.accent,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: AppColors.background),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          AppInputField(hint: 'Full Name', controller: nameCtrl, icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppInputField(hint: 'Phone Number', controller: phoneCtrl, icon: Icons.phone_outlined),
          const SizedBox(height: 12),
          AppInputField(hint: 'Email Address', controller: emailCtrl, icon: Icons.email_outlined),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save Changes',
            onTap: () {
              setState(() {
                _name = nameCtrl.text.trim().isEmpty ? _name : nameCtrl.text.trim();
                _phone = phoneCtrl.text.trim().isEmpty ? _phone : phoneCtrl.text.trim();
                _email = emailCtrl.text.trim().isEmpty ? _email : emailCtrl.text.trim();
              });
              Navigator.pop(ctx);
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
        PrimaryButton(label: 'Update Password', onTap: () => Navigator.pop(context)),
      ]),
    );
  }

  void _showPinSecurity() {
    showAppSheet(
      context,
      title: 'PIN Security',
      child: Column(children: [
        _infoRow(Icons.pin, AppColors.accent, 'Current PIN', 'Last changed 30 days ago'),
        const SizedBox(height: 8),
        _infoRow(Icons.history, AppColors.textSecondary, 'PIN Attempts', '0 failed attempts'),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Change PIN', onTap: () => Navigator.pop(context)),
        const SizedBox(height: 8),
        OutlineButton(label: 'Reset via Email', onTap: () => Navigator.pop(context)),
      ]),
    );
  }

  void _showActiveSessions() {
    showAppSheet(
      context,
      title: 'Active Sessions',
      child: Column(children: [
        _sessionTile('This Device', 'iPhone 14 Pro · Lagos, NG', 'Active now', true),
        const SizedBox(height: 8),
        _sessionTile('Chrome · Web', 'MacBook Pro · Lagos, NG', '2 hours ago', false),
        const SizedBox(height: 20),
        OutlineButton(
          label: 'Sign Out All Other Sessions',
          onTap: () => Navigator.pop(context),
          color: AppColors.destructive,
        ),
      ]),
    );
  }

  void _showHelpCenter() {
    showAppSheet(
      context,
      title: 'Help Center',
      child: Column(children: [
        _helpItem(Icons.chat_bubble_outline, 'Live Chat', 'Chat with our support team'),
        const SizedBox(height: 8),
        _helpItem(Icons.email_outlined, 'Email Support', 'support@spendalt.com'),
        const SizedBox(height: 8),
        _helpItem(Icons.article_outlined, 'FAQs', 'Browse common questions'),
        const SizedBox(height: 8),
        _helpItem(Icons.video_library_outlined, 'Video Guides', 'Learn how to use Spendalt'),
      ]),
    );
  }

  void _showAbout() {
    showAppSheet(
      context,
      title: 'About Spendalt',
      child: Column(children: [
        Center(
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primaryGreen]),
            ),
            child: const Icon(Icons.auto_awesome, size: 36, color: AppColors.background),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Spendalt', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Version 1.0.0 · Build 2026.04', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        _infoRow(Icons.shield_outlined, AppColors.accent, 'Privacy Policy', 'How we handle your data'),
        const SizedBox(height: 8),
        _infoRow(Icons.description_outlined, AppColors.accent, 'Terms of Service', 'Usage terms and conditions'),
        const SizedBox(height: 8),
        _infoRow(Icons.code, AppColors.textSecondary, 'Open Source Licenses', 'Third-party libraries used'),
        const SizedBox(height: 8),
        const Text('Made with 💚 for Nigerian users', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
        onConfirm: () => Navigator.pop(context),
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
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDark.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
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
                _menuItem(Icons.link, 'Linked Accounts', badge: '3 banks', onTap: () => widget.onNavigate('linked-accounts')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Preferences'),
            GlassCard(
              child: Column(children: [
                _toggleItem(Icons.notifications_outlined, 'SMS Detection', _smsEnabled,
                    (v) => setState(() => _smsEnabled = v)),
                _divider(),
                _toggleItem(Icons.bar_chart_rounded, 'Analytics Tracking', _analyticsEnabled,
                    (v) => setState(() => _analyticsEnabled = v)),
                _divider(),
                _menuItem(Icons.tune, 'All Preferences', onTap: () => widget.onNavigate('preferences')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Security'),
            GlassCard(
              child: Column(children: [
                _toggleItem(Icons.shield_outlined, 'Biometric Login', _biometricEnabled,
                    (v) => _toggleBiometric(v)),
                _divider(),
                _menuItem(Icons.smartphone, 'PIN Security', onTap: _showPinSecurity),
                _divider(),
                _menuItem(Icons.shield, 'Active Sessions', onTap: _showActiveSessions),
                _divider(),
                _menuItem(Icons.settings, 'App Permissions', badge: 'Manage',
                    onTap: () => widget.onNavigate('permissions')),
              ]),
            ),

            const SizedBox(height: 24),

            const SectionLabel('Support'),
            GlassCard(
              child: Column(children: [
                _menuItem(Icons.help_outline, 'Help Center', onTap: _showHelpCenter),
                _divider(),
                _menuItem(Icons.info_outline, 'About Spendalt', onTap: _showAbout),
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
            const Center(child: Text('Spendalt v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            const SizedBox(height: 4),
            const Center(child: Text('Made with 💚 for Nigerian users', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // ── Private helpers ──

  Widget _sectionDivider() => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 20, endIndent: 20);
  Widget _divider() => _sectionDivider();

  Widget _menuItem(IconData icon, String label, {String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary))),
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
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary))),
        AppToggle(enabled: value, onChanged: () => onChanged(!value)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String sub) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
      ]),
    );
  }

  Widget _sessionTile(String device, String detail, String time, bool current) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: (current ? AppColors.accent : AppColors.textSecondary).withValues(alpha: 0.1),
          ),
          child: Icon(Icons.smartphone, size: 18, color: current ? AppColors.accent : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(device, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            if (current) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
                child: const Text('Current', style: TextStyle(color: AppColors.success, fontSize: 10)),
              ),
            ],
          ]),
          Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ])),
        if (!current)
          GestureDetector(
            onTap: () {},
            child: const Text('Revoke', style: TextStyle(color: AppColors.destructive, fontSize: 13)),
          ),
      ]),
    );
  }

  Widget _helpItem(IconData icon, String label, String sub) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {},
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.accent.withValues(alpha: 0.1)),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
      ]),
    );
  }
}

/// A confirmation bottom sheet used for destructive actions (log out, delete account).
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
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: 0.2)),
        ),
        const SizedBox(height: 20),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.15)),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(body,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
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
