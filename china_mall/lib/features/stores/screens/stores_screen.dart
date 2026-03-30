import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/skeleton_widgets.dart';
 
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});
 
  @override
  State<StoresScreen> createState() => _StoresScreenState();
}
 
class _StoresScreenState extends State<StoresScreen> {
  List _stores = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    final res = search != null && search.isNotEmpty
        ? await ApiService.searchStores(search)
        : await ApiService.getStores();
    if (!mounted) return;
    setState(() {
      _stores  = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Stores',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                _load(v);
              },
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(CupertinoIcons.search,
                    size: 18, color: AppColors.textTertiary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _debounce?.cancel();
                          _load();
                        },
                        child: const Icon(CupertinoIcons.xmark_circle_fill,
                            size: 16, color: AppColors.textTertiary),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const StoreCardSkeleton(),
              ),
            )
          : _stores.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.house_fill,
                  title: 'No stores found',
                  subtitle: 'Try a different search',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(),
                  child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stores.length,
                  itemBuilder: (_, i) {
                    final store = _stores[i];
                    return GestureDetector(
                      onTap: () => context.go('/stores/${store['id']}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppNetworkImage(
                              url: store['logo'],
                              width: 60,
                              height: 60,
                              radius: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(store['name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  if (store['description'] != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      store['description'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (store['average_rating'] != null)
                                        StarRating(
                                          rating: (store[
                                                          'average_rating'] ??
                                                      0)
                                                  .toDouble(),
                                          reviewCount:
                                              store['review_count'],
                                        ),
                                      const SizedBox(width: 10),
                                      if (store['product_count'] != null)
                                        Text(
                                          '${store['product_count']} products',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_right,
                                size: 16,
                                color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ),
    );
  }
}