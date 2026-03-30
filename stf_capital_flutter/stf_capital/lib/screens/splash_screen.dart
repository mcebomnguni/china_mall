// ─────────────────────────────────────────────────────────────────────────────
//  screens/splash_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
 
  // ── Logo circle ───────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoFade;
  late final Animation<double>   _logoScale;
 
  // ── Per-letter controllers for "STF Capital" ──────────────────────────────
  final String _titleText = 'STF Capital';
  late final List<AnimationController> _letterCtrls;
  late final List<Animation<double>>   _letterFades;
  late final List<Animation<double>>   _letterSlides;
 
  // ── Subtitle + progress bar ───────────────────────────────────────────────
  late final AnimationController _subCtrl;
  late final Animation<double>   _subFade;
  late final Animation<double>   _progressAnim;
 
  @override
  void initState() {
    super.initState();
 
    // 1. Logo animates in first (0–600 ms)
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
 
    // 2. Letters stagger in after logo (each 80 ms apart, starting at 500 ms)
    _letterCtrls = List.generate(_titleText.length, (i) {
      return AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350),
      );
    });
    _letterFades = _letterCtrls.map((c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOut)
    ).toList();
    _letterSlides = _letterCtrls.map((c) =>
      Tween<double>(begin: 18, end: 0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
      )
    ).toList();
 
    // 3. Subtitle + progress bar fade in after all letters done
    _subCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _subFade = CurvedAnimation(parent: _subCtrl, curve: Curves.easeOut);
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subCtrl, curve: Curves.easeInOut),
    );
 
    _runSequence();
  }
 
  Future<void> _runSequence() async {
    // Logo fades in
    await _logoCtrl.forward();
 
    // Letters stagger
    for (int i = 0; i < _titleText.length; i++) {
      // Skip space — no animation needed
      if (_titleText[i] == ' ') continue;
      _letterCtrls[i].forward();
      await Future.delayed(const Duration(milliseconds: 75));
    }
 
    // Wait for last letter to finish
    await Future.delayed(const Duration(milliseconds: 350));
 
    // Subtitle + progress bar
    _subCtrl.forward();
  }
 
  @override
  void dispose() {
    _logoCtrl.dispose();
    for (final c in _letterCtrls) { c.dispose(); }
    _subCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Always dark — matches Android/iOS native splash colour
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
 
            // ── Gold logo circle ────────────────────────────────────────────
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.35),
                        blurRadius: 35,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'STF',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: AppTheme.darkBg, letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
 
            const SizedBox(height: 24),
 
            // ── "STF Capital" letter-by-letter reveal ───────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_titleText.length, (i) {
                final char = _titleText[i];
 
                // Space: just a gap, no animation
                if (char == ' ') return const SizedBox(width: 9);
 
                return AnimatedBuilder(
                  animation: _letterCtrls[i],
                  builder: (context, _) {
                    return Opacity(
                      opacity: _letterFades[i].value,
                      child: Transform.translate(
                        offset: Offset(0, _letterSlides[i].value),
                        child: ShaderMask(
                          shaderCallback: (r) =>
                            AppTheme.goldGradient.createShader(r),
                          child: Text(
                            char,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white, // masked by ShaderMask
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
 
            const SizedBox(height: 8),
 
            // ── "Financial Services" subtitle ───────────────────────────────
            FadeTransition(
              opacity: _subFade,
              child: Text(
                'Financial Services',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppTheme.textOnDarkMuted,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
 
            const SizedBox(height: 48),
 
            // ── Animated progress bar ───────────────────────────────────────
            FadeTransition(
              opacity: _subFade,
              child: SizedBox(
                width: 120,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: null, // indeterminate — matches your original
                        backgroundColor: AppTheme.darkSurface2,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.goldBright,
                        ),
                        minHeight: 2,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}