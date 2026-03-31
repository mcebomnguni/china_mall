import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DeliveryConfirmedAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const DeliveryConfirmedAnimation({super.key, this.onComplete});

  @override
  State<DeliveryConfirmedAnimation> createState() =>
      _DeliveryConfirmedAnimationState();
}

class _DeliveryConfirmedAnimationState
    extends State<DeliveryConfirmedAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _scaleController.forward().then((_) {
      _fadeController.forward().then((_) {
        Future.delayed(const Duration(seconds: 1), () {
          widget.onComplete?.call();
        });
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Delivered!',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
