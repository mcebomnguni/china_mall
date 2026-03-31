import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Phase 1: App name fade in + scale (0.00 → 0.30)
  late final Animation<double> _nameOpacity;
  late final Animation<double> _nameScale;

  // Phase 2: Shopping bags appear (0.25 → 0.55)
  late final Animation<double> _bagsOpacity;
  late final Animation<double> _bagsSlide;

  // Phase 3: Subtitle (0.40 → 0.55)
  late final Animation<double> _subtitleOpacity;

  // Phase 4: Hold (0.55 → 0.70) then swipe up (0.70 → 1.00)
  late final Animation<double> _swipeUp;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // ── Phase 1: Name ────────────────────────────────────────
    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.18, curve: Curves.easeOut)),
    );
    _nameScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.22, curve: Curves.elasticOut)),
    );

    // ── Phase 2: Shopping bags ───────────────────────────────
    _bagsOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.22, 0.38, curve: Curves.easeOut)),
    );
    _bagsSlide = Tween(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.22, 0.42, curve: Curves.easeOutCubic)),
    );

    // ── Phase 3: Subtitle ────────────────────────────────────
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.38, 0.50, curve: Curves.easeOut)),
    );

    // ── Phase 4: Swipe up (everything slides up and off screen)
    _swipeUp = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.72, 1.0, curve: Curves.easeInCubic)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final screenH = MediaQuery.of(context).size.height;
        // Swipe up offset: 0 → full screen height
        final swipeOffset = _swipeUp.value * -screenH;

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Transform.translate(
            offset: Offset(0, swipeOffset),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    const Color(0xFF0D4A2E),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ── App name ──────────────────────────────
                    Opacity(
                      opacity: _nameOpacity.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _nameScale.value,
                        child: const Column(
                          children: [
                            Text(
                              'China Stall',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'MARKET PLACE',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white54,
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Shopping bags ─────────────────────────
                    Opacity(
                      opacity: _bagsOpacity.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _bagsSlide.value),
                        child: _buildShoppingBags(),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Subtitle ──────────────────────────────
                    Opacity(
                      opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                      child: const Text(
                        'Everything you need, one place',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // ── Loading dots ──────────────────────────
                    Opacity(
                      opacity: (1.0 - _swipeUp.value).clamp(0.0, 1.0),
                      child: _buildLoadingDots(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShoppingBags() {
    final t = _ctrl.value;
    const bags = ['🛍️', '👜', '🛒', '🎒', '👝'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(bags.length, (i) {
        // Stagger each bag's appearance
        final bagDelay = 0.25 + i * 0.04;
        final bagProgress = ((t - bagDelay) / 0.15).clamp(0.0, 1.0);
        // Gentle float
        final float = sin(t * pi * 3 + i * 1.2) * 6.0;

        return Opacity(
          opacity: bagProgress,
          child: Transform.translate(
            offset: Offset(0, float),
            child: Transform.scale(
              scale: 0.5 + bagProgress * 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  bags[i],
                  style: TextStyle(fontSize: 32 + (i % 2) * 10.0),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingDots() {
    final t = _ctrl.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final dot = (sin(t * pi * 6 + i * 1.0) * 0.5 + 0.5);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.3 + dot * 0.5),
          ),
        );
      }),
    );
  }
}
