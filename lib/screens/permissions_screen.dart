import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_toggle.dart';
import '../widgets/screen_header.dart';
import '../models/permission.dart';
import '../services/biometric_service.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const PermissionsScreen({super.key, required this.onBack});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final List<Permission> _perms = [
    Permission(id: 'sms', icon: Icons.message_outlined, iconColor: Color(0xFFA8FF3E), title: 'SMS Detection', subtitle: 'Core feature',
        description: 'Allows Moninte to read incoming SMS messages from your bank to automatically detect and categorise transactions. Only bank-formatted SMS are parsed — personal messages are never read or stored.',
        enabled: true, required: true, status: 'granted'),
    Permission(id: 'notifications', icon: Icons.notifications_outlined, iconColor: Color(0xFFFFB830), title: 'Push Notifications', subtitle: 'Alerts & insights',
        description: 'Receive real-time alerts when you go over budget, when a new AI insight is ready, or when a transaction is detected.',
        enabled: true, required: false, status: 'granted'),
    Permission(id: 'biometric', icon: Icons.fingerprint, iconColor: Color(0xFFA8FF3E), title: 'Biometric Authentication', subtitle: 'Security',
        description: 'Use your fingerprint or Face ID to unlock Moninte instead of your PIN. Your biometric data stays on your device.',
        enabled: true, required: false, status: 'granted'),
    Permission(id: 'background', icon: Icons.refresh, iconColor: Color(0xFF4DFF91), title: 'Background App Refresh', subtitle: 'Sync & freshness',
        description: 'Allows Moninte to sync your account data in the background so your balances are always up to date.',
        enabled: false, required: false, status: 'denied'),
    Permission(id: 'location', icon: Icons.location_on_outlined, iconColor: Color(0xFF8A9E90), title: 'Location (Optional)', subtitle: 'Merchant context',
        description: 'Used to enrich transaction details with merchant location info. Completely optional and only accessed when you open a transaction.',
        enabled: false, required: false, status: 'not-asked'),
  ];

  String? _expanded = 'sms';

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      final i = _perms.indexWhere((p) => p.id == 'biometric');
      if (i != -1) {
        _perms[i] = _perms[i].copyWith(
          enabled: enabled,
          status: enabled ? 'granted' : 'denied',
        );
      }
    });
  }

  void _toggle(String id) async {
    final p = _perms.firstWhere((p) => p.id == id);
    if (p.required && p.enabled) return;

    if (id == 'biometric') {
      final available = await BiometricService.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrics not available on this device')),
        );
        return;
      }
      final enable = !p.enabled;
      final ok = await BiometricService.authenticate(
        reason: enable ? 'Confirm identity to enable biometric login' : 'Confirm identity to disable biometric login',
      );
      if (!mounted || !ok) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enable);
    }

    setState(() {
      final i = _perms.indexOf(p);
      _perms[i] = p.copyWith(enabled: !p.enabled, status: !p.enabled ? 'granted' : 'denied');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final granted = _perms.where((p) => p.status == 'granted').length;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            // Header
            ScreenHeader(
              title: 'Permissions',
              subtitle: '$granted of ${_perms.length} granted',
              onBack: widget.onBack,
            ),

            SizedBox(height: 20),

            // Permission health
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.shield, size: 20, color: c.accent),
                  const SizedBox(width: 8),
                  Text('Permission health', style: TextStyle(color: c.textPrimary)),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: granted / _perms.length,
                    backgroundColor: c.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  granted == _perms.length
                      ? 'All permissions granted — Moninte runs at full power'
                      : '${_perms.length - granted} permission${_perms.length - granted != 1 ? 's' : ''} not yet granted',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // Required notice
            GlassCard(
              padding: const EdgeInsets.all(16),
              border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(child: RichText(text: TextSpan(
                  style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.5),
                  children: [
                    const TextSpan(text: 'Permissions marked '),
                    TextSpan(text: 'Core feature', style: TextStyle(color: c.accent)),
                    const TextSpan(text: ' are required for Moninte to work. Revoking them will disable key functionality.'),
                  ],
                ))),
              ]),
            ),

            const SizedBox(height: 16),

            // Permission items
            ..._perms.map((p) {
              final isExpanded = _expanded == p.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: p.iconColor.withValues(alpha: 0.1)),
                          child: Icon(p.icon, size: 20, color: p.iconColor),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(p.title, style: TextStyle(color: c.textPrimary)),
                            if (p.required) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: c.accent.withValues(alpha: 0.1)),
                                child: Text('Core', style: TextStyle(color: c.accent, fontSize: 10)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            if (p.status == 'granted') const Icon(Icons.check_circle, size: 12, color: AppColors.success)
                            else if (p.status == 'denied') Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.destructive.withValues(alpha: 0.6)))
                            else Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: c.textSecondary.withValues(alpha: 0.4))),
                            const SizedBox(width: 6),
                            Text(p.status == 'not-asked' ? 'Not requested' : p.status, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                          ]),
                        ])),
                        // Toggle
                        AppToggle(
                          enabled: p.enabled,
                          locked: p.required && p.enabled,
                          onChanged: () => _toggle(p.id),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = isExpanded ? null : p.id),
                          child: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: c.textSecondary),
                        ),
                      ]),
                    ),
                    if (isExpanded) ...[
                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.description, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5)),
                          if (p.status == 'denied' || p.status == 'not-asked') ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _toggle(p.id),
                              child: Text(
                                p.status == 'denied' ? 'Grant this permission →' : 'Request permission →',
                                style: TextStyle(color: c.accent, fontSize: 14),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ],
                  ]),
                ),
              );
            }),

            const SizedBox(height: 8),
            Center(child: Text(
              "You can also manage app permissions in your device's system Settings → Apps → Moninte.",
              style: TextStyle(color: c.textSecondary, fontSize: 12), textAlign: TextAlign.center,
            )),
          ],
        ),
      ),
    );
  }
}
