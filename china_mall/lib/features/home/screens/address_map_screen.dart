import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS MODEL
// ─────────────────────────────────────────────────────────────────────────────
 
class SavedAddress {
  final int?   id;
  final String label, fullAddress;
  final double lat, lng;
  final bool   isDefault;
 
  const SavedAddress({
    this.id,
    required this.label,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });
 
  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id:          j['id'],
        label:       j['label'] ?? '',
        fullAddress: j['full_address'] ?? '',
        lat:         double.tryParse(j['lat'].toString()) ?? 0,
        lng:         double.tryParse(j['lng'].toString()) ?? 0,
        isDefault:   j['is_default'] ?? false,
      );
}
 
// ─────────────────────────────────────────────────────────────────────────────
// SAVED ADDRESSES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
 
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});
 
  @override
  State<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}
 
class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<SavedAddress> _addresses = [];
  bool _loading   = true;
  bool _loadError = false;
 
  Future<Map<String, String>> get _headers async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = false; });
    try {
      // Try Supabase first
      try {
        final client = SupabaseService.client;
        final resp = await client
            .from('addresses')
            .select()
            .order('is_default', ascending: false)
            ;
        if (resp != null) {
          final list = (resp as List)
              .map((j) => SavedAddress.fromJson(Map<String, dynamic>.from(j)))
              .toList();
          if (mounted) setState(() => _addresses = list);
          return;
        }
      } catch (_) {}

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/addresses/'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() => _addresses =
              list.map((j) => SavedAddress.fromJson(j)).toList());
        }
      } else {
        if (mounted) setState(() => _loadError = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = true);
        _showError('Could not load addresses. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _delete(SavedAddress address) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Remove "${address.label}" from your saved addresses?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
 
    try {
      try {
        final client = SupabaseService.client;
        await client.from('addresses').delete().eq('id', address.id);
        _load();
        return;
      } catch (_) {}

      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/addresses/${address.id}/'),
        headers: await _headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _load();
      } else if (mounted) {
        _showError('Could not delete address. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Network error. Please try again.');
    }
  }
 
  Future<void> _setDefault(int id) async {
    try {
      try {
        final client = SupabaseService.client;
        await client.from('addresses').update({'is_default': true}).eq('id', id);
        _load();
        return;
      } catch (_) {}

      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/addresses/$id/'),
        headers: await _headers,
        body: jsonEncode({'is_default': true}),
      );
      if (res.statusCode == 200) {
        _load();
      } else if (mounted) {
        _showError('Could not set default. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Network error. Please try again.');
    }
  }
 
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home'))    return CupertinoIcons.house_fill;
    if (l.contains('work'))    return CupertinoIcons.briefcase_fill;
    if (l.contains('partner')) return CupertinoIcons.heart_fill;
    return CupertinoIcons.location_fill;
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Addresses',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const AddAddressScreen()),
          );
          _load();
        },
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.wifi_slash,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not load addresses',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _addresses.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.location_slash,
                              size: 56, color: AppColors.textTertiary),
                          SizedBox(height: 16),
                          Text(
                            'No saved addresses',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (_, i) {
                          final a = _addresses[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: a.isDefault
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.border,
                                width: a.isDefault ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: a.isDefault
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.surfaceVariant,
                                child: Icon(
                                  _iconForLabel(a.label),
                                  color: a.isDefault
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    a.label,
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (a.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                a.fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'default' && a.id != null) {
                                    _setDefault(a.id!);
                                  }
                                  if (v == 'delete') _delete(a);
                                },
                                itemBuilder: (_) => [
                                  if (!a.isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Text('Set as Default'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// ADD ADDRESS SCREEN with Google Maps picker
// ─────────────────────────────────────────────────────────────────────────────
 
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
 
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}
 
class _AddAddressScreenState extends State<AddAddressScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(-26.2041, 28.0473);
  final _addressCtrl = TextEditingController();
  bool _loading  = false;
  bool _locating = false;
  bool _isDefault = false;
 
  static const _labels = ['Home', 'Work', 'Partner', 'Other'];
  String _selectedLabel = 'Home';
 
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
 
  @override
  void dispose() {
    _mapController?.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
 
  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }
 
  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
 
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permanently denied. Open settings to enable it.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
 
      if (permission == LocationPermission.denied) return;
 
      // ignore: deprecated_member_use
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,  // ignore: deprecated_member_use
      );
      final newPos = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _selectedPosition = newPos);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }
 
  Future<void> _save() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a full address.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    setState(() => _loading = true);
    try {
      // Try Supabase insert first
      try {
        final client = SupabaseService.client;
        final userId = client.auth.currentUser?.id;
        await client.from('addresses').insert({
          if (userId != null) 'profile_id': userId,
          'label': _selectedLabel,
          'full_address': _addressCtrl.text.trim(),
          'lat': _selectedPosition.latitude,
          'lng': _selectedPosition.longitude,
          'is_default': _isDefault,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
        return;
      } catch (_) {}

      final token = await AuthService.getAccessToken();
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/addresses/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'label': _selectedLabel,
          'full_address': _addressCtrl.text.trim(),
          'lat': _selectedPosition.latitude,
          'lng': _selectedPosition.longitude,
          'is_default': _isDefault,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error']?.toString() ?? 'Failed to save address.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Add Address',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      body: Column(
        children: [
 
          // ── Map ───────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition,
                    zoom: 15,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: (pos) =>
                      setState(() => _selectedPosition = pos),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPosition,
                      draggable: true,
                      onDragEnd: (pos) =>
                          setState(() => _selectedPosition = pos),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
 
                // Instruction pill
                Positioned(
                  top: 12, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap map or drag pin to set location',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
 
                // GPS button
                Positioned(
                  right: 12, bottom: 12,
                  child: FloatingActionButton.small(
                    backgroundColor: AppColors.black,
                    onPressed: _getCurrentLocation,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(CupertinoIcons.location_fill,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
 
          // ── Form ─────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
 
                  // Label chips
                  Row(
                    children: _labels.map((l) {
                      final selected = _selectedLabel == l;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedLabel = l),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.black
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
 
                  // Address field
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Full Address',
                      hintText: '123 Main Street, Sandton, 2196',
                      prefixIcon: Icon(CupertinoIcons.location, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
 
                  // Coordinates
                  Text(
                    'Pin: ${_selectedPosition.latitude.toStringAsFixed(4)}, '
                    '${_selectedPosition.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
 
                  // Default toggle
                  SwitchListTile.adaptive(
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _isDefault,
                    activeTrackColor: AppColors.black,
                    onChanged: (v) => setState(() => _isDefault = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
 
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Address',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
