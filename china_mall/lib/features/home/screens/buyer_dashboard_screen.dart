import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});
 
  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}
 
class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  Map? _data;
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getBuyerDashboard();
    if (!mounted) return;
    setState(() {
      _data = res.isSuccess ? res.data : null;
      _loading = false;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Dashboard',
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
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero spend card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientRed,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Spent',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'R ${((_data?['total_spent'] ?? 0) as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _MiniStat(
                                label: 'Orders',
                                value: '${_data?['total_orders'] ?? 0}',
                              ),
                              const SizedBox(width: 24),
                              _MiniStat(
                                label: 'Delivered',
                                value: '${_data?['delivered_orders'] ?? 0}',
                              ),
                              const SizedBox(width: 24),
                              _MiniStat(
                                label: 'Active',
                                value: '${_data?['active_orders'] ?? 0}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
 
                    // Quick links
                    Text('Quick Access',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _QuickLink(
                          icon: CupertinoIcons.cube_box_fill,
                          label: 'Orders',
                          color: AppColors.info,
                          onTap: () => context.go('/orders'),
                        ),
                        _QuickLink(
                          icon: CupertinoIcons.arrow_uturn_left_circle_fill,
                          label: 'Returns',
                          color: AppColors.warning,
                          onTap: () => context.go('/orders/returns'),
                        ),
                        _QuickLink(
                          icon: CupertinoIcons.exclamationmark_bubble_fill,
                          label: 'Disputes',
                          color: AppColors.error,
                          onTap: () => context.go('/orders/disputes'),
                        ),
                        _QuickLink(
                          icon: CupertinoIcons.creditcard_fill,
                          label: 'Payments',
                          color: AppColors.success,
                          onTap: () => context.go('/payments/history'),
                        ),
                        _QuickLink(
                          icon: CupertinoIcons.tag_fill,
                          label: 'Shop',
                          color: AppColors.primary,
                          onTap: () => context.go('/products'),
                        ),
                        _QuickLink(
                          icon: CupertinoIcons.house_fill,
                          label: 'Stores',
                          color: AppColors.accent,
                          onTap: () => context.go('/stores'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
 
                    // Recent orders
                    if (_data?['recent_orders'] != null &&
                        (_data!['recent_orders'] as List).isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Orders',
                              style: Theme.of(context).textTheme.headlineSmall),
                          GestureDetector(
                            onTap: () => context.go('/orders'),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(_data!['recent_orders'] as List).take(5).map(
                            (order) => GestureDetector(
                              onTap: () =>
                                  context.go('/orders/${order['id']}'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.bag_fill,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['order_number'] ??
                                                '#${order['id']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          Text(
                                            'R ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(
                                        status: order['status'] ?? ''),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
 
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
 
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
        Text(label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white60,
              fontSize: 11,
            )),
      ],
    );
  }
}
 
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}