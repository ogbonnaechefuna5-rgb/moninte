import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../widgets/section_label.dart';
import '../widgets/screen_header.dart';
import '../widgets/passcode_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/security_provider.dart';
import '../services/biometric_service.dart';
import '../router.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String get _theme => context.read<ThemeProvider>().modeKey;
  void _setTheme(String key) => context.read<ThemeProvider>().setMode(key);

  bool _showClearConfirm = false;

  Future<void> _toggleBiometric(SecurityProvider security) async {
    if (security.biometricEnabled) {
      await security.setSecurity('biometricEnabled', false);
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
    final ok = await BiometricService.authenticate(reason: 'Set up biometric login');
    if (!mounted) return;
    if (ok) await security.setSecurity('biometricEnabled', true);
  }

  Future<void> _togglePasscode(SecurityProvider security) async {
    if (security.passcodeEnabled) {
      final confirmed = await showPasscodeScreen(context,
          mode: PasscodeMode.verify,
          subtitle: 'Enter your current passcode to disable it');
      if (!mounted) return;
      if (confirmed == true) await security.setSecurity('passcodeEnabled', false);
      return;
    }
    final set = await showPasscodeScreen(context, mode: PasscodeMode.setup);
    if (!mounted) return;
    if (set == true) await security.setSecurity('passcodeEnabled', true);
  }

  Future<void> _clearCache() async {
    context.read<DashboardProvider>().invalidate();
    context.read<AnalyticsProvider>().invalidate();
    setState(() => _showClearConfirm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon')),
    );
  }

  static const _notifItems = [
    _Item('transactionAlerts', Icons.bolt, Color(0xFFA8FF3E), 'Transaction Alerts', 'Instant alerts for every debit and credit'),
    _Item('budgetWarnings', Icons.trending_up, Color(0xFFFFB830), 'Budget Warnings', "When you're approaching or over your limits"),
    _Item('aiInsights', Icons.bar_chart, Color(0xFF4DFF91), 'AI Insights', 'Weekly spending patterns and smart tips'),
    _Item('weeklyReport', Icons.calendar_today, Color(0xFF8A9E90), 'Weekly Digest', "Sunday summary of the week's finances", comingSoon: true),
    _Item('savingsReminders', Icons.notifications, Color(0xFFA8FF3E), 'Savings Reminders', "Nudges when you're behind on savings goals", comingSoon: true),
    _Item('promotions', Icons.notifications_off, Color(0xFF8A9E90), 'Tips & Promotions', 'Financial tips and feature announcements', comingSoon: true),
  ];

  static const _privacyItems = [
    _Item('hideBalances', Icons.visibility_off, Color(0xFFA8FF3E), 'Hide Balances', 'Mask amounts on the dashboard by default'),
    _Item('shareAnalytics', Icons.share, Color(0xFF8A9E90), 'Usage Analytics', 'Help us improve by sharing anonymous usage data'),
    _Item('crashReports', Icons.bug_report, Color(0xFF8A9E90), 'Crash Reports', 'Automatically send crash logs to our team'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final prefs = context.watch<PreferencesProvider>();
    final security = context.watch<SecurityProvider>();
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                ScreenHeader(title: 'Preferences', subtitle: 'Customise your Moninte experience', onBack: () => context.go(Routes.profile)),
                const SizedBox(height: 24),

                // ── Display ──
                const SectionLabel('Display'),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Align(alignment: Alignment.centerLeft, child: Text('Theme', style: TextStyle(color: c.textPrimary, fontSize: 14))),
                    const SizedBox(height: 12),
                    Row(children: [
                      _themeOption(context, 'dark', 'Dark', Icons.dark_mode),
                      const SizedBox(width: 8),
                      _themeOption(context, 'light', 'Light', Icons.light_mode),
                      const SizedBox(width: 8),
                      _themeOption(context, 'system', 'System', Icons.computer),
                    ]),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: c.borderDefault),
                    const SizedBox(height: 16),
                    _settingRow(context, 'Currency', 'Used for all displayed amounts', '₦ NGN'),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: c.borderDefault),
                    const SizedBox(height: 16),
                    _settingRow(context, 'Language', 'App display language', 'EN (NG)', icon: Icons.language),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Security ──
                const SectionLabel('Security'),
                GlassCard(
                  child: Column(children: [
                    _toggleRow(
                      context,
                      const _Item('biometricEnabled', Icons.fingerprint, Color(0xFF4DFF91), 'Biometric Login', 'Use Face ID or fingerprint to unlock'),
                      security.biometricEnabled,
                      () => _toggleBiometric(security),
                    ),
                    Divider(height: 1, color: c.borderDefault),
                    _toggleRow(
                      context,
                      const _Item('passcodeEnabled', Icons.lock_outline, Color(0xFFA8FF3E), 'Passcode Lock', 'Require a 6-digit passcode to open the app'),
                      security.passcodeEnabled,
                      () => _togglePasscode(security),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Notifications ──
                const SectionLabel('Notifications'),
                GlassCard(
                  child: Column(
                    children: _notifItems.asMap().entries.map((e) {
                      final i = e.key; final item = e.value;
                      return Column(children: [
                        _toggleRow(context, item, prefs.valueOf(item.key), item.comingSoon ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon')),
                          );
                        } : () => prefs.toggle(item.key)),
                        if (i < _notifItems.length - 1) Divider(height: 1, color: c.borderDefault),
                      ]);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Privacy ──
                const SectionLabel('Privacy'),
                GlassCard(
                  child: Column(
                    children: _privacyItems.asMap().entries.map((e) {
                      final i = e.key; final item = e.value;
                      return Column(children: [
                        _toggleRow(context, item, prefs.valueOf(item.key), () => prefs.toggle(item.key)),
                        if (i < _privacyItems.length - 1) Divider(height: 1, color: c.borderDefault),
                      ]);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Data ──
                const SectionLabel('Data'),
                GlassCard(
                  child: Column(children: [
                    _actionRow(context, Icons.download, AppColors.success, 'Export My Data', 'Download all transactions as CSV', _exportData),
                    Divider(height: 1, color: c.borderDefault),
                    _actionRow(context, Icons.delete_outline, AppColors.destructive, 'Clear Cache', "Free up space (won't delete your data)", () => setState(() => _showClearConfirm = true)),
                  ]),
                ),

                const SizedBox(height: 24),

                // App version
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('App Version', style: TextStyle(color: c.textPrimary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Moninte v1.0.0 — Build 2026.04', style: TextStyle(color: c.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: AppColors.success.withValues(alpha: 0.1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        const Text('Up to date', style: TextStyle(color: AppColors.success, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),

            if (_showClearConfirm) _buildClearConfirm(context),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String value, String label, IconData icon) {
    final c = AppColors.of(context);
    final selected = _theme == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { _setTheme(value); setState(() {}); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? c.accent.withValues(alpha: 0.15) : c.surfaceDark.withValues(alpha: 0.4),
            border: Border.all(color: selected ? c.accent.withValues(alpha: 0.5) : c.borderDefault),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: selected ? c.accent : c.textSecondary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: selected ? c.accent : c.textSecondary, fontSize: 12)),
            if (selected) ...[
              const SizedBox(height: 6),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _settingRow(BuildContext context, String label, String desc, String value, {IconData? icon}) {
    final c = AppColors.of(context);
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.textPrimary, fontSize: 14)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(color: c.textSecondary, fontSize: 12)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: c.surfaceDark.withValues(alpha: 0.6),
          border: Border.all(color: c.borderDefault),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: c.textSecondary), const SizedBox(width: 4)],
          Text(value, style: TextStyle(color: c.textPrimary, fontSize: 14)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: c.textSecondary),
        ]),
      ),
    ]);
  }

  Widget _toggleRow(BuildContext context, _Item item, bool enabled, VoidCallback onToggle) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: item.iconColor.withValues(alpha: 0.1)),
          child: Icon(item.icon, size: 16, color: item.iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(item.label, style: TextStyle(color: c.textPrimary, fontSize: 14)),
            if (item.comingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: c.textSecondary.withValues(alpha: 0.1)),
                child: Text('Soon', style: TextStyle(color: c.textSecondary, fontSize: 10)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(item.desc, style: TextStyle(color: c.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        AppToggle(enabled: enabled, onChanged: onToggle),
      ]),
    );
  }

  Widget _actionRow(BuildContext context, IconData icon, Color color, String label, String desc, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color == AppColors.destructive ? color : c.textPrimary, fontSize: 14)),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, size: 16, color: c.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildClearConfirm(BuildContext context) {
    final c = AppColors.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showClearConfirm = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.surfaceLight, c.surfaceDark]),
                  border: Border.all(color: c.borderDefault),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: c.textSecondary.withValues(alpha: 0.3))),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.destructive.withValues(alpha: 0.15)),
                      child: const Icon(Icons.delete_outline, size: 20, color: AppColors.destructive),
                    ),
                    const SizedBox(width: 12),
                    Text('Clear Cache?', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'This will clear locally cached data (chart thumbnails, recent search history). Your transactions and account data will not be affected.',
                    style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => setState(() => _showClearConfirm = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.borderDefault),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: _clearCache,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructive, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Clear Cache'),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String key, label, desc;
  final IconData icon;
  final Color iconColor;
  final bool comingSoon;
  const _Item(this.key, this.icon, this.iconColor, this.label, this.desc, {this.comingSoon = false});
}
