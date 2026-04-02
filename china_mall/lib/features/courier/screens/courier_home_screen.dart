import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_task.dart';
import '../services/courier_mock_data.dart';
import '../utils/batch_utils.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen>
    with TickerProviderStateMixin {
  bool _isOnline = false;
  Timer? _countdownTimer;
  Duration _timeUntilBatch = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _batchSlideController;
  late Animation<Offset> _batchSlideAnimation;

  late AnimationController _deliverySlideController;
  late Animation<Offset> _deliverySlideAnimation;

  @override
  void initState() {
    super.initState();
    _timeUntilBatch = BatchUtils.timeUntilNextBatch();

    // Pulse animation for online indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Batch card slide-in from left
    _batchSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _batchSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _batchSlideController,
      curve: Curves.easeOut,
    ));

    // Delivery card slide-in from right
    _deliverySlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _deliverySlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _deliverySlideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _batchSlideController.dispose();
    _deliverySlideController.dispose();
    super.dispose();
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _pulseController.repeat(reverse: true);
      _startCountdown();
      _batchSlideController.forward(from: 0.0);
      _deliverySlideController.forward(from: 0.0);
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _countdownTimer?.cancel();
      _batchSlideController.reset();
      _deliverySlideController.reset();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _timeUntilBatch = BatchUtils.timeUntilNextBatch();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeUntilBatch = BatchUtils.timeUntilNextBatch();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeDeliveries = CourierMockData.deliveryTasks
        .where((d) => d.status != DeliveryStatus.delivered)
        .toList();
    final activeCount = activeDeliveries.length;
    final nextDelivery = activeCount > 0 ? activeDeliveries.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
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
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(LucideIcons.repeat2, size: 16),
            label: const Text('Customer'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Go Online Toggle
            _buildOnlineToggle(),
            const SizedBox(height: 6),
            _buildOnlineSubtext(),
            const SizedBox(height: 24),

            // Batch Status Card (only when online)
            if (_isOnline) ...[
              SlideTransition(
                position: _batchSlideAnimation,
                child: _buildBatchStatusCard(),
              ),
              const SizedBox(height: 20),
            ],

            // Stats Row
            _buildStatsRow(),
            const SizedBox(height: 20),

            // Active Delivery Card
            if (_isOnline && activeCount > 0) ...[
              SlideTransition(
                position: _deliverySlideAnimation,
                child: _buildActiveDeliveryCard(
                  activeCount: activeCount,
                  nextDelivery: nextDelivery!,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Quick Actions
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.clipboardList,
                    label: 'Pickup\nAssignments',
                    onTap: () => context.push('/courier/pickups'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.history,
                    label: 'Delivery\nHistory',
                    onTap: () => context.push('/courier/history'),
                  ),
                ),
              ],
            ),

            // Bottom padding for nav bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isOnline ? AppColors.success : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isOnline
                ? AppColors.success
                : AppColors.textTertiary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: _isOnline ? _buildOnlineContent() : _buildOfflineContent(),
      ),
    );
  }

  Widget _buildOfflineContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.power,
          size: 20,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 10),
        Text(
          'GO ONLINE',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineContent() {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.power,
            size: 20,
            color: AppColors.white,
          ),
          const SizedBox(width: 10),
          const Text(
            'ONLINE',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.white.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineSubtext() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isOnline
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "You're offline. Go online to receive pickup assignments.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
    );
  }

  Widget _buildBatchStatusCard() {
    final batchLabel = BatchUtils.getCurrentBatchLabel();
    final batchesComplete = BatchUtils.batchesCompleteForToday;
    final isUrgent = _timeUntilBatch.inMinutes < 30 && !batchesComplete;
    final countdownText = BatchUtils.formatDuration(_timeUntilBatch);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: batchesComplete
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Today's batches complete",
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Next batch: Tomorrow 9:00 AM',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchLabel,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 13,
                          fontWeight:
                              isUrgent ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isUrgent ? AppColors.error : AppColors.textSecondary,
                        ),
                        child: Text('Next pickup in $countdownText'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.package,
            value: CourierMockData.pickupsToday.toDouble(),
            label: 'Pickups',
            isCurrency: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.truck,
            value: CourierMockData.deliveriesToday.toDouble(),
            label: 'Deliveries',
            isCurrency: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.wallet,
            value: CourierMockData.earningsToday,
            label: 'Earnings',
            isCurrency: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryCard({
    required int activeCount,
    required DeliveryTask nextDelivery,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.packageCheck,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have $activeCount packages to deliver',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next: ${nextDelivery.customerName} - ${nextDelivery.suburb}',
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => context.push('/courier/deliveries'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('View Deliveries'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final double value;
  final String label;
  final bool isCurrency;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              String display;
              if (isCurrency) {
                display = 'R${animValue.toInt()}';
              } else {
                display = '${animValue.toInt()}';
              }
              return Text(
                display,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
