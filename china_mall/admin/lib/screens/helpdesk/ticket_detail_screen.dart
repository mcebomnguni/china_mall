import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/admin_api.dart';
import '../../core/theme/admin_theme.dart';
import '../_widgets/section_card.dart';

const _categoryLabels = <String, String>{
  'order_issue': 'Order Issue',
  'delivery_problem': 'Delivery Problem',
  'product_complaint': 'Product Complaint',
  'account_issue': 'Account Issue',
  'payment_dispute': 'Payment Dispute',
};

Color _priorityColor(String? p) {
  switch (p) {
    case 'urgent':
      return AC.error;
    case 'high':
      return AC.warning;
    case 'medium':
      return AC.info;
    case 'low':
      return AC.textMuted;
    default:
      return AC.textMuted;
  }
}

String _capitalize(String? s) {
  if (s == null || s.isEmpty) return '—';
  return s[0].toUpperCase() + s.substring(1);
}

class TicketDetailScreen extends StatefulWidget {
  final int id;
  const TicketDetailScreen({super.key, required this.id});
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _acting = false;
  String? _error;

  final _replyCtrl = TextEditingController();
  bool _isInternal = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApi.getTicketDetail(widget.id),
        AdminApi.getTicketMessages(widget.id),
      ]);
      setState(() {
        _ticket = results[0] as Map<String, dynamic>;
        _messages = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignToMe() async {
    setState(() => _acting = true);
    try {
      await AdminApi.assignTicket(widget.id);
      _showSuccess('Ticket assigned to you.');
      await _load();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _acting = true);
    try {
      await AdminApi.updateTicketStatus(widget.id, status);
      _showSuccess('Status updated to ${_capitalize(status)}.');
      await _load();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _acting = true);
    try {
      await AdminApi.replyTicket(widget.id, text, isInternal: _isInternal);
      _replyCtrl.clear();
      setState(() => _isInternal = false);
      _showSuccess(_isInternal ? 'Internal note added.' : 'Reply sent.');
      await _load();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: AC.success,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: AC.error,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.primary))
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: AC.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/helpdesk'),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Help Desk'),
                          ),
                          const Text(' / ',
                              style: TextStyle(color: AC.textMuted)),
                          Text(_ticket?['ticket_number'] ?? '',
                              style: const TextStyle(color: AC.textSecond)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Two-column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column — ticket info + messages
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _TicketInfoCard(ticket: _ticket!),
                                const SizedBox(height: 16),
                                _MessageThread(messages: _messages),
                                const SizedBox(height: 16),
                                _ReplyBox(
                                  controller: _replyCtrl,
                                  isInternal: _isInternal,
                                  acting: _acting,
                                  onInternalChanged: (v) =>
                                      setState(() => _isInternal = v),
                                  onSend: _sendReply,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right column — action panel
                          SizedBox(
                            width: 280,
                            child: _ActionPanel(
                              ticket: _ticket!,
                              acting: _acting,
                              onAssign: _assignToMe,
                              onStatusChange: _updateStatus,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Ticket info card ─────────────────────────────────────────────────────────

class _TicketInfoCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketInfoCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final priority = ticket['priority'] as String?;
    final category = ticket['category'] as String?;
    final pColor = _priorityColor(priority);

    return SectionCard(
      title: 'Ticket Details',
      child: Column(
        children: [
          _InfoRow('Ticket #', ticket['ticket_number'] ?? '—'),
          _InfoRow('Subject', ticket['subject'] ?? '—'),
          _InfoRow(
              'Category', _categoryLabels[category] ?? _capitalize(category)),
          _InfoRowWidget('Priority', Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_capitalize(priority),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pColor,
                )),
          )),
          _InfoRow('Customer', ticket['customer_name'] ?? '—'),
          _InfoRow('Email', ticket['customer_email'] ?? '—'),
          if (ticket['order_number'] != null)
            _InfoRow('Linked Order', ticket['order_number']),
          if (ticket['store_name'] != null)
            _InfoRow('Linked Store', ticket['store_name']),
          _InfoRow(
              'Created',
              ticket['created_at'] != null
                  ? DateFormat('d MMM yyyy, HH:mm')
                      .format(DateTime.parse(ticket['created_at']))
                  : '—'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, color: AC.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRowWidget(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Message thread ───────────────────────────────────────────────────────────

class _MessageThread extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const _MessageThread({required this.messages});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Conversation',
      action: Text('${messages.length} message${messages.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: AC.textMuted)),
      child: messages.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No messages yet',
                    style: TextStyle(color: AC.textMuted, fontSize: 13)),
              ),
            )
          : Column(
              children: messages.asMap().entries.map((entry) {
                final idx = entry.key;
                final msg = entry.value;
                return Padding(
                  padding: EdgeInsets.only(top: idx == 0 ? 0 : 12),
                  child: _MessageBubble(message: msg),
                );
              }).toList(),
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final senderName = message['sender_name'] as String? ?? 'Unknown';
    final role = message['sender_role'] as String? ?? 'customer';
    final text = message['message'] as String? ?? '';
    final isInternal = message['is_internal'] == true;
    final createdAt = message['created_at'] != null
        ? DateFormat('d MMM yyyy, HH:mm')
            .format(DateTime.parse(message['created_at']))
        : '';

    Color roleBadgeColor;
    String roleLabel;
    switch (role) {
      case 'admin':
        roleBadgeColor = AC.primary;
        roleLabel = 'Admin';
        break;
      case 'staff':
        roleBadgeColor = AC.info;
        roleLabel = 'Staff';
        break;
      default:
        roleBadgeColor = AC.warning;
        roleLabel = 'Customer';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInternal
            ? const Color(0xFFFEF9C3)
            : AC.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInternal
              ? const Color(0xFFFDE68A)
              : AC.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name, role badge, internal label, timestamp
          Row(
            children: [
              Text(senderName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AC.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roleBadgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(roleLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: roleBadgeColor,
                    )),
              ),
              if (isInternal) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AC.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Internal Note',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AC.warning,
                      )),
                ),
              ],
              const Spacer(),
              Text(createdAt,
                  style: const TextStyle(fontSize: 11, color: AC.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AC.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Reply box ────────────────────────────────────────────────────────────────

class _ReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isInternal;
  final bool acting;
  final ValueChanged<bool> onInternalChanged;
  final VoidCallback onSend;

  const _ReplyBox({
    required this.controller,
    required this.isInternal,
    required this.acting,
    required this.onInternalChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Reply',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: isInternal
                  ? 'Write an internal note (not visible to customer)…'
                  : 'Type your reply to the customer…',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              fillColor: isInternal
                  ? const Color(0xFFFEF9C3)
                  : AC.surface,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: isInternal,
                  onChanged: (v) => onInternalChanged(v ?? false),
                  activeColor: AC.warning,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onInternalChanged(!isInternal),
                child: const Text('Internal Note',
                    style: TextStyle(fontSize: 12, color: AC.textSecond)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: acting ? null : onSend,
                icon: acting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(isInternal ? 'Add Note' : 'Send Reply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInternal ? AC.warning : AC.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action panel ─────────────────────────────────────────────────────────────

class _ActionPanel extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool acting;
  final VoidCallback onAssign;
  final ValueChanged<String> onStatusChange;

  const _ActionPanel({
    required this.ticket,
    required this.acting,
    required this.onAssign,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] as String?;
    final priority = ticket['priority'] as String?;
    final assignedTo = ticket['assigned_to_name'] as String?;
    final pColor = _priorityColor(priority);

    return SectionCard(
      title: 'Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current status
          Row(
            children: [
              const Text('Status',
                  style: TextStyle(
                      fontSize: 12,
                      color: AC.textSecond,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              StatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // Priority display
          Row(
            children: [
              const Text('Priority',
                  style: TextStyle(
                      fontSize: 12,
                      color: AC.textSecond,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_capitalize(priority),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pColor,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Assigned to
          Row(
            children: [
              const Text('Assigned To',
                  style: TextStyle(
                      fontSize: 12,
                      color: AC.textSecond,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(assignedTo ?? 'Unassigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: assignedTo != null ? AC.textPrimary : AC.textMuted,
                    fontStyle: assignedTo != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AC.border),
          const SizedBox(height: 16),

          // Assign to me button
          if (acting) ...[
            const Center(
                child: CircularProgressIndicator(color: AC.primary)),
          ] else ...[
            OutlinedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Assign to Me'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AC.primary,
                side: const BorderSide(color: AC.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Status dropdown
            const Text('Update Status',
                style: TextStyle(
                    fontSize: 12,
                    color: AC.textSecond,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AC.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AC.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  style: const TextStyle(
                      fontSize: 13, color: AC.textPrimary),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AC.textSecond),
                  items: const [
                    DropdownMenuItem(
                        value: 'open', child: Text('Open')),
                    DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(
                        value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (v) {
                    if (v != null && v != status) {
                      onStatusChange(v);
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
