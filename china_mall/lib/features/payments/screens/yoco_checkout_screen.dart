import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens Yoco's hosted payment page in a WebView.
/// Detects success/cancel/failure from the redirect URL.
class YocoCheckoutScreen extends StatefulWidget {
  final String redirectUrl;
  final int transactionId;
  final int orderId;

  const YocoCheckoutScreen({
    super.key,
    required this.redirectUrl,
    required this.transactionId,
    required this.orderId,
  });

  @override
  State<YocoCheckoutScreen> createState() => _YocoCheckoutScreenState();
}

class _YocoCheckoutScreenState extends State<YocoCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            // Detect outcome from redirect URL pattern
            if (url.contains('/payment/success')) {
              _handleResult('success');
              return NavigationDecision.prevent;
            } else if (url.contains('/payment/cancel')) {
              _handleResult('cancelled');
              return NavigationDecision.prevent;
            } else if (url.contains('/payment/failure')) {
              _handleResult('failed');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _handleResult(String result) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          result: result,
          transactionId: widget.transactionId,
          orderId: widget.orderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                    'Are you sure you want to cancel this payment?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleResult('cancelled');
                    },
                    child: const Text('Yes, Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// ── Payment Result Screen ─────────────────────────────────────────────────────

class PaymentResultScreen extends StatelessWidget {
  final String result;
  final int transactionId;
  final int orderId;

  const PaymentResultScreen({
    super.key,
    required this.result,
    required this.transactionId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = result == 'success';
    final isCancelled = result == 'cancelled';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline
                  : isCancelled
                      ? Icons.cancel_outlined
                      : Icons.error_outline,
              size: 100,
              color: isSuccess
                  ? Colors.green
                  : isCancelled
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess
                  ? 'Payment Successful!'
                  : isCancelled
                      ? 'Payment Cancelled'
                      : 'Payment Failed',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess
                  ? 'Your order #$orderId has been confirmed.'
                  : isCancelled
                      ? 'Your payment was cancelled. Your cart is still saved.'
                      : 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(isSuccess ? 'View Order' : 'Back to Home',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (!isSuccess) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
