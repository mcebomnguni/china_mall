import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

enum _PinState { entering, confirming }

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  static const int _minPinLength = 4;
  static const int _maxPinLength = 6;

  _PinState _pinState = _PinState.entering;
  String _enteredPin = '';
  String _firstPin = '';
  String? _errorText;
  bool _loading = false;
  bool _success = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(int digit) {
    if (_loading || _success) return;
    if (_enteredPin.length >= _maxPinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit.toString();
      _errorText = null;
    });
  }

  void _onDeletePressed() {
    if (_loading || _success) return;
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _onConfirmPressed() async {
    if (_loading || _success) return;
    if (_enteredPin.length < _minPinLength) {
      _triggerError('Enter at least $_minPinLength digits');
      return;
    }

    if (_pinState == _PinState.entering) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _pinState = _PinState.confirming;
        _errorText = null;
      });
      return;
    }

    if (_enteredPin != _firstPin) {
      _triggerError('PINs do not match. Try again.');
      setState(() {
        _enteredPin = '';
        _pinState = _PinState.entering;
        _firstPin = '';
      });
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.setLoginPin(_enteredPin);
    if (!mounted) return;

    if (ok) {
      HapticFeedback.heavyImpact();
      setState(() { _loading = false; _success = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/');
    } else {
      setState(() => _loading = false);
      _triggerError(auth.error ?? 'Failed to set PIN');
      setState(() { _enteredPin = ''; _pinState = _PinState.entering; _firstPin = ''; });
    }
  }

  void _triggerError(String message) {
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);
    setState(() => _errorText = message);
  }

  Future<void> _useBiometrics() async {
    if (_loading || _success) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.setSecurityMethod('biometric');
    if (!mounted) return;
    if (ok) {
      HapticFeedback.heavyImpact();
      setState(() { _loading = false; _success = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/');
    } else {
      setState(() => _loading = false);
      _triggerError('Could not enable biometrics. Try setting a PIN instead.');
    }
  }

  void _skip() {
    if (_loading || _success) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top: icon + title + PIN dots ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: ValueKey(_success),
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _success ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.lock_shield_fill,
                          size: 28, color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _success ? "You're all set!" : 'Secure Your Account',
                      style: const TextStyle(fontFamily: 'Satoshi', fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _success ? 'Your account is now protected'
                          : _pinState == _PinState.entering
                              ? 'Set a PIN to protect your account'
                              : 'Re-enter your PIN to confirm',
                      style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: AppColors.white.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // PIN dots
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      ),
                      child: _buildPinDots(),
                    ),
                    // Error
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Bottom: number pad + actions ──
              if (!_success)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Container(width: 32, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                        // Number pad — takes remaining space
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: _buildNumberPad(),
                          ),
                        ),
                        // Confirm button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _enteredPin.length >= _minPinLength ? _onConfirmPressed : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                  : Text(
                                      _pinState == _PinState.entering ? 'CONFIRM PIN' : 'SET PIN',
                                      style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Biometrics
                        GestureDetector(
                          onTap: _useBiometrics,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fingerprint, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                const Text('Or use Biometrics', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                        // Skip
                        GestureDetector(
                          onTap: _skip,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Skip for now', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    final totalDots = (_firstPin.isNotEmpty ? _firstPin.length : _enteredPin.length).clamp(_minPinLength, _maxPinLength);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (i) {
        final filled = i < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: filled ? 16 : 12,
          height: filled ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.white : AppColors.white.withValues(alpha: 0.2),
            border: Border.all(color: filled ? AppColors.white : AppColors.white.withValues(alpha: 0.4), width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return LayoutBuilder(builder: (context, constraints) {
      final btnSize = ((constraints.maxHeight - 32) / 4).clamp(38.0, 60.0);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _numRow([1, 2, 3], btnSize),
          _numRow([4, 5, 6], btnSize),
          _numRow([7, 8, 9], btnSize),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: btnSize, height: btnSize),
              _digitBtn(0, btnSize),
              GestureDetector(
                onTap: _onDeletePressed,
                child: SizedBox(
                  width: btnSize, height: btnSize,
                  child: Center(child: Icon(CupertinoIcons.delete_left, size: btnSize * 0.32, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _numRow(List<int> digits, double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _digitBtn(d, size)).toList(),
    );
  }

  Widget _digitBtn(int digit, double size) {
    return GestureDetector(
      onTap: () => _onDigitPressed(digit),
      child: SizedBox(
        width: size, height: size,
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: size * 0.38, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
