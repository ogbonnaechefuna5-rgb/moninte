import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/bottom_nav.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/linked_accounts_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/preferences_screen.dart';

void main() {
  runApp(const MoninteApp());
}

class MoninteApp extends StatelessWidget {
  const MoninteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          title: 'Moninte',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.mode,
          home: const AppShell(),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showSplash = true;
  bool _showOnboarding = false;
  String _activeScreen = 'home';

  static const _subScreens = ['linked-accounts', 'permissions', 'preferences'];

  void _completeSplash() {
    setState(() {
      _showSplash = false;
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

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    final isSubScreen = _subScreens.contains(_activeScreen);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          _buildScreen(),

          // Profile avatar button (hidden on sub-screens and profile)
          if (_activeScreen != 'profile' && !isSubScreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => _navigate('profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark.withValues(alpha: 0.5),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: const Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                ),
              ),
            ),

          // Bottom nav (hidden on sub-screens)
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
