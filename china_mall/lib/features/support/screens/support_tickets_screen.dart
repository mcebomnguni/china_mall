import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../providers/support_provider.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SupportProvider>().loadTickets();
    });
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  const Text(
                    'Support Tickets',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/support/new'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.plus, size: 18, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ShimmerBox(width: double.infinity, height: 100, radius: 20),
                      ),
                    )
                  : provider.tickets.isEmpty
                      ? EmptyState(
                          icon: CupertinoIcons.chat_bubble_2,
                          title: 'No tickets yet',
                          subtitle: 'Need help? Create a support ticket and our team will assist you.',
                          buttonLabel: 'Create a Ticket',
                          onButton: () => context.push('/support/new'),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => context.read<SupportProvider>().loadTickets(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: provider.tickets.length,
                            itemBuilder: (_, i) => _TicketCard(ticket: provider.tickets[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ticket card ───────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  static const _categoryLabels = {
    'order_issue': 'Order Issue',
    'delivery_problem': 'Delivery Problem',
    'product_complaint': 'Product Complaint',
    'account_issue': 'Account Issue',
    'payment_dispute': 'Payment Dispute',
  };

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
    final ticketNumber = ticket['ticket_number']?.toString() ?? '#${ticket['id']}';
    final subject = ticket['subject']?.toString() ?? 'No subject';
    final category = ticket['category']?.toString() ?? '';
    final status = ticket['status']?.toString() ?? 'open';
    final createdAt = ticket['created_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(
            DateTime.tryParse(ticket['created_at'].toString()) ?? DateTime.now(),
          )
        : '';
    final categoryLabel = _categoryLabels[category] ?? category.replaceAll('_', ' ');
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OsCard(
        onTap: () => context.push('/support/${ticket['id']}'),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                CupertinoIcons.chat_bubble_text_fill,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticketNumber,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: status, color: color, label: _statusLabel(status)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subject,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$categoryLabel  ·  $createdAt',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 13, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Status badge pill ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final String label;
  const _StatusBadge({required this.status, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: AppColors.white,
        ),
      ),
    );
  }
}
