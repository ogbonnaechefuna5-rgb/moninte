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
  final void Function({bool isNewUser}) onComplete;
  final String? sessionExpiredMessage;
  const AuthScreen({super.key, required this.onComplete, this.sessionExpiredMessage});

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
                  _LoginForm(onSuccess: widget.onComplete, initialError: widget.sessionExpiredMessage),
                  _RegisterFlow(onSuccess: widget.onComplete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login ──────────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final void Function({bool isNewUser}) onSuccess;
  final String? initialError;
  const _LoginForm({required this.onSuccess, this.initialError});

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
  bool _passcodeEnabled = false;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) _error = widget.initialError;
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('pref_biometricEnabled') ?? false;
    final passcodeEnabled = prefs.getBool('pref_passcodeEnabled') ?? false;
    final hasSession = prefs.getString('refresh_token') != null;
    if (!mounted) return;
    if (!hasSession) return; // no session — buttons serve no purpose
    bool biometricAvailable = false;
    BiometricType? biometricType;
    if (biometricEnabled) {
      biometricAvailable = await BiometricService.isAvailable();
      if (biometricAvailable) {
        final types = await BiometricService.availableTypes();
        biometricType = types.contains(BiometricType.face)
            ? BiometricType.face
            : BiometricType.fingerprint;
      }
    }
    if (!mounted) return;
    setState(() {
      _biometricAvailable = biometricAvailable;
      _biometricType = biometricType;
      _passcodeEnabled = passcodeEnabled;
      _hasSession = hasSession;
    });
    if (biometricAvailable) _triggerBiometric();
  }

  Future<void> _triggerBiometric() async {
    setState(() { _loading = true; _error = null; });
    final ok = await BiometricService.authenticate(reason: 'Sign in to Moninte');
    if (!mounted) return;
    if (ok) {
      final refreshed = await context.read<AuthProvider>().refreshFromStorage();
      if (!mounted) return;
      if (refreshed) {
        widget.onSuccess(isNewUser: false);
      } else {
        setState(() { _loading = false; _error = 'Session expired. Please sign in with your password.'; });
      }
    } else {
      setState(() { _loading = false; _error = 'Biometric authentication failed'; });
    }
  }

  Future<void> _triggerPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getString('refresh_token') != null;
    if (!hasSession) {
      setState(() => _error = 'No saved session. Please sign in with your password.');
      return;
    }
    if (!mounted) return;
    final ok = await showPasscodeScreen(context, mode: PasscodeMode.verify, title: 'Enter Passcode');
    if (!mounted) return;
    if (ok == true) {
      setState(() { _loading = true; _error = null; });
      final refreshed = await context.read<AuthProvider>().refreshFromStorage();
      if (!mounted) return;
      if (refreshed) {
        widget.onSuccess(isNewUser: false);
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
      widget.onSuccess(isNewUser: false);
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
          const SizedBox(height: 24),
          AppInputField(hint: 'Phone number or email', controller: _identifier, icon: Icons.person_outline),
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
          const SizedBox(height: 20),
          _loading
              ? Center(child: CircularProgressIndicator(color: c.accent))
              : PrimaryButton(label: 'Sign In', onTap: _submit),
          const SizedBox(height: 12),
          if (_biometricAvailable || _passcodeEnabled)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_biometricAvailable) ...[
                  _QuickAuthButton(
                    icon: _biometricType == BiometricType.face
                        ? Icons.face_unlock_outlined
                        : Icons.fingerprint,
                    label: _biometricType == BiometricType.face ? 'Face ID' : 'Fingerprint',
                    enabled: true,
                    onTap: _triggerBiometric,
                  ),
                  if (_passcodeEnabled) const SizedBox(width: 12),
                ],
                if (_passcodeEnabled)
                  _QuickAuthButton(
                    icon: Icons.pin_outlined,
                    label: 'Passcode',
                    enabled: true,
                    onTap: _triggerPasscode,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Divider(color: c.borderDefault)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ),
            Expanded(child: Divider(color: c.borderDefault)),
          ]),
          const SizedBox(height: 16),
          _OIDCButton(
            label: 'Continue with Google',
            icon: _GoogleIcon(),
            onTap: () async {
              setState(() { _loading = true; _error = null; });
              final err = await context.read<AuthProvider>().signInWithGoogle();
              if (!mounted) return;
              if (err != null) { setState(() { _error = err; _loading = false; }); }
              else { widget.onSuccess(isNewUser: false); }
            },
          ),
          const SizedBox(height: 10),
          _OIDCButton(
            label: 'Continue with Apple',
            icon: Icon(Icons.apple, size: 20, color: c.textPrimary),
            onTap: () async {
              setState(() { _loading = true; _error = null; });
              final err = await context.read<AuthProvider>().signInWithApple();
              if (!mounted) return;
              if (err != null) { setState(() { _error = err; _loading = false; }); }
              else { widget.onSuccess(isNewUser: false); }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Register — multi-step flow ─────────────────────────────────────────────────

class _RegisterFlow extends StatefulWidget {
  final void Function({bool isNewUser}) onSuccess;
  const _RegisterFlow({required this.onSuccess});

  @override
  State<_RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<_RegisterFlow> {
  int _step = 0; // 0 = OIDC/entry, 1 = credentials, 2 = personal details

  // Shared state passed between steps
  String? _email;
  String? _phone;
  String? _password;

  void _goToCredentials() => setState(() => _step = 1);
  void _goToDetails(String? email, String? phone, String password) {
    _email = email;
    _phone = phone;
    _password = password;
    setState(() => _step = 2);
  }

  void _back() => setState(() => _step = _step - 1);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (_step) {
        0 => _StepOIDC(
            key: const ValueKey(0),
            onContinueManually: _goToCredentials,
            onSuccess: widget.onSuccess,
          ),
        1 => _StepCredentials(
            key: const ValueKey(1),
            onBack: _back,
            onNext: _goToDetails,
          ),
        _ => _StepPersonalDetails(
            key: const ValueKey(2),
            email: _email,
            phone: _phone,
            password: _password!,
            onBack: _back,
            onSuccess: widget.onSuccess,
          ),
      },
    );
  }
}

// ── Step 0: OIDC + entry choice ────────────────────────────────────────────────

class _StepOIDC extends StatefulWidget {
  final VoidCallback onContinueManually;
  final void Function({bool isNewUser}) onSuccess;
  const _StepOIDC({super.key, required this.onContinueManually, required this.onSuccess});

  @override
  State<_StepOIDC> createState() => _StepOIDCState();
}

class _StepOIDCState extends State<_StepOIDC> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogle() async {
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      widget.onSuccess(isNewUser: true);
    }
  }

  Future<void> _handleApple() async {
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().signInWithApple();
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      widget.onSuccess(isNewUser: true);
    }
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
          const SizedBox(height: 20),
          if (_loading)
            Center(child: CircularProgressIndicator(color: c.accent))
          else ...[
            _OIDCButton(
              label: 'Continue with Google',
              icon: _GoogleIcon(),
              onTap: _handleGoogle,
            ),
            const SizedBox(height: 10),
            _OIDCButton(
              label: 'Continue with Apple',
              icon: Icon(Icons.apple, size: 20, color: c.textPrimary),
              onTap: _handleApple,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Divider(color: c.borderDefault)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ),
            Expanded(child: Divider(color: c.borderDefault)),
          ]),
          const SizedBox(height: 16),
          _OutlineButton(
            label: 'Continue with email or phone',
            icon: Icons.email_outlined,
            onTap: widget.onContinueManually,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Step 1: Email/phone + password ─────────────────────────────────────────────

class _StepCredentials extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(String? email, String? phone, String password) onNext;
  const _StepCredentials({super.key, required this.onBack, required this.onNext});

  @override
  State<_StepCredentials> createState() => _StepCredentialsState();
}

