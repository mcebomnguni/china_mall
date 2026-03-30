import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
 
class AdminApprovalQueueScreen extends StatefulWidget {
  /// Pass 'stores' or 'products'.
  final String queueType;
  const AdminApprovalQueueScreen({super.key, required this.queueType});
 
  @override
  State<AdminApprovalQueueScreen> createState() =>
      _AdminApprovalQueueScreenState();
}
 
class _AdminApprovalQueueScreenState
    extends State<AdminApprovalQueueScreen> {
  List<dynamic> _items   = [];
  bool          _loading = true;
  bool          _loadError = false;
 
  // ── Computed strings ───────────────────────────────────────────────────────
 
  String get _title =>
      widget.queueType == 'stores' ? 'Store Approvals' : 'Product Approvals';
 
  String get _endpoint => widget.queueType == 'stores'
      ? '${ApiConstants.baseUrl}/stores/?status=pending'
      : '${ApiConstants.baseUrl}/products/?status=pending';
 
  String _actionEndpoint(int id) => widget.queueType == 'stores'
      ? '${ApiConstants.baseUrl}/admin/stores/$id/action/'
      : '${ApiConstants.baseUrl}/admin/products/$id/action/';
 
  // ── Auth headers ───────────────────────────────────────────────────────────
 
  Future<Map<String, String>> get _headers async {
    final token = await AuthService.getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin');
    }
  }
 
  // ── Load ───────────────────────────────────────────────────────────────────
 
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = false; });
    try {
      // Try Supabase queries first
      try {
        final client = SupabaseService.client;
        if (widget.queueType == 'stores') {
          final resp = await client
              .from('stores')
              .select('*, profiles:owner(full_name)')
              .eq('status', 'pending');
          if (resp != null) {
            final list = (resp as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            if (!mounted) return;
            setState(() => _items = list);
            return;
          }
        } else {
          final resp =
              await client.from('products').select('*').eq('is_active', false);
          if (resp != null) {
            final list = (resp as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            if (!mounted) return;
            setState(() => _items = list);
            return;
          }
        }
      } catch (_) {}

      final res = await http.get(
        Uri.parse(_endpoint),
        headers: await _headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Handle both list and paginated { results: [] } response shapes.
        final items = decoded is List
            ? decoded
            : (decoded['results'] as List? ?? []);
        setState(() => _items = items);
      } else {
        setState(() => _loadError = true);
        _showError('Failed to load (${res.statusCode}). Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = true);
        _showError('Network error. Please check your connection.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Approve / reject ───────────────────────────────────────────────────────
 
  Future<void> _action(int id, String action,
      {String reason = ''}) async {
    try {
      // Try direct Supabase table update first (fast-path)
      try {
        final client = SupabaseService.client;
        if (widget.queueType == 'stores') {
          await client
              .from('stores')
              .update({'status': action == 'approve' ? 'approved' : 'rejected'})
              .eq('id', id);
          await client.from('audit_logs').insert([
            {
              'actor': null,
              'action': action == 'approve' ? 'approve_store' : 'reject_store',
              'resource_type': 'store',
              'resource_id': String(id),
              'details': {'reason': reason}
            }
          ]);
            if (!mounted) return;
            final label = action == 'approve' ? 'Approved' : 'Rejected';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label successfully.'),
                backgroundColor: action == 'approve' ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _load();
            return;
        } else {
          await client
              .from('products')
              .update({'is_active': action == 'approve'})
              .eq('id', id);
          await client.from('audit_logs').insert([
            {
              'actor': null,
              'action':
                  action == 'approve' ? 'approve_product' : 'reject_product',
              'resource_type': 'product',
              'resource_id': String(id),
              'details': {'reason': reason}
            }
          ]);
            if (!mounted) return;
            final label = action == 'approve' ? 'Approved' : 'Rejected';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label successfully.'),
                backgroundColor: action == 'approve' ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _load();
            return;
        }
      } catch (_) {}

      final res = await http.post(
        Uri.parse(_actionEndpoint(id)),
        headers: await _headers,
        body: jsonEncode({'action': action, 'reason': reason}),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        final label = action == 'approve' ? 'Approved' : 'Rejected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label successfully.'),
            backgroundColor: action == 'approve' ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
        _showError(body['error']?.toString() ?? body['detail']?.toString() ?? 'Action failed. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Network error. Please try again.');
    }
  }
 
  // ── Reject dialog ──────────────────────────────────────────────────────────
 
  void _showRejectDialog(int id) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Reject — Enter Reason',
          style: TextStyle(
              fontFamily: 'Satoshi', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Why is this being rejected?',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _action(id, 'reject', reason: ctrl.text.trim());
            },
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
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
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.wifi_slash,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not load queue',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.checkmark_circle,
                              size: 56, color: AppColors.success),
                          const SizedBox(height: 16),
                          Text(
                            'No pending ${widget.queueType}',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i] as Map<String, dynamic>;
                          return _QueueItemCard(
                            item: item,
                            queueType: widget.queueType,
                            onApprove: () =>
                                _action(item['id'], 'approve'),
                            onReject: () =>
                                _showRejectDialog(item['id']),
                          );
                        },
                      ),
                    ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Queue item card — handles both stores and products
// ─────────────────────────────────────────────────────────────────────────────
 
class _QueueItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String queueType;
  final VoidCallback onApprove;
  final VoidCallback onReject;
 
  const _QueueItemCard({
    required this.item,
    required this.queueType,
    required this.onApprove,
    required this.onReject,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? 'Unnamed',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
 
          // Description
          if (item['description'] != null &&
              item['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
 
          // Price (products only)
          if (item['price'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'R${item['price']}',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
 
          // Owner (stores only)
          if (queueType == 'stores' &&
              item['owner_name'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.person,
                    size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  item['owner_name'],
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
 
          const SizedBox(height: 14),
 
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(CupertinoIcons.xmark,
                      size: 14, color: AppColors.error),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.checkmark,
                      size: 14, color: Colors.white),
                  label: const Text(
                    'Approve',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
