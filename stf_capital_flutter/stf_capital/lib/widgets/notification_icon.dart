// ─────────────────────────────────────────────────────────────────────────────
//  widgets/notification_icon.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ApplicationService>();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.clientNotificationsStream(auth.currentUser?.uid ?? ''),
      builder: (ctx, snap) {
        final unreadCount = snap.data?.where((n) => n['read'] == false).length ?? 0;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotifications(context, snap.data ?? []),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.goldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: AppTheme.darkBg,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context, List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Notifications',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: notifications.isEmpty
              ? Center(
                  child: Text('No notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (ctx, i) {
                    final notif = notifications[i];
                    return NotificationTile(
                      notification: notif,
                      onTap: () {
                        // Mark as read
                        context.read<ApplicationService>()
                            .markNotificationRead(notif['id'] as String);
                        Navigator.pop(ctx);
                        // Navigate to application
                        context.push('/application/${notif['applicationId'] as String}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] == true;
    final status = ApplicationStatusX.fromString(notification['newStatus'] ?? '');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.darkSurface2 : AppTheme.goldLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRead ? AppTheme.darkBorder : AppTheme.goldLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application status updated to ${status.displayName}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.goldLight,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification['productName'] ?? '',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (notification['returnReason'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${notification['returnReason']}',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppTheme.statusReturned,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(DateTime.parse(notification['createdAt'])),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved:
        return Icons.check_circle_rounded;
      case ApplicationStatus.declined:
        return Icons.cancel_rounded;
      case ApplicationStatus.returned:
        return Icons.assignment_return_rounded;
      case ApplicationStatus.opened:
        return Icons.folder_open_rounded;
      case ApplicationStatus.pendingOutcome:
        return Icons.hourglass_empty_rounded;
      case ApplicationStatus.pendingReview:
      default:
        return Icons.pending_rounded;
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved:
        return AppTheme.statusApproved;
      case ApplicationStatus.declined:
        return AppTheme.statusDeclined;
      case ApplicationStatus.returned:
        return AppTheme.statusReturned;
      case ApplicationStatus.opened:
        return AppTheme.statusOpened;
      case ApplicationStatus.pendingOutcome:
        return AppTheme.statusPendingOutcome;
      case ApplicationStatus.pendingReview:
      default:
        return AppTheme.statusPending;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
