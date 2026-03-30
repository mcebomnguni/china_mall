import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class VendorPayoutsScreen extends StatefulWidget {
  const VendorPayoutsScreen({super.key});
 
  @override
  State<VendorPayoutsScreen> createState() => _VendorPayoutsScreenState();
}
 
class _VendorPayoutsScreenState extends State<VendorPayoutsScreen> {
  List _payouts = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getPayouts();
    if (!mounted) return;
    setState(() {
      _payouts = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  double get _totalEarned => _payouts.fold(
      0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/vendor');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Payouts',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payouts.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.money_dollar_circle,
                  title: 'No payouts yet',
                  subtitle:
                      'Payouts are processed 14 days after delivery.',
                )
              : Column(
                  children: [
                    // Summary
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Earned',
                                    style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        color: Colors.white70,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  'R ${_totalEarned.toStringAsFixed(2)}',
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
                          const Text('💰',
                              style: TextStyle(fontSize: 40)),
                        ],
                      ),
                    ),
 
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _payouts.length,
                        itemBuilder: (_, i) {
                          final p = _payouts[i];
                          final amount =
                              (p['amount'] ?? 0).toDouble();
                          final status = p['status'] ?? 'pending';
 
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.money_dollar_circle_fill,
                                    color: AppColors.accent,
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
                                            'Order #${p['order']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      if (p['payout_date'] != null)
                                        Text(
                                          'Payout: ${p['payout_date']}',
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
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 11,
                                        color: status == 'paid'
                                            ? AppColors.success
                                            : AppColors.warning,
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