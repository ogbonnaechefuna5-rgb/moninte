import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _pageController = PageController();
  int _step = 0;

  static const _screens = [
    _Page('Moninte', 'Your financial brain',
        'AI-powered spending insights for Nigerian users',
        Icons.auto_awesome_rounded),
    _Page('One Place, All Accounts', 'Connect and monitor',
        'Link your GTBank, Kuda, Opay, and more to get a complete financial picture',
        Icons.trending_up_rounded),
    _Page('Your Money Stays Yours', 'Privacy first',
        "We never touch your money. Ever. We're not a bank or wallet — just your intelligent advisor.",
        Icons.shield_rounded),
  ];

  void _next() {
    if (_step < _screens.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            // Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _step < _screens.length - 1
                    ? TextButton(
                        onPressed: widget.onComplete,
                        child: Text('Skip',
                            style: TextStyle(
                                color: c.textSecondary,
                                decoration: TextDecoration.underline,
                                decorationColor: c.textSecondary)),
                      )
                    : const SizedBox(height: 40),
              ),
            ),

            // Swipeable pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _step = i),
                itemCount: _screens.length,
                itemBuilder: (_, i) {
                  final s = _screens[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Icon(s.icon, size: 80, color: AppColors.accent),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(s.subtitle,
                            style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(s.description,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: c.textSecondary,
                                  height: 1.5),
                              textAlign: TextAlign.center),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_screens.length, (i) {
                final active = i == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 32 : 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accent
                        : c.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: c.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          _step == _screens.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page {
  final String title, subtitle, description;
  final IconData icon;
  const _Page(this.title, this.subtitle, this.description, this.icon);
}
