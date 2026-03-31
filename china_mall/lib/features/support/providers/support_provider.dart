import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class SupportProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get tickets => _tickets;
  List<Map<String, dynamic>> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  String? get _uid => SupabaseService.client.auth.currentUser?.id;

  // ── Load all tickets for current user ─────────────────────────────────────

  Future<void> loadTickets() async {
    final uid = _uid;
    if (uid == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.client
          .from('support_tickets')
          .select('*')
          .eq('profile_id', uid)
          .order('created_at', ascending: false);

      _tickets = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Failed to load tickets: $e';
    }

    _loading = false;
    notifyListeners();
  }

  // ── Load messages for a specific ticket ───────────────────────────────────

  Future<void> loadTicketMessages(int ticketId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.client
          .from('ticket_messages')
          .select('*, profiles:sender_id(full_name, role)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      _messages = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = 'Failed to load messages: $e';
    }

    _loading = false;
    notifyListeners();
  }

  // ── Create a new support ticket ───────────────────────────────────────────

  Future<bool> createTicket({
    required String category,
    required String subject,
    required String message,
    int? orderId,
    int? storeId,
  }) async {
    final uid = _uid;
    if (uid == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Insert the ticket
      final ticketData = await SupabaseService.client
          .from('support_tickets')
          .insert({
            'profile_id': uid,
            'category': category,
            'subject': subject,
            'status': 'open',
            if (orderId != null) 'order_id': orderId,
            if (storeId != null) 'store_id': storeId,
          })
          .select()
          .single();

      final ticketId = ticketData['id'];

      // Insert the first message
      await SupabaseService.client.from('ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': uid,
        'message': message,
        'is_internal': false,
      });

      _loading = false;
      notifyListeners();

      // Reload tickets list
      await loadTickets();
      return true;
    } catch (e) {
      _error = 'Failed to create ticket: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Send a message on an existing ticket ──────────────────────────────────

  Future<bool> sendMessage(int ticketId, String message) async {
    final uid = _uid;
    if (uid == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await SupabaseService.client.from('ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': uid,
        'message': message,
        'is_internal': false,
      });

      // Reload messages after sending
      await loadTicketMessages(ticketId);
      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }
}
