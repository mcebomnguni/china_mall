import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/supabase_service.dart';
import '../providers/support_provider.dart';

class TicketChatScreen extends StatefulWidget {
  final int ticketId;
  const TicketChatScreen({super.key, required this.ticketId});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  Map<String, dynamic>? _ticket;

  String? get _uid => SupabaseService.client.auth.currentUser?.id;

  static const _categoryLabels = {
    'order_issue': 'Order Issue',
    'delivery_problem': 'Delivery Problem',
    'product_complaint': 'Product Complaint',
    'account_issue': 'Account Issue',
    'payment_dispute': 'Payment Dispute',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<SupportProvider>();
    await provider.loadTicketMessages(widget.ticketId);

    // Find the ticket from the provider's tickets list
    await provider.loadTickets();
    if (!mounted) return;
    final tickets = provider.tickets;
    for (final t in tickets) {
      if (t['id'] == widget.ticketId) {
        setState(() => _ticket = t);
        break;
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/support');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _messageCtrl.clear();

    final success = await context.read<SupportProvider>().sendMessage(
          widget.ticketId,
          text,
        );

    if (!mounted) return;
    setState(() => _sending = false);

    if (success) {
      _scrollToBottom();
    } else {
      final errorMsg = context.read<SupportProvider>().error ?? 'Failed to send message.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.primary;
      case 'in_progress':
        return const Color(0xFF3E7BFA);
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final messages = provider.messages;
    final status = _ticket?['status']?.toString() ?? 'open';
    final isClosed = status == 'closed' || status == 'resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(status),

            // ── Ticket info card ────────────────────────────────────────
            if (_ticket != null) _buildTicketInfo(status),

            // ── Messages ────────────────────────────────────────────────
            Expanded(
              child: provider.loading && messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : messages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  size: 40,
                                  color: AppColors.textTertiary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _MessageBubble(
                            message: messages[i],
                            isOwnMessage: messages[i]['sender_id'] == _uid,
                          ),
                        ),
            ),

            // ── Message input ───────────────────────────────────────────
            if (!isClosed) _buildMessageInput(),
            if (isClosed) _buildClosedBanner(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(String status) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _safePop,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(CupertinoIcons.back, size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ticket?['ticket_number']?.toString() ?? 'Ticket #${widget.ticketId}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _ticket?['subject']?.toString() ?? 'Loading...',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ticket info card ────────────────────────────────────────────────────────

  Widget _buildTicketInfo(String status) {
    final category = _ticket?['category']?.toString() ?? '';
    final categoryLabel = _categoryLabels[category] ?? category.replaceAll('_', ' ');
    final createdAt = _ticket?['created_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(
            DateTime.tryParse(_ticket!['created_at'].toString()) ?? DateTime.now(),
          )
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              _categoryIcon(category),
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              categoryLabel,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.clock, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              createdAt,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message input bar ───────────────────────────────────────────────────────

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _messageCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  hintStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.paperplane_fill,
                      size: 18,
                      color: AppColors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Closed banner ─────────────────────────────────────────────────────────

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.textTertiary),
          SizedBox(width: 8),
          Text(
            'This ticket has been closed',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'order_issue':
        return CupertinoIcons.cube_box;
      case 'delivery_problem':
        return CupertinoIcons.car_detailed;
      case 'product_complaint':
        return CupertinoIcons.exclamationmark_triangle;
      case 'account_issue':
        return CupertinoIcons.person_crop_circle;
      case 'payment_dispute':
        return CupertinoIcons.creditcard;
      default:
        return CupertinoIcons.question_circle;
    }
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isOwnMessage;

  const _MessageBubble({required this.message, required this.isOwnMessage});

  @override
  Widget build(BuildContext context) {
    final text = message['message']?.toString() ?? '';
    final createdAt = message['created_at'] != null
        ? DateFormat('dd MMM, HH:mm').format(
            DateTime.tryParse(message['created_at'].toString()) ?? DateTime.now(),
          )
        : '';

    // Extract sender info from the joined profiles relation
    final profiles = message['profiles'];
    final senderName = profiles is Map ? (profiles['full_name']?.toString() ?? 'Unknown') : 'Unknown';
    final senderRole = profiles is Map ? (profiles['role']?.toString() ?? '') : '';
    final isAdmin = senderRole == 'admin' || senderRole == 'staff';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            // Avatar for admin/support
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isAdmin ? AppColors.primary : AppColors.green100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isAdmin ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : isAdmin
                        ? AppColors.green050
                        : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                ),
                border: Border.all(
                  color: isOwnMessage
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name + role badge
                  if (!isOwnMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                senderRole.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Message text
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),

                  // Timestamp
                  const SizedBox(height: 4),
                  Align(
                    alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      createdAt,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
