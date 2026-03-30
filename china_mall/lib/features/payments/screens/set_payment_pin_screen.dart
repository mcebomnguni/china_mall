import 'package:flutter/material.dart';
import '../../../core/services/payment_service.dart';

class SetPaymentPINScreen extends StatefulWidget {
  const SetPaymentPINScreen({super.key});

  @override
  State<SetPaymentPINScreen> createState() => _SetPaymentPINScreenState();
}

class _SetPaymentPINScreenState extends State<SetPaymentPINScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  bool _loading = false;

  void _onKey(String key) {
    if (!_confirming) {
      if (_pin.length < 4) {
        setState(() => _pin += key);
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _confirming = true);
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += key);
        if (_confirmPin.length == 4) {
          _submit();
        }
      }
    }
  }

  void _onDelete() {
    if (!_confirming) {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      }
    }
  }

  Future<void> _submit() async {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PINs do not match. Please try again.'),
            backgroundColor: Colors.red));
      setState(() {
        _pin = '';
        _confirmPin = '';
        _confirming = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await PaymentService.setPaymentPIN(_pin, _confirmPin);
      if (mounted) {
        if (res['statusCode'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Payment PIN set successfully!'),
                backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['error'] ?? 'Failed to set PIN.'),
                backgroundColor: Colors.red));
          setState(() {
            _pin = '';
            _confirmPin = '';
            _confirming = false;
          });
        }
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _currentPin => _confirming ? _confirmPin : _pin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Payment PIN')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.purple),
            const SizedBox(height: 16),
            Text(
              _confirming ? 'Confirm your PIN' : 'Create a 4-digit Payment PIN',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'Re-enter your PIN to confirm'
                  : 'This PIN will be required to confirm payments',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            if (_loading)
              const CircularProgressIndicator()
            else ...[
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _currentPin.length
                        ? Colors.purple
                        : Colors.grey.shade300,
                  ),
                )),
              ),
              const SizedBox(height: 32),

              // Numpad
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  ...['1','2','3','4','5','6','7','8','9'].map((k) =>
                    InkWell(
                      onTap: () => _onKey(k),
                      child: Center(
                        child: Text(k, style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500)),
                      ),
                    )),
                  const SizedBox.shrink(),
                  InkWell(
                    onTap: () => _onKey('0'),
                    child: const Center(
                      child: Text('0', style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      onPressed: _onDelete),
                ],
              ),

              if (_confirming)
                TextButton(
                  onPressed: () => setState(() {
                    _confirming = false;
                    _pin = '';
                    _confirmPin = '';
                  }),
                  child: const Text('Start over'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
