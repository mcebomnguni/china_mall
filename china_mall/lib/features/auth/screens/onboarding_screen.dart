import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: 'CS',
      title: 'Shop Thousands\nof Products',
      subtitle: 'Browse clothing, electronics, furniture and more from verified local stores.',
      gradient: AppColors.gradientRed,
    ),
    _OnboardPage(
      emoji: 'SV',
      title: 'Sell on\nChina Stall',
      subtitle: 'Register your store and reach thousands of buyers across South Africa.',
      gradient: LinearGradient(
        colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _OnboardPage(
      emoji: 'GO',
      title: 'Fast, Tracked\nDelivery',
      subtitle: 'Real-time order tracking from pickup to your doorstep.',
      gradient: AppColors.gradientDark,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Simple navigation - no SharedPreferences (avoids web crash)
  void _finish() {
    context.read<AuthProvider>().completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _PageView(page: _pages[i]),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Main CTA button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_page < _pages.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _page < _pages.length - 1 ? 'Next' : 'Get Started',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Skip button
                    if (_page < _pages.length - 1)
                      GestureDetector(
                        onTap: _finish,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _PageView extends StatelessWidget {
  final _OnboardPage page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: page.gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 32),
              Text(
                page.title,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 17,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
