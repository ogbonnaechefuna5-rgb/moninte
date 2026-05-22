import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/ingest_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/linked_accounts_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/preferences_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/passcode_screen.dart';
import 'services/biometric_service.dart';
import 'theme/app_theme.dart';

// ── Route names ───────────────────────────────────────────────────────────────

class Routes {
  static const splash        = '/splash';
  static const loading       = '/loading';
  static const auth          = '/auth';
  static const onboarding    = '/onboarding';
  static const home          = '/home';
  static const analytics     = '/analytics';
  static const budget        = '/budget';
  static const savings       = '/savings';
  static const ai            = '/ai';
  static const ingest        = '/ingest';
  static const transactions  = '/transactions';
  static const profile       = '/profile';
  static const linkedAccounts = '/linked-accounts';
  static const permissions   = '/permissions';
  static const preferences   = '/preferences';
}

// ── Router factory ────────────────────────────────────────────────────────────

GoRouter buildRouter(AuthProvider auth, bool showSplash) {
  return GoRouter(
    initialLocation: showSplash ? Routes.splash : Routes.loading,
    refreshListenable: auth,
    redirect: (context, state) {
      final loading = auth.loading;
      final loggedIn = auth.isLoggedIn;
      final expired = auth.sessionExpired;
      final loc = state.matchedLocation;

      // While init is in flight, hold on the loading route.
      if (loading) return loc == Routes.loading ? null : Routes.loading;

      // Init done — leave loading.
      if (loc == Routes.loading) return loggedIn ? Routes.home : Routes.auth;

      // Session expired mid-use → send to auth with a query param.
      if (expired && loc != Routes.auth) return '${Routes.auth}?expired=1';

      // Not logged in → auth screen (unless already there or on onboarding splash).
      if (!loggedIn && loc != Routes.auth && loc != Routes.splash) {
        return Routes.auth;
      }

      // Logged in but trying to visit auth → home.
      if (loggedIn && loc == Routes.auth) return Routes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => _SplashBridge(),
      ),
      GoRoute(
        path: Routes.loading,
        builder: (_, __) => const _LoadingScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (context, state) {
          final expired = state.uri.queryParameters['expired'] == '1';
          return AuthScreen(
            sessionExpiredMessage: expired ? 'Your session has expired. Please log in again.' : null,
            onComplete: ({bool isNewUser = false}) {
              if (isNewUser) {
                context.go(Routes.onboarding);
              } else {
                context.go(Routes.home);
              }
            },
          );
        },
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, _) => OnboardingScreen(
          onComplete: () => context.go(Routes.home),
        ),
      ),
      // Shell route: wraps all main tabs with the bottom nav + offline banner + lock screen.
      ShellRoute(
        builder: (context, state, child) => _AppShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: Routes.home,       builder: (_, __) => const DashboardScreen()),
          GoRoute(path: Routes.analytics,  builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: Routes.budget,     builder: (_, __) => const BudgetScreen()),
          GoRoute(path: Routes.savings,    builder: (_, __) => const SavingsScreen()),
          GoRoute(path: Routes.ai,         builder: (_, __) => const AIAssistantScreen()),
          GoRoute(path: Routes.ingest,     builder: (context, _) => IngestScreen(
            onPickerActive: (active) => _AppShell.suppressLockOf(context, active),
          )),
          GoRoute(path: Routes.transactions, builder: (_, __) => const TransactionsScreen()),
          GoRoute(path: Routes.profile,    builder: (_, __) => const ProfileScreen()),
          GoRoute(path: Routes.linkedAccounts, builder: (_, __) => const LinkedAccountsScreen()),
          GoRoute(path: Routes.permissions,   builder: (_, __) => const PermissionsScreen()),
          GoRoute(path: Routes.preferences,   builder: (_, __) => const PreferencesScreen()),
        ],
      ),
    ],
  );
}

// ── Splash bridge ─────────────────────────────────────────────────────────────
// Renders the onboarding splash then lets the redirect logic take over.

class _SplashBridge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(onComplete: () => context.go(Routes.auth));
  }
}

// ── Loading screen ────────────────────────────────────────────────────────────
// Shown on every non-first launch while AuthProvider.init() is in flight.

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Center(child: CircularProgressIndicator(color: c.accent)),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────
// Owns the bottom nav, offline banner, lock screen, and lifecycle observer.
// Replaces the old AppShell StatefulWidget.

class _AppShell extends StatefulWidget {
  final String location;
  final Widget child;
  const _AppShell({required this.location, required this.child});

  /// Lets child screens suppress the lock (e.g. while a file picker is open).
  static void suppressLockOf(BuildContext context, bool suppress) {
    context.findAncestorStateOfType<_AppShellState>()?._suppressLock = suppress;
  }

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  bool _locked = false;
  bool _suppressLock = false;

  static const _subRoutes = {
    Routes.transactions,
    Routes.profile,
    Routes.linkedAccounts,
    Routes.permissions,
    Routes.preferences,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_suppressLock) return;
      final auth = context.read<AuthProvider>();
      final prefs = context.read<PreferencesProvider>();
      if (auth.isLoggedIn && (prefs.biometricEnabled || prefs.passcodeEnabled)) {
        setState(() => _locked = true);
      }
    } else if (state == AppLifecycleState.resumed && _locked) {
      _promptUnlock();
    }
  }

  Future<void> _promptUnlock() async {
    final prefs = context.read<PreferencesProvider>();
    if (prefs.biometricEnabled) {
      final ok = await BiometricService.authenticate(reason: 'Verify your identity to continue');
      if (!mounted) return;
      if (ok) setState(() => _locked = false);
    } else if (prefs.passcodeEnabled) {
      final ok = await showPasscodeScreen(context, mode: PasscodeMode.verify);
      if (!mounted) return;
      if (ok == true) setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_locked) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: c.textSecondary),
              const SizedBox(height: 16),
              Text('App locked', style: TextStyle(color: c.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _promptUnlock,
                child: Text('Unlock', style: TextStyle(color: c.accent)),
              ),
            ],
          ),
        ),
      );
    }

    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final isSubRoute = _subRoutes.contains(widget.location);

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          widget.child,
          if (!isOnline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _OfflineBanner(),
            ),
          // Floating profile icon — visible on the four main tabs only.
          if (!isSubRoute && widget.location != Routes.profile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => context.go(Routes.profile),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceDark.withValues(alpha: 0.5),
                    border: Border.all(color: c.borderDefault),
                  ),
                  child: Icon(Icons.person_outline, size: 20, color: c.textSecondary),
                ),
              ),
            ),
          if (!isSubRoute)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: BottomNav(location: widget.location),
            ),
        ],
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFF3B30),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'No internet connection',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
