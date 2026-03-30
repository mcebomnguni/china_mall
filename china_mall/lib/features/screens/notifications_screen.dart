import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() => _notifications = notifications);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'order_update': return Icons.receipt_long;
      case 'delivery_update': return Icons.local_shipping;
      case 'pickup_ready': return Icons.store;
      case 'payment': return Icons.payment;
      case 'promotion': return Icons.local_offer;
      case 'store_update': return Icons.storefront;
      case 'product_update': return Icons.inventory;
      default: return Icons.notifications;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'order_update': return Colors.blue;
      case 'delivery_update': return Colors.orange;
      case 'pickup_ready': return Colors.green;
      case 'payment': return Colors.purple;
      case 'promotion': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 70, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("You're all caught up!",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    final unread = n['is_read'] == false;
                    final color = _typeColor(n['notification_type']);

                    return Container(
                      color: unread
                          ? color.withValues(alpha: 0.04)
                          : Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            _typeIcon(n['notification_type']),
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                n['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['body'] ?? '',
                                style: TextStyle(
                                    color: unread
                                        ? Colors.black87
                                        : Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(n['created_at']),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Navigate based on notification data
                          final data = n['data'] as Map?;
                          if (data?['order_id'] != null) {
                            // Navigator.pushNamed(context, '/orders/${data['order_id']}');
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
