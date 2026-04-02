import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

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

class DeliveryConfirmedAnimation extends StatefulWidget {
  final String orderRef;
  final VoidCallback onComplete;

  const DeliveryConfirmedAnimation({
    super.key,
    required this.orderRef,
    required this.onComplete,
  });

  @override
  State<DeliveryConfirmedAnimation> createState() =>
      _DeliveryConfirmedAnimationState();
}

class _DeliveryConfirmedAnimationState extends State<DeliveryConfirmedAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _textController;
  late AnimationController _confettiController;
  late AnimationController _buttonController;
  late Animation<double> _checkScale;
  late Animation<double> _textOpacity;
  late Animation<double> _confettiProgress;
  late Animation<double> _buttonOpacity;

  late List<_ConfettiParticle> _particles;
  final _random = Random();
  bool _autoDismissed = false;

  static const _confettiColors = [
    Color(0xFFD42B2B),
    Color(0xFFD4A843),
    Color(0xFF16A34A),
  ];

  @override
  void initState() {
    super.initState();

    _particles = List.generate(28, (_) {
      return _ConfettiParticle(
        startX: _random.nextDouble(),
        startDelay: _random.nextDouble() * 0.3,
        horizontalDrift: (_random.nextDouble() - 0.5) * 120,
        size: 6 + _random.nextDouble() * 6,
        color: _confettiColors[_random.nextInt(_confettiColors.length)],
        rotationSpeed: 1 + _random.nextDouble() * 3,
      );
    });

    // Checkmark spring animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.elasticOut,
      ),
    );

    // Text fade animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Confetti fall animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.linear),
    );

    // Button appear animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() async {
    // Start checkmark + confetti simultaneously
    _checkController.forward();
    _confettiController.forward();

    // Text fades in after checkmark settles
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Button appears after 1 second
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _buttonController.forward();

    // Auto-dismiss after 3 seconds total
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || _autoDismissed) return;
    _autoDismissed = true;
    widget.onComplete();
  }

  void _onBackTap() {
    if (_autoDismissed) return;
    _autoDismissed = true;
    widget.onComplete();
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.95),
      child: Stack(
        children: [
          // Confetti particles
          AnimatedBuilder(
            animation: _confettiProgress,
            builder: (context, _) {
              return Stack(
                children: _particles.map((p) {
                  final progress = _confettiProgress.value;
                  final particleProgress =
                      ((progress - p.startDelay) / (1.0 - p.startDelay))
                          .clamp(0.0, 1.0);

                  if (particleProgress <= 0) return const SizedBox.shrink();

                  final x = p.startX * size.width +
                      sin(particleProgress * p.rotationSpeed * pi) *
                          p.horizontalDrift;
                  final y = -20 + particleProgress * (size.height + 40);
                  final opacity =
                      particleProgress < 0.7 ? 1.0 : (1.0 - particleProgress) / 0.3;

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
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green checkmark with spring scale
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.checkCircle2,
                      size: 80,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // "Delivered!" text
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'Delivered!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    'Order ${widget.orderRef} delivered successfully',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Back to Deliveries button
                FadeTransition(
                  opacity: _buttonOpacity,
                  child: OutlinedButton.icon(
                    onPressed: _onBackTap,
                    icon: const Icon(LucideIcons.arrowLeft, size: 18),
                    label: const Text(
                      'Back to Deliveries',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
