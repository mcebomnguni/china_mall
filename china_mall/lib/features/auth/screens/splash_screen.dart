import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
 
import '../../../core/theme/app_theme.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Auto-navigate after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    // Navigate based on authentication state
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                // ── Centered wordmark ─────────────────────────────────────
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // "China" — heavy bold, green (primary brand colour)
                            Text(
                              'China',
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: AppColors.green700,
                                letterSpacing: -2,
                                height: 1.0,
                                fontFamily:
                                    theme.textTheme.displayLarge?.fontFamily,
                              ),
                            ),
 
                            // "Stall" — lighter weight, dark, aligned right
                            // like "bank" sits bottom-right under "GOtyme"
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Stall',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF2B2D42),
                                  letterSpacing: -1,
                                  height: 1.0,
                                  fontFamily:
                                      theme.textTheme.displayLarge?.fontFamily,
                                ),
                              ),
                            ),
 
                            const SizedBox(height: 14),
 
                            // Thin divider — same as GoTyme's line under the name
                            Container(
                              height: 1.2,
                              color:
                                  const Color(0xFF2B2D42).withValues(alpha: 0.15),
                            ),
 
                            const SizedBox(height: 14),
 
                            // "Market Place" — like "Formerly TymeBank"
                            // mixed weight: regular + bold green
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Market ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF2B2D42)
                                        .withValues(alpha: 0.70),
                                    fontFamily:
                                        theme.textTheme.titleMedium?.fontFamily,
                                  ),
                                ),
                                Text(
                                  'Place',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green700,
                                    fontFamily:
                                        theme.textTheme.titleMedium?.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
 
                // ── Bottom tagline ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Text(
                      'Secured shopping, couriers and payments',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            const Color(0xFF2B2D42).withValues(alpha: 0.40),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}