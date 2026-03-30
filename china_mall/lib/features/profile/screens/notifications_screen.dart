import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
 
class _AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String? route;
  bool read;
  final String time;
 
  _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.route,
    this.read = false,
    required this.time,
  });
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
 
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
 
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}
 
class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mutable list — was const before which is why "Mark all read" never worked.
  late final List<_AppNotification> _notifications = [
    _AppNotification(
      id: '1',
      title: 'Order Delivered!',
      body: 'Your order CM-ABC12345 has been delivered. Enjoy!',
      icon: CupertinoIcons.checkmark_circle_fill,
      color: AppColors.success,
      route: '/orders',
      read: false,
      time: 'Just now',
    ),
    _AppNotification(
      id: '2',
      title: 'Out for Delivery',
      body: 'CM-DEF67890 is out for delivery. Expect it soon.',
      icon: CupertinoIcons.car_fill,
      color: AppColors.info,
      route: '/orders',
      read: false,
      time: '1 hour ago',
    ),
    _AppNotification(
      id: '3',
      title: 'Payment Confirmed',
      body: 'Payment for CM-GHI11111 was successful.',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primary,
      route: '/payments/history',
      read: true,
      time: 'Yesterday',
    ),
    _AppNotification(
      id: '4',
      title: 'New Products Available',
      body: 'Check out the latest arrivals in Electronics!',
      icon: CupertinoIcons.bag_fill,
      color: AppColors.accent,
      route: '/products?category=electronics',
      read: true,
      time: '2 days ago',
    ),
  ];
 
  // ── Helpers ──────────────────────────────────────────────────────────────
 
  int get _unreadCount => _notifications.where((n) => !n.read).length;
 
  /// Mark a single notification as read.
  void _markRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.read = true;
    });
  }
 
  /// Mark every notification as read.
  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
    });
  }
 
  /// Remove a notification (swipe-to-dismiss or explicit delete).
  void _dismiss(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }
 
  /// Navigate to the notification's route and mark it read.
  void _open(_AppNotification n) {
    _markRead(n.id);
    if (n.route != null) {
      // Use go_router for deep links; fall back gracefully if the route
      // doesn't exist yet so the app doesn't crash.
      try {
        context.go(n.route!);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${n.title}…'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
 
  // ── Safe back navigation ─────────────────────────────────────────────────
 
  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }
 
  // ── Build ────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: AppColors.textPrimary,
          onPressed: _back,
          tooltip: 'Back',
        ),
        title: Text(
          _unreadCount > 0
              ? 'Notifications ($_unreadCount)'
              : 'Notifications',
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? EmptyState(
              icon: CupertinoIcons.bell_slash,
              title: 'No notifications',
              subtitle: "You're all caught up!",
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return _NotificationTile(
                  key: ValueKey(n.id),
                  notification: n,
                  onTap: () => _open(n),
                  onDismiss: () => _dismiss(n.id),
                );
              },
            ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Tile widget — extracted so Dismissible key is stable
// ─────────────────────────────────────────────────────────────────────────────
 
class _NotificationTile extends StatelessWidget {
  final _AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
 
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });
 
  @override
  Widget build(BuildContext context) {
    final n = notification;
 
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(CupertinoIcons.delete, color: AppColors.error, size: 22),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.read ? AppColors.surface : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.icon, color: n.color, size: 20),
              ),
              const SizedBox(width: 12),
 
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight:
                                  n.read ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Unread dot — only shown when unread
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.time,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
 
              // Chevron for tappable notifications
              if (n.route != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(CupertinoIcons.chevron_right,
                      size: 14, color: AppColors.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
