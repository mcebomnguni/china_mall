import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart'; 
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// VOUCHER APPLY WIDGET — drop into checkout screen
// ─────────────────────────────────────────────────────────────────────────────
 
class VoucherApplyWidget extends StatefulWidget {
  final double orderTotal;
  final int? storeId;
  final Function(Map<String, dynamic> voucherResult) onApplied;
  final VoidCallback onRemoved;
 
  /// Optionally pre-fill a code (e.g. when user taps "Use" on a deal card).
  final String? initialCode;
 
  const VoucherApplyWidget({
    super.key,
    required this.orderTotal,
    this.storeId,
    required this.onApplied,
    required this.onRemoved,
    this.initialCode,
  });
 
  @override
  State<VoucherApplyWidget> createState() => _VoucherApplyWidgetState();
}
 
class _VoucherApplyWidgetState extends State<VoucherApplyWidget> {
  late final TextEditingController _codeCtrl;
  bool _loading = false;
  Map<String, dynamic>? _applied;
 
  @override
  void initState() {
    super.initState();
    // Pre-fill if a code was passed in (from "Use" button on deal card).
    _codeCtrl = TextEditingController(
        text: widget.initialCode?.toUpperCase() ?? '');
  }
 
  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _apply() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
 
    try {
      // Try Supabase validation first
      try {
        final client = SupabaseService.client;
        final code = _codeCtrl.text.trim().toUpperCase();
        final resp = await client
            .from('vouchers')
            .select('*')
            .ilike('code', code)
            .eq('active', true)
            .maybeSingle();
        if (resp != null) {
          final v = Map<String, dynamic>.from(resp);
          final now = DateTime.now().toUtc();
          final validFrom = v['valid_from'] != null ? DateTime.parse(v['valid_from']) : null;
          final validTo = v['valid_to'] != null ? DateTime.parse(v['valid_to']) : null;
          final usageLimit = v['usage_limit'] ?? 1;
          final timesUsed = v['times_used'] ?? 0;
          if ((validFrom == null || now.isAfter(validFrom)) && (validTo == null || now.isBefore(validTo)) && (usageLimit == 0 || timesUsed < usageLimit)) {
            // Compute discount amount (prefer absolute amount)
            double discountAmount = 0;
            if (v['discount_amount'] != null) discountAmount = double.tryParse(v['discount_amount'].toString()) ?? 0;
            else if (v['discount_percent'] != null) {
              final pct = double.tryParse(v['discount_percent'].toString()) ?? 0;
              discountAmount = widget.orderTotal * (pct / 100.0);
            }
            final result = {
              'valid': true,
              'code': v['code'],
              'discount_amount': discountAmount,
              'free_delivery': v['discount_amount'] == null && (v['discount_percent'] ?? 0) == 0,
            };
            setState(() => _applied = result);
            widget.onApplied(result);
            return;
          }
        }
      } catch (_) {}

      final token = await AuthService.getAccessToken();
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/vouchers/apply/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': _codeCtrl.text.trim().toUpperCase(),
          'order_total': widget.orderTotal,
          if (widget.storeId != null) 'store_id': widget.storeId,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['valid'] == true) {
        setState(() => _applied = body);
        widget.onApplied(body);
      } else {
        _showError(body['error']?.toString() ?? 'Invalid voucher code.');
      }
    } catch (_) {
      _showError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  void _remove() {
    setState(() {
      _applied = null;
      _codeCtrl.clear();
    });
    widget.onRemoved();
  }
 
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    // ── Applied state ──────────────────────────────────────────────────
    if (_applied != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _applied!['code']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    _applied!['free_delivery'] == true
                        ? 'Free delivery applied!'
                        : 'Saving R${_applied!['discount_amount']}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _remove,
              child: const Text('Remove',
                  style: TextStyle(
                      fontFamily: 'Satoshi', color: AppColors.error)),
            ),
          ],
        ),
      );
    }
 
    // ── Entry state ────────────────────────────────────────────────────
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter voucher code',
              prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _loading ? null : _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Apply',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// DISCOUNT TAB SCREEN — shows deals and voucher entry
// ─────────────────────────────────────────────────────────────────────────────
 
class DiscountTabScreen extends StatefulWidget {
  const DiscountTabScreen({super.key});
 
  @override
  State<DiscountTabScreen> createState() => _DiscountTabScreenState();
}
 
class _DiscountTabScreenState extends State<DiscountTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  // Pre-filled code when user taps "Use" on a deal — drives the widget below.
  String? _prefillCode;
 
  final _deals = const [
    _Deal('WELCOME10', '10% off your first order',    'Platform Wide',       Colors.blue,   '10% OFF',      null),
    _Deal('FREESHIP',  'Free delivery on orders over R200', 'All Stores',    Colors.green,  'FREE DELIVERY','Minimum R200'),
    _Deal('FLASH20',   '20% off selected electronics', 'Electronics',        Colors.orange, '20% OFF',      'Expires tonight'),
    _Deal('NEWSTORE',  'R50 off at new stores',         'New Stores',        Colors.purple, 'R50 OFF',      'Minimum R150'),
  ];
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
 
  // ── Use deal — switch to tab 2 AND prefill the code ───────────────────────
 
  void _useDeal(String code) {
    setState(() => _prefillCode = code);
    _tabController.animateTo(1);
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Deals & Vouchers',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Current Deals'),
            Tab(text: 'Enter Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
 
          // ── Tab 1: Deals list ──────────────────────────────────────
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _deals.length,
            itemBuilder: (_, i) {
              final d = _deals[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: d.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          d.badge,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
 
                      // Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.description,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              d.scope,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                            if (d.footnote != null)
                              Text(
                                d.footnote!,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  color: d.color,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
 
                      // Code + Use button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            d.code,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w800,
                              color: d.color,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            // Prefills the code AND switches tab — was only
                            // switching tab before, leaving the field empty.
                            onTap: () => _useDeal(d.code),
                            child: Text(
                              'Use →',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                color: d.color,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
 
          // ── Tab 2: Enter code manually ─────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.local_offer_outlined,
                    size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                const Text(
                  'Have a voucher code?',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your code below. Vouchers are applied at checkout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
 
                // Pass the prefilled code when the user came from "Use →".
                // Using a ValueKey so the widget rebuilds with the new code
                // each time _prefillCode changes.
                VoucherApplyWidget(
                  key: ValueKey(_prefillCode),
                  orderTotal: 0,
                  initialCode: _prefillCode,
                  onApplied: (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Voucher "${result['code']}" saved! It will be applied at checkout.',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onRemoved: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Deal model
// ─────────────────────────────────────────────────────────────────────────────
 
class _Deal {
  final String code, description, scope, badge;
  final Color color;
  final String? footnote;
 
  const _Deal(this.code, this.description, this.scope, this.color,
      this.badge, this.footnote);
}
