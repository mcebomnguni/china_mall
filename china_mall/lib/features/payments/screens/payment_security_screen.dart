import 'package:flutter/material.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import 'yoco_checkout_screen.dart';

/// Full payment flow screen.
/// Shows user their order total, then asks for fingerprint OR PIN.
/// On success, opens Yoco WebView.
class PaymentSecurityScreen extends StatefulWidget {
  final int orderId;
  final int amountCents;
  final String orderSummary;

  const PaymentSecurityScreen({
    super.key,
    required this.orderId,
    required this.amountCents,
    required this.orderSummary,
  });

  @override
  State<PaymentSecurityScreen> createState() => _PaymentSecurityScreenState();
}

class _PaymentSecurityScreenState extends State<PaymentSecurityScreen> {
  bool _biometricAvailable = false;
  bool _loading = false;
  bool _showPinEntry = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final token = await AuthService.getBiometricToken();
    setState(() => _biometricAvailable = available && token != null);
  }

  String get _amountDisplay =>
      'R${(widget.amountCents / 100).toStringAsFixed(2)}';

  Future<void> _proceedWithBiometric() async {
    setState(() => _loading = true);
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'Confirm payment of $_amountDisplay',
      );
      if (!authenticated) {
        _showError('Biometric verification failed.');
        return;
      }
      await _initiateCheckout(biometricVerified: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _proceedWithPIN(String pin) async {
    setState(() => _loading = true);
    try {
      final res = await PaymentService.verifyPaymentPIN(pin);
      if (res['statusCode'] == 200) {
        final pinToken = res['pin_token'];
        await _initiateCheckout(biometricVerified: false, pinToken: pinToken);
      } else if (res['statusCode'] == 423) {
        _showError('PIN locked. Try again in 30 minutes.');
      } else {
        _showError(res['error'] ?? 'Incorrect PIN.');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _initiateCheckout({
    required bool biometricVerified,
    String? pinToken,
  }) async {
    final res = await PaymentService.initiatePayment(
      orderId: widget.orderId,
      amountCents: widget.amountCents,
      biometricVerified: biometricVerified,
      pinToken: pinToken,
    );

    if (res['statusCode'] == 200 && res['redirect_url'] != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YocoCheckoutScreen(
              redirectUrl: res['redirect_url'],
              transactionId: res['transaction_id'],
              orderId: widget.orderId,
            ),
          ),
        );
      }
    } else {
      _showError(res['error'] ?? 'Failed to initiate payment.');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order summary ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.orderSummary,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(_amountDisplay,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Verify your identity to pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose how to confirm this payment:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_showPinEntry)
              _PINEntryWidget(onSubmit: _proceedWithPIN,
                  onCancel: () => setState(() => _showPinEntry = false))
            else
              Column(
                children: [
                  // Biometric option
                  if (_biometricAvailable)
                    _PaymentOptionCard(
                      icon: Icons.fingerprint,
                      title: 'Pay with Fingerprint',
                      subtitle: 'Quick and secure biometric confirmation',
                      color: AppColors.primary,
                      onTap: _proceedWithBiometric,
                    ),
                  if (_biometricAvailable) const SizedBox(height: 12),

                  // PIN option
                  _PaymentOptionCard(
                    icon: Icons.pin,
                    title: 'Pay with PIN',
                    subtitle: 'Enter your 4-digit payment PIN',
                    color: AppColors.green700,
                    onTap: () => setState(() => _showPinEntry = true),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── PIN Entry Widget ──────────────────────────────────────────────────────────

class _PINEntryWidget extends StatefulWidget {
  final Function(String pin) onSubmit;
  final VoidCallback onCancel;

  const _PINEntryWidget({required this.onSubmit, required this.onCancel});

  @override
  State<_PINEntryWidget> createState() => _PINEntryWidgetState();
}

class _PINEntryWidgetState extends State<_PINEntryWidget> {
  String _pin = '';

  void _onKey(String key) {
    if (_pin.length < 4) {
      setState(() => _pin += key);
      if (_pin.length == 4) {
        widget.onSubmit(_pin);
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Enter Payment PIN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          )),
        ),
        const SizedBox(height: 24),

        // Numpad
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [
            ...['1','2','3','4','5','6','7','8','9'].map((k) =>
              _NumKey(label: k, onTap: () => _onKey(k))),
            const SizedBox.shrink(),
            _NumKey(label: '0', onTap: () => _onKey('0')),
            IconButton(
                icon: const Icon(Icons.backspace_outlined),
                onPressed: _onDelete),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: widget.onCancel,
            child: const Text('Use different method')),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
