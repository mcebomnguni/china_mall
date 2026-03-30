import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});
 
  @override
  State<CourierDashboardScreen> createState() =>
      _CourierDashboardScreenState();
}
 
class _CourierDashboardScreenState extends State<CourierDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map? _profile;
  Map? _earnings;
  List _activeJobs = [];
  bool _loading = true;
  bool _togglingAvailability = false;
  late TabController _tabCtrl;
 
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }
 
  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getCourierProfile(),
        ApiService.getCourierJobs(),
        ApiService.getCourierEarnings(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile    = results[0].isSuccess ? results[0].data : null;
        _activeJobs = results[1].isSuccess ? (results[1].data as List? ?? []) : [];
        _earnings   = results[2].isSuccess ? results[2].data : null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load dashboard. Check your connection.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _toggleAvailability() async {
    if (_profile == null) return;
    setState(() => _togglingAvailability = true);
    final isOnline = _profile!['is_online'] ?? false;
    await ApiService.toggleAvailability(!isOnline);
    await _load();
    setState(() => _togglingAvailability = false);
  }
 
  Future<void> _updateJobStatus(int jobId, String status) async {
    await ApiService.updateDeliveryStatus(jobId, status);
    _load();
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
 
    final isOnline = _profile?['is_online'] ?? false;
 
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Courier Dashboard',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.textPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Online/Offline toggle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
                      : AppColors.gradientDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'You\'re Online' : 'You\'re Offline',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            isOnline
                                ? 'Ready to receive delivery jobs'
                                : 'Toggle to start accepting deliveries',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _togglingAvailability
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Switch(
                            value: isOnline,
                            onChanged: (_) => _toggleAvailability(),
                            activeThumbColor: Colors.white,
                            activeTrackColor:
                                Colors.white.withValues(alpha: 0.3),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
 
              // Earnings summary
              if (_earnings != null)
                Row(
                  children: [
                    Expanded(
                      child: _EarningsCard(
                        label: 'Today',
                        amount:
                            (_earnings!['today'] ?? 0).toDouble(),
                        icon: CupertinoIcons.sun_max_fill,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EarningsCard(
                        label: 'This Week',
                        amount:
                            (_earnings!['this_week'] ?? 0).toDouble(),
                        icon: CupertinoIcons.calendar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EarningsCard(
                        label: 'Total',
                        amount:
                            (_earnings!['total'] ?? 0).toDouble(),
                        icon: CupertinoIcons.money_dollar_circle_fill,
                      ),
                    ),
                  ],
                ),
 
              const SizedBox(height: 24),
 
              // Jobs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Jobs (${_activeJobs.length})',
                      style:
                          Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 12),
 
              if (_activeJobs.isEmpty)
                EmptyState(
                  icon: CupertinoIcons.car,
                  title: 'No active jobs',
                  subtitle: isOnline
                      ? 'Waiting for delivery assignments...'
                      : 'Go online to receive jobs',
                )
              else
                ..._activeJobs.map((job) => _JobCard(
                      job: job,
                      onUpdateStatus: (status) =>
                          _updateJobStatus(job['id'], status),
                    )),
 
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
 
class _EarningsCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
 
  const _EarningsCard(
      {required this.label, required this.amount, required this.icon});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            'R ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 11,
                  color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
 
class _JobCard extends StatelessWidget {
  final Map job;
  final void Function(String) onUpdateStatus;
 
  const _JobCard({required this.job, required this.onUpdateStatus});
 
  static const _nextStatus = {
    'assigned': 'accepted',
    'accepted': 'heading_to_pickup',
    'heading_to_pickup': 'at_pickup',
    'at_pickup': 'picked_up',
    'picked_up': 'heading_to_delivery',
    'heading_to_delivery': 'at_delivery',
    'at_delivery': 'delivered',
  };
 
  static const _nextLabel = {
    'assigned': 'Accept Job',
    'accepted': 'Head to Pickup',
    'heading_to_pickup': 'At Pickup Point',
    'at_pickup': 'Mark Picked Up',
    'picked_up': 'Head to Delivery',
    'heading_to_delivery': 'At Delivery',
    'at_delivery': 'Mark Delivered',
  };
 
  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? '';
    final next = _nextStatus[status];
    final label = _nextLabel[status];
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Delivery #${job['id']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          if (job['delivery_address'] != null)
            Row(
              children: [
                const Icon(CupertinoIcons.location_fill,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(job['delivery_address'],
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          if (job['fee'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Fee: R ${(job['fee'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.success,
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: label ?? 'Update Status',
              onTap: () => onUpdateStatus(next),
            ),
          ],
        ],
      ),
    );
  }
}