class _StepCredentialsState extends State<_StepCredentials> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  void _next() {
    final email = _email.text.trim().isEmpty ? null : _email.text.trim();
    final pw = _password.text;
    final cf = _confirm.text;
    if (pw.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }
    if (pw.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (pw != cf) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    widget.onNext(email, null, pw);
  }

  @override
  void dispose() {
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
          _BackHeader(onBack: widget.onBack, title: 'Your credentials'),
          const SizedBox(height: 4),
          Text('Step 1 of 2', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
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
          PrimaryButton(label: 'Next', onTap: _next),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Step 2: Personal details ───────────────────────────────────────────────────

class _StepPersonalDetails extends StatefulWidget {
  final String? email;
  final String? phone;
  final String password;
  final VoidCallback onBack;
  final void Function({bool isNewUser}) onSuccess;

  const _StepPersonalDetails({
    super.key,
    required this.email,
    required this.phone,
    required this.password,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<_StepPersonalDetails> createState() => _StepPersonalDetailsState();
}

class _StepPersonalDetailsState extends State<_StepPersonalDetails> {
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  // Phone field shown only if not already provided in step 1
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final fn = _firstName.text.trim();
    final ln = _lastName.text.trim();
    final phone = _phone.text.trim();

    if (fn.isEmpty || ln.isEmpty) {
      setState(() => _error = 'First and last name are required');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Phone number is required');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().signup(
      firstName: fn,
      middleName: _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
      lastName: ln,
      phone: phone,
      password: widget.password,
      email: widget.email,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
      return;
    }
    final loginErr = await context.read<AuthProvider>().login(
      phone.isNotEmpty ? phone : widget.email!,
      widget.password,
    );
    if (!mounted) return;
    if (loginErr != null) {
      setState(() { _error = loginErr; _loading = false; });
    } else {
      widget.onSuccess(isNewUser: true);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _phone.dispose();
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
          _BackHeader(onBack: widget.onBack, title: 'Personal details'),
          const SizedBox(height: 4),
          Text('Step 2 of 2', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: AppInputField(hint: 'First name', controller: _firstName, icon: Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: AppInputField(hint: 'Last name', controller: _lastName, icon: Icons.person_outline)),
          ]),
          const SizedBox(height: 12),
          AppInputField(hint: 'Middle name (optional)', controller: _middleName, icon: Icons.person_outline),
          const SizedBox(height: 12),
          AppInputField(hint: 'Phone number', controller: _phone, icon: Icons.phone_outlined),
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

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  const _BackHeader({required this.onBack, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.of(context).textSecondary),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.displayMedium),
      ],
    );
  }
}

class _OIDCButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _OIDCButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderDefault),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: c.accent, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Simplified G logo using arcs
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.5, 3.3, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.8, 1.6, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.1, 0.7, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.5, 0.8, true, paint);
    // White center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);
    // Blue right bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.2, r, r * 0.4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: enabled ? c.accent.withValues(alpha: 0.35) : c.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? c.accent : c.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: enabled ? c.textPrimary : c.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
