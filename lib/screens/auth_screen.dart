import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../widgets/app_input_field.dart';
import '../widgets/app_button.dart';
import '../widgets/passcode_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const AuthScreen({super.key, required this.onComplete});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/moninte-logo.png', height: 44),
            const SizedBox(height: 8),
            Text('moninte', style: AppTheme.monoSized(22, weight: FontWeight.w700, color: c.accent)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderDefault),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: c.background,
                  unselectedLabelColor: c.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LoginForm(onSuccess: widget.onComplete),
                  _RegisterForm(onSuccess: () => _tab.animateTo(0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login ──

class _LoginForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _LoginForm({required this.onSuccess});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _biometricAvailable = false;
  BiometricType? _biometricType;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    if (!mounted) return;
    if (!available) return;
    final types = await BiometricService.availableTypes();
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString('token') != null;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = true;
      _biometricType = types.contains(BiometricType.face)
          ? BiometricType.face
          : BiometricType.fingerprint;
    });
    if (hasToken) _triggerBiometric();
  }

  Future<void> _triggerBiometric() async {
    setState(() { _loading = true; _error = null; });
    final ok = await BiometricService.authenticate(reason: 'Sign in to Moninte');
    if (!mounted) return;
    if (ok) {
      await context.read<AuthProvider>().refresh();
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        widget.onSuccess();
      } else {
        setState(() { _loading = false; _error = 'Session expired. Please sign in with your password.'; });
      }
    } else {
      setState(() { _loading = false; _error = 'Biometric authentication failed'; });
    }
  }

  Future<void> _triggerPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString('token') != null;
    if (!hasToken) {
      setState(() => _error = 'No saved session. Please sign in with your password.');
      return;
    }
    if (!mounted) return;
    final ok = await showPasscodeScreen(
      context,
      mode: PasscodeMode.verify,
      title: 'Enter Passcode',
    );
    if (!mounted) return;
    if (ok == true) {
      setState(() { _loading = true; _error = null; });
      await context.read<AuthProvider>().refresh();
      if (!mounted) return;
      if (context.read<AuthProvider>().isLoggedIn) {
        widget.onSuccess();
      } else {
        setState(() { _loading = false; _error = 'Session expired. Please sign in with your password.'; });
      }
    }
  }

  Future<void> _submit() async {
    final id = _identifier.text.trim();
    final pw = _password.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().login(id, pw);
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      widget.onSuccess();
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Sign in to your account', style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          AppInputField(
            hint: 'Phone number or email',
            controller: _identifier,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            hint: 'Password',
            controller: _password,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          _loading
              ? Center(child: CircularProgressIndicator(color: c.accent))
              : PrimaryButton(label: 'Sign In', onTap: _submit),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAuthButton(
                  icon: _biometricType == BiometricType.face
                      ? Icons.face_unlock_outlined
                      : Icons.fingerprint,
                  label: _biometricType == BiometricType.face ? 'Face ID' : 'Fingerprint',
                  enabled: _biometricAvailable,
                  onTap: _triggerBiometric,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAuthButton(
                  icon: Icons.pin_outlined,
                  label: 'Passcode',
                  enabled: true,
                  onTap: _triggerPasscode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Register ──

class _RegisterForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _RegisterForm({required this.onSuccess});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    final fn = _firstName.text.trim();
    final ln = _lastName.text.trim();
    final ph = _phone.text.trim();
    final pw = _password.text;
    final cf = _confirm.text;

    if (fn.isEmpty || ln.isEmpty || ph.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Please fill in all required fields');
      return;
    }
    if (pw != cf) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (pw.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().signup(
      firstName: fn,
      lastName: ln,
      phone: ph,
      password: pw,
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      widget.onSuccess();
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create account', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Start managing your finances', style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Row(children: [
            Expanded(child: AppInputField(hint: 'First name', controller: _firstName, icon: Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: AppInputField(hint: 'Last name', controller: _lastName, icon: Icons.person_outline)),
          ]),
          const SizedBox(height: 12),
          AppInputField(hint: 'Phone number', controller: _phone, icon: Icons.phone_outlined),
          const SizedBox(height: 12),
          AppInputField(hint: 'Email (optional)', controller: _email, icon: Icons.email_outlined),
          const SizedBox(height: 12),
          _PasswordField(
            hint: 'Password',
            controller: _password,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            hint: 'Confirm password',
            controller: _confirm,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          _loading
              ? Center(child: CircularProgressIndicator(color: c.accent))
              : PrimaryButton(label: 'Create Account', onTap: _submit),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared widgets ──

class _PasswordField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderDefault),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary),
          prefixIcon: Icon(Icons.lock_outline, size: 18, color: c.textSecondary),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18,
              color: c.textSecondary,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.destructive, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.destructive, fontSize: 13))),
      ]),
    );
  }
}

class _QuickAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickAuthButton({required this.icon, required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: enabled ? c.accent.withValues(alpha: 0.35) : c.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? c.accent : c.textSecondary, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: enabled ? c.textPrimary : c.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

