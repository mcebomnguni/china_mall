import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class CheckoutSuccessAnimation extends StatefulWidget {
  final String orderRef;
  final VoidCallback onTrackOrder;

  const CheckoutSuccessAnimation({
    super.key,
    required this.orderRef,
    required this.onTrackOrder,
  });

  @override
  State<CheckoutSuccessAnimation> createState() =>
      _CheckoutSuccessAnimationState();
}

class _CheckoutSuccessAnimationState extends State<CheckoutSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _textController;
  late AnimationController _confettiController;
  late AnimationController _buttonController;
  late Animation<double> _checkScale;
  late Animation<double> _textOpacity;
  late Animation<double> _confettiProgress;
  late Animation<double> _buttonSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _dimAnimation;

  late List<_ConfettiParticle> _particles;
  final _random = Random();

  static const _confettiColors = [
    Color(0xFFD42B2B),
    Color(0xFFD4A843),
    Color(0xFF16A34A),
  ];

  @override
  void initState() {
    super.initState();

    _particles = List.generate(30, (_) {
      return _ConfettiParticle(
        startX: _random.nextDouble(),
        startDelay: _random.nextDouble() * 0.3,
        horizontalDrift: (_random.nextDouble() - 0.5) * 140,
        size: 4 + _random.nextDouble() * 4,
        color: _confettiColors[_random.nextInt(_confettiColors.length)],
        rotationSpeed: 1 + _random.nextDouble() * 3,
      );
    });

    // Dim background
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dimAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: const Interval(0.0, 0.3)),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.linear),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buttonSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    _checkController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _buttonController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _textController.dispose();
    _confettiController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _checkController,
        _textController,
        _confettiController,
        _buttonController,
      ]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: _dimAnimation.value * 0.3),
          child: Stack(
            children: [
              // Confetti
              ...(_particles.map((p) {
                final progress = _confettiProgress.value;
                final particleProgress =
                    ((progress - p.startDelay) / (1.0 - p.startDelay))
                        .clamp(0.0, 1.0);
                if (particleProgress <= 0) return const SizedBox.shrink();

                final x = p.startX * size.width +
                    sin(particleProgress * p.rotationSpeed * pi) *
                        p.horizontalDrift;
                final y = -20 + particleProgress * (size.height * 0.7);
                final opacity = particleProgress < 0.7
                    ? 1.0
                    : (1.0 - particleProgress) / 0.3;

                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: particleProgress * p.rotationSpeed * pi * 2,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                );
              })),

              // Center content
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.checkCircle2,
                            size: 48,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: const Text(
                          'Order Placed!',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: Text(
                          'Ref: ${widget.orderRef}',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _buttonOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _buttonSlide.value),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.onTrackOrder,
                              icon: const Icon(LucideIcons.mapPin, size: 16),
                              label: const Text(
                                'Track Your Order',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double startDelay;
  final double horizontalDrift;
  final double size;
  final Color color;
  final double rotationSpeed;

  const _ConfettiParticle({
    required this.startX,
    required this.startDelay,
    required this.horizontalDrift,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}
