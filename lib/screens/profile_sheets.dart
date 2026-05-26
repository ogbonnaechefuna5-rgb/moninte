import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input_field.dart';
import '../widgets/modal_sheet.dart';
import '../widgets/glass_card.dart';
import '../widgets/passcode_screen.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../providers/security_provider.dart';

// ── Edit Profile ──────────────────────────────────────────────────────────────

void showEditProfileSheet(
  BuildContext context, {
  required String firstName,
  required String middleName,
  required String lastName,
  required String phone,
  required String email,
  required void Function({
    required String firstName,
    required String middleName,
    required String lastName,
    required String phone,
    required String email,
  }) onSaved,
}) {
  final firstCtrl  = TextEditingController(text: firstName);
  final middleCtrl = TextEditingController(text: middleName);
  final lastCtrl   = TextEditingController(text: lastName);
  final phoneCtrl  = TextEditingController(text: phone);
  final emailCtrl  = TextEditingController(text: email);

  showAppSheet(
    context,
    title: 'Edit Profile',
    child: StatefulBuilder(
      builder: (ctx, setSheet) {
        String? sheetError;
        return Column(children: [
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
                await ctx.read<ApiService>().updateProfile({
                  'first_name':  firstCtrl.text.trim(),
                  'middle_name': middleCtrl.text.trim(),
                  'last_name':   lastCtrl.text.trim(),
                  'phone':       phoneCtrl.text.trim(),
                  if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                });
                onSaved(
                  firstName:  firstCtrl.text.trim(),
                  middleName: middleCtrl.text.trim(),
                  lastName:   lastCtrl.text.trim(),
                  phone:      phoneCtrl.text.trim(),
                  email:      emailCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setSheet(() => sheetError = e.toString().replaceFirst('Exception: ', ''));
              }
            },
          ),
        ]);
      },
    ),
  );
}

// ── Change Password ───────────────────────────────────────────────────────────

void showChangePasswordSheet(BuildContext context) {
  final currentCtrl = TextEditingController();
  final newCtrl     = TextEditingController();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')));
            return;
          }
          try {
            await context.read<ApiService>().changePassword(currentCtrl.text, newCtrl.text);
            if (context.mounted) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password changed')));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())));
            }
          }
        },
      ),
    ]),
  );
}

// ── Active Sessions ───────────────────────────────────────────────────────────

Future<void> showActiveSessionsSheet(BuildContext context) async {
  List<Map<String, dynamic>> sessions = [];
  try {
    final data = await context.read<ApiService>().getSessions();
    sessions = (data['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  } catch (_) {}

  if (!context.mounted) return;
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: c.accent.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.smartphone, size: 18, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['device'] ?? 'Unknown device',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  Text('${s['os'] ?? ''} · ${s['ip_address'] ?? ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )),
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
          if (context.mounted) Navigator.pop(context);
        },
        color: AppColors.destructive,
      ),
    ]),
  );
}

// ── Security toggles ──────────────────────────────────────────────────────────

Future<void> toggleBiometric(BuildContext context, SecurityProvider security) async {
  if (security.biometricEnabled) {
    await security.setSecurity('biometricEnabled', false);
    return;
  }
  final available = await BiometricService.isAvailable();
  if (!context.mounted) return;
  if (!available) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometrics not available on this device')));
    return;
  }
  final ok = await BiometricService.authenticate(
      reason: 'Confirm identity to enable biometric login');
  if (!context.mounted) return;
  if (ok) await security.setSecurity('biometricEnabled', true);
}

Future<void> togglePasscode(BuildContext context, SecurityProvider security) async {
  if (security.passcodeEnabled) {
    final ok = await showPasscodeScreen(context,
        mode: PasscodeMode.verify,
        title: 'Enter Current Passcode',
        subtitle: 'Confirm to disable passcode');
    if (!context.mounted || ok != true) return;
    await security.setSecurity('passcodeEnabled', false);
  } else {
    final ok = await showPasscodeScreen(context, mode: PasscodeMode.setup);
    if (!context.mounted || ok != true) return;
    await security.setSecurity('passcodeEnabled', true);
  }
}
