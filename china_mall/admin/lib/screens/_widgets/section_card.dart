import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const SectionCard({super.key, required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AC.textPrimary,
                  )),
              if (action != null) ...[const Spacer(), action!],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String? status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(statusLabel(status),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          )),
    );
  }
}

// ── Action button row ─────────────────────────────────────────────────────────

class ApprovalActions extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onMoreInfo;
  final bool loading;

  const ApprovalActions({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.onMoreInfo,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AC.primary),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Approve'),
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(backgroundColor: AC.success),
        ),
        if (onMoreInfo != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.info_outline_rounded, size: 16),
            label: const Text('More Info'),
            onPressed: onMoreInfo,
            style: OutlinedButton.styleFrom(
              foregroundColor: AC.info,
              side: const BorderSide(color: AC.info),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Reject'),
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AC.error,
            side: const BorderSide(color: AC.error),
          ),
        ),
      ],
    );
  }
}
