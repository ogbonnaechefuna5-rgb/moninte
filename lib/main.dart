import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/category_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/savings_provider.dart';
import 'services/api_service.dart';
import 'router.dart';

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
        Provider(create: (_) => ApiService()),
        ChangeNotifierProxyProvider<ApiService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<ApiService>())..init(),
          update: (_, api, prev) => prev ?? AuthProvider(api)..init(),
        ),
        ChangeNotifierProxyProvider<ApiService, PreferencesProvider>(
          create: (ctx) => PreferencesProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? PreferencesProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, CategoryProvider>(
          create: (ctx) => CategoryProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? CategoryProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, DashboardProvider>(
          create: (ctx) => DashboardProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? DashboardProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, AnalyticsProvider>(
          create: (ctx) => AnalyticsProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? AnalyticsProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, BudgetProvider>(
          create: (ctx) => BudgetProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? BudgetProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiService, SavingsProvider>(
          create: (ctx) => SavingsProvider(ctx.read<ApiService>()),
          update: (_, api, prev) => prev ?? SavingsProvider(api),
        ),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, auth, _) {
          final router = buildRouter(auth, showSplash);
          return MaterialApp.router(
            title: 'Moninte',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.mode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
