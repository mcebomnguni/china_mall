import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Thin wrapper around Supabase for all admin-specific operations.
class AdminApi {
  static SupabaseClient get _db => AdminSupabase.client;
  static String get _uid => AdminSupabase.currentUser!.id;

  // ── Role helpers ───────────────────────────────────────────────────────────
  static String? _cachedAdminLevel;
  static Future<String?> getAdminLevel() async {
    if (_cachedAdminLevel != null) return _cachedAdminLevel;
    final p = await _db.from('profiles').select('admin_level').eq('id', _uid).single();
    _cachedAdminLevel = p['admin_level'] as String?;
    return _cachedAdminLevel;
  }
  static Future<bool> isSuperAdmin() async => (await getAdminLevel()) == 'super_admin';
  static void clearCache() => _cachedAdminLevel = null;

  // ── Auth ────────────────────────────────────────────────────────────────────

  static Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
    // Verify caller is admin/staff
    final profile = await _db
        .from('profiles')
        .select('role')
        .eq('id', AdminSupabase.currentUser!.id)
        .single();
    final role = profile['role'] as String?;
    if (role != 'admin' && role != 'staff') {
      await _db.auth.signOut();
      throw Exception('Access denied: not an admin account.');
    }
  }

  static Future<void> signOut() => _db.auth.signOut();

  // ── Dashboard ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    final res = await _db.rpc('admin_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  // ── Vendor applications ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVendorApplications({
    String? status,
  }) async {
    var q = _db.from('vendor_applications').select(
      '*, profiles:profile_id(full_name, email, avatar_url)',
    );
    if (status != null) q = q.eq('status', status);
    final res = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<Map<String, dynamic>> getVendorApplicationDetail(int id) async {
    final res = await _db
        .from('vendor_applications')
        .select('*, profiles:profile_id(full_name, email, phone, avatar_url)')
        .eq('id', id)
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<void> approveVendor(int id, {String? notes}) async {
    await _db.rpc('admin_approve_vendor', params: {
      'p_application_id': id,
      'p_admin_id':       _uid,
      'p_notes':          notes,
    });
  }

  static Future<void> rejectVendor(int id, {required String notes}) async {
    await _db.rpc('admin_reject_vendor', params: {
      'p_application_id': id,
      'p_admin_id':       _uid,
      'p_notes':          notes,
    });
  }

  static Future<void> vendorMoreInfo(int id, {required String notes}) async {
    await _db.rpc('admin_vendor_more_info', params: {
      'p_application_id': id,
      'p_admin_id':       _uid,
      'p_notes':          notes,
    });
  }

  // ── Product approvals ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProducts({String? status}) async {
    var q = _db.from('products').select(
      '*, stores:store_id(name, owner), product_images(url, ordinal)',
    );
    if (status != null) q = q.eq('status', status);
    final res = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<Map<String, dynamic>> getProductDetail(int id) async {
    final res = await _db
        .from('products')
        .select('*, stores:store_id(name, owner, is_active), product_images(url, ordinal), categories:category_id(label)')
        .eq('id', id)
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<void> approveProduct(int id) async {
    await _db.rpc('admin_approve_product', params: {
      'p_product_id': id,
      'p_admin_id':   _uid,
    });
  }

  static Future<void> rejectProduct(int id, {required String notes}) async {
    await _db.rpc('admin_reject_product', params: {
      'p_product_id': id,
      'p_admin_id':   _uid,
      'p_notes':      notes,
    });
  }

  static Future<void> productNeedsChanges(int id, {required String notes}) async {
    await _db.rpc('admin_product_needs_changes', params: {
      'p_product_id': id,
      'p_admin_id':   _uid,
      'p_notes':      notes,
    });
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTopProducts({
    int days  = 30,
    int limit = 100,
  }) async {
    final res = await _db.rpc('admin_top_products', params: {
      'p_days':  days,
      'p_limit': limit,
    });
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getRevenueTimeline({
    String period = 'day',
    int    days   = 30,
  }) async {
    final res = await _db.rpc('admin_revenue_timeline', params: {
      'p_period': period,
      'p_days':   days,
    });
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getStorePerformance({int days = 30}) async {
    final res = await _db.rpc('admin_store_performance', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getCourierPerformance({int days = 30}) async {
    final res = await _db.rpc('admin_courier_performance', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getCategoryStats({int days = 30}) async {
    final res = await _db.rpc('admin_category_stats', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Payments (A3) ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPaymentStats({int days = 30}) async {
    final res = await _db.rpc('admin_payment_stats', params: {'p_days': days});
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> getPayments({String? status, int limit = 200}) async {
    var q = _db.from('payments').select('*, profiles:profile_id(full_name, email), orders:order_id(id, total_amount, status)');
    if (status != null) q = q.eq('status', status);
    final res = await q.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getPayouts({String? status}) async {
    var q = _db.from('payouts').select('*, payout_schedules(frequency, commission_pct)');
    if (status != null) q = q.eq('status', status);
    final res = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getPayoutSchedules() async {
    final res = await _db.from('payout_schedules').select('*').order('entity_type').order('entity_id');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> processPayout(int id, {String? reference}) async {
    await _db.rpc('admin_process_payout', params: {
      'p_payout_id': id,
      'p_admin_id':  _uid,
      'p_reference': reference,
    });
  }

  static Future<void> updatePayoutSchedule(int id, {String? frequency, double? commissionPct, bool? isActive}) async {
    await _db.rpc('admin_update_payout_schedule', params: {
      'p_schedule_id':    id,
      'p_frequency':      frequency,
      'p_commission_pct': commissionPct,
      'p_is_active':      isActive,
    });
  }

  // ── Help Desk (A4) ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTicketStats() async {
    final res = await _db.rpc('admin_ticket_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> getTickets({String? status, String? category}) async {
    var q = _db.from('support_tickets').select(
      '*, profiles:profile_id(full_name, email, avatar_url), assigned:assigned_to(full_name)',
    );
    if (status != null) q = q.eq('status', status);
    if (category != null) q = q.eq('category', category);
    final res = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<Map<String, dynamic>> getTicketDetail(int id) async {
    final res = await _db.from('support_tickets').select(
      '*, profiles:profile_id(full_name, email, phone, avatar_url), assigned:assigned_to(full_name)',
    ).eq('id', id).single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> getTicketMessages(int ticketId) async {
    final res = await _db.from('ticket_messages').select(
      '*, profiles:sender_id(full_name, role, avatar_url)',
    ).eq('ticket_id', ticketId).order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> assignTicket(int ticketId) async {
    await _db.rpc('admin_assign_ticket', params: {
      'p_ticket_id': ticketId,
      'p_admin_id':  _uid,
    });
  }

  static Future<void> updateTicketStatus(int ticketId, String status) async {
    await _db.rpc('admin_update_ticket_status', params: {
      'p_ticket_id': ticketId,
      'p_status':    status,
      'p_admin_id':  _uid,
    });
  }

  static Future<void> replyTicket(int ticketId, String message, {bool isInternal = false}) async {
    await _db.rpc('admin_reply_ticket', params: {
      'p_ticket_id':   ticketId,
      'p_admin_id':    _uid,
      'p_message':     message,
      'p_is_internal': isInternal,
    });
  }

  // ── Inventory (A5) ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getInventoryStats() async {
    final res = await _db.rpc('admin_inventory_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> getInventoryOverview() async {
    final res = await _db.rpc('admin_inventory_overview');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getLowStockItems({int threshold = 3}) async {
    final res = await _db.rpc('admin_low_stock_items', params: {'p_threshold': threshold});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> notifyRestock(int productId, {String? message}) async {
    await _db.rpc('admin_notify_restock', params: {
      'p_product_id': productId,
      'p_admin_id':   _uid,
      'p_message':    message,
    });
  }

  // ── A6: Orders Monitoring ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrdersOverview({String? status, int days = 30}) async {
    final res = await _db.rpc('admin_orders_overview', params: {
      'p_status': status,
      'p_days':   days,
    });
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getOrderHandoffs(int orderId) async {
    final res = await _db.rpc('admin_order_handoffs', params: {'p_order_id': orderId});
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Financial (super_admin) ────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFinancialByStore({int days = 30}) async {
    final res = await _db.rpc('admin_financial_by_store', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getFinancialByCourier({int days = 30}) async {
    final res = await _db.rpc('admin_financial_by_courier', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getRefundSummary({int days = 30}) async {
    final res = await _db.rpc('admin_refund_summary', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> processRefund(int refundId, String action) async {
    await _db.rpc('admin_process_refund', params: {
      'p_refund_id': refundId,
      'p_admin_id':  _uid,
      'p_action':    action,
    });
  }

  static Future<List<Map<String, dynamic>>> getGeographicDemand({int days = 30}) async {
    final res = await _db.rpc('admin_geographic_demand', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Financial Books (super_admin) ──────────────────────────────────────────

  static Future<Map<String, dynamic>> getIncomeStatement(String from, String to) async {
    final res = await _db.rpc('admin_income_statement', params: {'p_from': from, 'p_to': to});
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> getTrialBalance() async {
    final res = await _db.rpc('admin_trial_balance');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<List<Map<String, dynamic>>> getFinancialEntries({int limit = 100}) async {
    final res = await _db.from('financial_entries').select(
      '*, profiles:created_by(full_name)',
    ).order('entry_date', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> addFinancialEntry({
    required String date, required String category,
    required String description, double debit = 0, double credit = 0,
  }) async {
    await _db.rpc('admin_add_financial_entry', params: {
      'p_admin_id':    _uid,
      'p_entry_date':  date,
      'p_category':    category,
      'p_description': description,
      'p_debit':       debit,
      'p_credit':      credit,
    });
  }

  // ── Admin Management (super_admin) ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> listAdmins() async {
    final res = await _db.rpc('admin_list_admins');
    return List<Map<String, dynamic>>.from(res as List);
  }

  static Future<void> createAdmin(String email, String fullName, {String role = 'admin', String level = 'admin'}) async {
    await _db.rpc('admin_create_admin', params: {
      'p_caller_id':   _uid,
      'p_email':       email,
      'p_full_name':   fullName,
      'p_role':        role,
      'p_admin_level': level,
    });
  }
}
