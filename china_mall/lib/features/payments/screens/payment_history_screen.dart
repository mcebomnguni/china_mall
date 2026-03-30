import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
 
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}
 
class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List _payments = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getPaymentHistory();
    if (!mounted) return;
    setState(() {
      _payments = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  double get _totalSpent => _payments.fold(
      0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
 
  Color _statusColor(String status) {
    switch (status) {
      case 'succeeded':
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return AppColors.info;
      case 'processing':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }
 
  IconData _statusIcon(String status) {
    switch (status) {
      case 'succeeded':
      case 'completed':
        return CupertinoIcons.checkmark_circle_fill;
      case 'failed':
        return CupertinoIcons.xmark_circle_fill;
      case 'refunded':
        return CupertinoIcons.arrow_counterclockwise_circle_fill;
      case 'processing':
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.circle;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.creditcard,
                  title: 'No payments yet',
                  subtitle: 'Your payment history will appear here.',
                )
              : Column(
                  children: [
                    // Summary card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'R ${_totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_payments.length}',
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
 
                    // Transactions list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payments.length,
                          itemBuilder: (_, i) {
                            final p = _payments[i];
                            final amount =
                                (p['amount'] ?? p['amount_rands'] ?? 0)
                                    .toDouble();
                            final status =
                                (p['status'] ?? 'pending') as String;
                            final color = _statusColor(status);
 
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _statusIcon(status),
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['order_number'] ??
                                              'Order #${p['order'] ?? '—'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          (p['created_at'] ?? '')
                                              .toString()
                                              .substring(0, 10),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'R ${amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: color == AppColors.success
                                              ? AppColors.textPrimary
                                              : color,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}