import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
 
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
 
class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabCtrl;
 
  List _products    = [];
  List _stores      = [];
  bool _loading     = false;
  bool _hasSearched = false;
 
  // Debounce timer — prevents hitting the API on every keystroke.
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 400);
 
  static const _recent = [
    'blankets', 'phones', 'shoes', 'furniture', 'bags',
  ];
 
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
 
  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }
 
  // ── Search with debounce ───────────────────────────────────────────────────
 
  void _onChanged(String query) {
    // Cancel any pending search.
    _debounce?.cancel();
 
    if (query.trim().isEmpty) {
      setState(() {
        _products    = [];
        _stores      = [];
        _hasSearched = false;
        _loading     = false;
      });
      return;
    }
 
    // Show loading immediately so the UI feels responsive.
    setState(() => _loading = true);
 
    // Wait 400ms before actually hitting the API.
    _debounce = Timer(_debounceDuration, () => _search(query));
  }
 
  Future<void> _search(String query) async {
    if (!mounted) return;
 
    final results = await Future.wait([
      ApiService.searchProducts(query),
      ApiService.searchStores(query),
    ]);
 
    if (!mounted) return;
    setState(() {
      _products    = results[0].isSuccess
          ? (results[0].data as List? ?? [])
          : [];
      _stores      = results[1].isSuccess
          ? (results[1].data as List? ?? [])
          : [];
      _loading     = false;
      _hasSearched = true;
    });
  }
 
  // ── Tap a suggestion ──────────────────────────────────────────────────────
 
  void _useSuggestion(String term) {
    _ctrl.text = term;
    // Move cursor to end.
    _ctrl.selection =
        TextSelection.collapsed(offset: term.length);
    _onChanged(term);
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
        title: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            _debounce?.cancel();
            if (v.trim().isNotEmpty) _search(v.trim());
          },
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search products & stores…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _ctrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      _onChanged('');
                    },
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                  )
                : null,
          ),
        ),
        bottom: _hasSearched
            ? TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'Products (${_products.length})'),
                  Tab(text: 'Stores (${_stores.length})'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary))
          : !_hasSearched
              ? _buildSuggestions()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildProductResults(),
                    _buildStoreResults(),
                  ],
                ),
    );
  }
 
  // ── Suggestions ────────────────────────────────────────────────────────────
 
  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Searches',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map(
                  (term) => GestureDetector(
                    onTap: () => _useSuggestion(term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.search,
                              size: 13,
                              color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            term,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
 
  // ── Product results ────────────────────────────────────────────────────────
 
  Widget _buildProductResults() {
    if (_products.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.search,
        title: 'No products found',
        subtitle: 'Try a different search term',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return GestureDetector(
          onTap: () => context.go('/products/${p['id']}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: AppNetworkImage(
                    url: p['image'],
                    height: 140,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        style:
                            Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      PriceText(
                          price: (p['price'] ?? 0).toDouble()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
 
  // ── Store results ──────────────────────────────────────────────────────────
 
  Widget _buildStoreResults() {
    if (_stores.isEmpty) {
      return const EmptyState(
        icon: CupertinoIcons.house_fill,
        title: 'No stores found',
        subtitle: 'Try a different search term',
      );
    }
    return ListView.builder(
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  url: store['logo'],
                  width: 56,
                  height: 56,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store['name'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium),
                      if (store['description'] != null)
                        Text(
                          store['description'],
                          style:
                              Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (store['average_rating'] != null) ...[
                        const SizedBox(height: 4),
                        StarRating(
                          rating: (store['average_rating'] ?? 0)
                              .toDouble(),
                          reviewCount: store['review_count'],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }
}