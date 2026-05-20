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
import 'screens/ingest_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/linked_accounts_screen.dart';
import 'screens/permissions_screen.dart';
import 'providers/preferences_provider.dart';
import 'providers/connectivity_provider.dart';

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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreMenu(onNavigate: (screen) {
        Navigator.pop(context);
        _navigate(screen);
      }),
    );
  }

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

    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final isSubScreen = _subScreens.contains(_activeScreen);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Stack(
        children: [
          _buildScreen(),
          if (!isOnline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _OfflineBanner(),
            ),
          if (!isSubScreen)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: BottomNav(
                active: _activeScreen,
                onNavigate: _navigate,
                onMore: _showMoreMenu,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_activeScreen) {
      case 'home':
        return DashboardScreen(onProfileTap: () => _navigate('profile'));
      case 'analytics':
        return const AnalyticsScreen();
      case 'ingest':
        return const IngestScreen();
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

class _OfflineBanner extends StatelessWidget {  @override
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

class _MoreMenu extends StatelessWidget {
  final ValueChanged<String> onNavigate;
  const _MoreMenu({required this.onNavigate});

  static const _items = [
    _MenuItem('ai', Icons.auto_awesome_rounded, 'AI Assistant', 'Smart spending insights'),
    _MenuItem('linked-accounts', Icons.account_balance_outlined, 'Linked Accounts', 'Manage your bank connections'),
    _MenuItem('permissions', Icons.shield_outlined, 'Permissions', 'App access settings'),
    _MenuItem('preferences', Icons.tune_outlined, 'Preferences', 'Notifications, theme & more'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.borderDefault),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: c.textSecondary.withValues(alpha: 0.3))),
          const SizedBox(height: 20),
          ..._items.map((item) => GestureDetector(
            onTap: () => onNavigate(item.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: c.surfaceLight.withValues(alpha: 0.4),
                border: Border.all(color: c.borderDefault),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: c.accent.withValues(alpha: 0.1)),
                  child: Icon(item.icon, size: 20, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.label, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ])),
                Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String id, label, subtitle;
  final IconData icon;
  const _MenuItem(this.id, this.icon, this.label, this.subtitle);
}
