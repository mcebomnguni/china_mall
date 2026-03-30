import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
 
class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});
 
  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}
 
class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  List<dynamic> _devices        = [];
  bool          _loading        = true;
  String?       _currentToken;          // FCM token of THIS device
  final Set<String> _removing   = {};   // tokens currently being removed
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _init();
  }
 
  Future<void> _init() async {
    // Fetch the current device token FIRST so we can mark it correctly
    // before the list renders.
    _currentToken = await _fetchCurrentToken();
    await _load();
  }
 
  // ── Auth headers ───────────────────────────────────────────────────────────
 
  Future<Map<String, String>> get _headers async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
 
  // ── Current device token ───────────────────────────────────────────────────
 
  /// Returns the FCM push token for this device so we can exclude it from
  /// "sign out all others". Falls back to null if the service is unavailable.
  Future<String?> _fetchCurrentToken() async {
    try {
      return await NotificationService.getFCMToken();
    } catch (_) {
      return null;
    }
  }
 
  // ── Load devices ───────────────────────────────────────────────────────────
 
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Try Supabase first
      try {
        final client = SupabaseService.client;
        final resp = await client.from('notification_devices').select('*');
        if (resp != null) {
          setState(() => _devices = List<dynamic>.from(resp as List));
          return;
        }
      } catch (_) {}

      // Fallback to HTTP
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/'),
        headers: await _headers,
      );

      if (res.statusCode == 200) {
        setState(() => _devices = jsonDecode(res.body) as List<dynamic>);
      } else {
        _showError('Could not load devices (${res.statusCode}).');
      }
    } catch (_) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Remove single device ───────────────────────────────────────────────────
 
  Future<void> _removeDevice(String token) async {
    final confirmed = await _confirmDialog(
      title: 'Remove Device?',
      body: 'This device will be signed out and will need to log in again.',
      action: 'Remove',
    );
    if (confirmed != true || !mounted) return;
 
    setState(() => _removing.add(token));
 
    try {
      // Try direct Supabase table delete first
      try {
        final client = SupabaseService.client;
        await client.from('notification_devices').delete().eq('token', token);
        setState(() => _devices.removeWhere((d) => d['token'] == token));
        return;
      } catch (_) {}

      // Then try Supabase Edge Function as a fallback for server-side logic
      try {
        final client = SupabaseService.client;
        final fnRes = await client.functions.invoke('notifications_unregister_device', body: {'token': token});
        setState(() => _devices.removeWhere((d) => d['token'] == token));
        return;
      } catch (_) {}

      final res = await http.delete(
        Uri.parse(
            '${ApiConstants.baseUrl}/notifications/unregister-device/'),
        headers: await _headers,
        body: jsonEncode({'token': token}),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => _devices.removeWhere((d) => d['token'] == token));
      } else {
        _showError('Failed to remove device. Please try again.');
      }
    } catch (_) {
      _showError('Network error. Could not remove device.');
    } finally {
      if (mounted) setState(() => _removing.remove(token));
    }
  }
 
  // ── Remove all other devices ───────────────────────────────────────────────
 
  Future<void> _removeAllOtherDevices() async {
    final others = _devices
        .where((d) => d['token'] != _currentToken)
        .toList();
 
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other devices to sign out.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    final confirmed = await _confirmDialog(
      title: 'Sign Out All Other Devices?',
      body: 'All ${others.length} other device(s) will be signed out immediately.',
      action: 'Sign Out All',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
 
    final headers = await _headers;
 
    for (final device in others) {
      final token = device['token'] as String?;
      if (token == null) continue;
 
      setState(() => _removing.add(token));
      try {
        // Try direct Supabase table delete first
        try {
          final client = SupabaseService.client;
          await client.from('notification_devices').delete().eq('token', token);
          if (mounted) {
            setState(() => _devices.removeWhere((d) => d['token'] == token));
          }
          continue;
        } catch (_) {}

        // Then Edge Function fallback
        try {
          final client = SupabaseService.client;
          await client.functions.invoke('notifications_unregister_device', body: {'token': token});
          if (mounted) setState(() => _devices.removeWhere((d) => d['token'] == token));
          continue;
        } catch (_) {}

        await http.delete(
          Uri.parse(
              '${ApiConstants.baseUrl}/notifications/unregister-device/'),
          headers: headers,
          body: jsonEncode({'token': token}),
        );
        if (mounted) {
          setState(() => _devices.removeWhere((d) => d['token'] == token));
        }
      } catch (_) {
        // Continue removing others even if one fails.
      } finally {
        if (mounted) setState(() => _removing.remove(token));
      }
    }
 
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All other devices have been signed out.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String action,
    bool isDestructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }
 
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return 'Added ${DateFormat('d MMM yyyy').format(dt)}';
    } catch (_) {
      return '';
    }
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
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    // Devices other than this one — used for the "sign out others" button.
    final otherCount =
        _devices.where((d) => d['token'] != _currentToken).length;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Linked Devices',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
        actions: [
          if (otherCount > 0)
            TextButton(
              onPressed: _removeAllOtherDevices,
              child: const Text(
                'Sign out others',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No linked devices',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w600,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Devices that receive notifications will appear here.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'These devices are registered to receive notifications '
                        'and have access to your account.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ..._devices.map((device) => _DeviceTile(
                            device: device,
                            isCurrentDevice:
                                device['token'] == _currentToken,
                            isRemoving: _removing
                                .contains(device['token']),
                            formattedDate:
                                _formatDate(device['created_at']),
                            onRemove: () =>
                                _removeDevice(device['token']),
                          )),
                    ],
                  ),
                ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Device tile — extracted for clarity
// ─────────────────────────────────────────────────────────────────────────────
 
class _DeviceTile extends StatelessWidget {
  final dynamic device;
  final bool    isCurrentDevice;
  final bool    isRemoving;
  final String  formattedDate;
  final VoidCallback onRemove;
 
  const _DeviceTile({
    required this.device,
    required this.isCurrentDevice,
    required this.isRemoving,
    required this.formattedDate,
    required this.onRemove,
  });
 
  @override
  Widget build(BuildContext context) {
    final isAndroid  = (device['platform'] ?? '').toLowerCase() == 'android';
    final deviceName = (device['device_name']?.isNotEmpty == true)
        ? device['device_name'] as String
        : '${isAndroid ? 'Android' : 'iOS'} Device';
    final isActive   = device['is_active'] == true;
 
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isCurrentDevice
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAndroid
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.blue.withValues(alpha: 0.12),
          child: Icon(
            isAndroid ? Icons.android : Icons.phone_iphone,
            color: isAndroid ? Colors.green : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceName,
                style: const TextStyle(
                    fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
              ),
            ),
            // "This device" badge
            if (isCurrentDevice)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This device',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              (device['platform'] ?? '').toString().toUpperCase(),
              style: const TextStyle(fontSize: 11),
            ),
            if (formattedDate.isNotEmpty)
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: isCurrentDevice
            // Cannot remove your own device from this screen.
            ? null
            : isRemoving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isActive
                    ? IconButton(
                        icon:
                            const Icon(Icons.link_off, color: Colors.red),
                        onPressed: onRemove,
                        tooltip: 'Remove device',
                      )
                    : const Icon(Icons.link_off, color: Colors.grey),
        isThreeLine: true,
      ),
    );
  }
}
