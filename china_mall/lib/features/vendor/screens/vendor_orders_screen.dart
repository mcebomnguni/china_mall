import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});
 
  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}
 
class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  List _orders = [];
  bool _loading = true;
  late TabController _tabCtrl;
 
  static const _filters = [
    {'label': 'All', 'status': null},
    {'label': 'New', 'status': 'payment_confirmed'},
    {'label': 'Processing', 'status': 'processing'},
    {'label': 'Pickup', 'status': 'awaiting_pickup'},
    {'label': 'Delivered', 'status': 'delivered'},
  ];
 
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _filters.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _load(_filters[_tabCtrl.index]['status']);
      }
    });
    _load(null);
  }
 
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _load(String? status) async {
    setState(() => _loading = true);
    final res = await ApiService.getVendorOrders(status: status);
    if (!mounted) return;
    setState(() {
      _orders = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Orders'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 13),
          tabs: _filters
              .map((f) => Tab(text: f['label'] as String))
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.cube_box,
                  title: 'No orders in this category',
                  subtitle: 'Orders will appear here as customers buy.',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(_filters[_tabCtrl.index]['status']),
                  child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final order = _orders[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order['order_number'] ??
                                    '#${order['id']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const Spacer(),
                              StatusChip(status: order['status'] ?? ''),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (order['buyer_name'] != null)
                            Row(
                              children: [
                                const Icon(CupertinoIcons.person_fill,
                                    size: 13,
                                    color: AppColors.textTertiary),
                                const SizedBox(width: 5),
                                Text(order['buyer_name'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              PriceText(
                                  price: (order['total_amount'] ?? 0)
                                      .toDouble()),
                              Text(
                                '${(order['items'] as List?)?.length ?? 0} item(s)',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ),
    );
  }
}