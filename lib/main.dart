import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/bottom_nav.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/linked_accounts_screen.dart';
import 'screens/permissions_screen.dart';
import 'providers/preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = !(prefs.getBool('has_seen_splash') ?? false);
  if (isFirstLaunch) await prefs.setBool('has_seen_splash', true);
  runApp(MoninteApp(showSplash: isFirstLaunch));
}

class MoninteApp extends StatelessWidget {
  final bool showSplash;
  const MoninteApp({super.key, required this.showSplash});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          title: 'Moninte',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.mode,
          home: AppShell(showSplash: showSplash),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final bool showSplash;
  const AppShell({super.key, required this.showSplash});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late bool _showSplash = widget.showSplash;
  bool _showAuth = false;
  bool _showOnboarding = false;
  String _activeScreen = 'home';

  static const _subScreens = ['linked-accounts', 'permissions', 'preferences'];

  @override
  void initState() {
    super.initState();
    if (!widget.showSplash) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) _showAuth = true;
    }
  }

  void _completeSplash() {
    setState(() {
      _showSplash = false;
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) _showAuth = true;
    });
  }

  void _completeAuth() {
    setState(() {
      _showAuth = false;
      _showOnboarding = true;
    });
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
  }

  void _navigate(String screen) {
    setState(() => _activeScreen = screen);
  }

  void _goBack() {
    setState(() => _activeScreen = 'profile');
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _completeSplash);
    }

    if (_showAuth) {
      return AuthScreen(onComplete: _completeAuth);
    }

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    final isSubScreen = _subScreens.contains(_activeScreen);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Stack(
        children: [
          _buildScreen(),
          if (_activeScreen != 'profile' && !isSubScreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: GestureDetector(
                onTap: () => _navigate('profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.of(context).surfaceDark.withValues(alpha: 0.5),
                    border: Border.all(color: AppColors.of(context).borderDefault),
                  ),
                  child: Icon(Icons.person_outline, size: 20, color: AppColors.of(context).textSecondary),
                ),
              ),
            ),
          if (!isSubScreen)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: BottomNav(
                active: _activeScreen,
                onNavigate: _navigate,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_activeScreen) {
      case 'home':
        return const DashboardScreen();
      case 'analytics':
        return const AnalyticsScreen();
      case 'budget':
        return const BudgetScreen();
      case 'savings':
        return const SavingsScreen();
      case 'ai':
        return const AIAssistantScreen();
      case 'profile':
        return ProfileScreen(onNavigate: _navigate);
      case 'linked-accounts':
        return LinkedAccountsScreen(onBack: _goBack);
      case 'permissions':
        return PermissionsScreen(onBack: _goBack);
      case 'preferences':
        return PreferencesScreen(onBack: _goBack);
      default:
        return const DashboardScreen();
    }
  }
}
