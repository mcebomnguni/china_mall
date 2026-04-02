import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_task.dart';
import '../services/courier_mock_data.dart';
import '../utils/batch_utils.dart';

class ActiveDeliveriesScreen extends StatefulWidget {
  const ActiveDeliveriesScreen({super.key});

  @override
  State<ActiveDeliveriesScreen> createState() => _ActiveDeliveriesScreenState();
}

class _ActiveDeliveriesScreenState extends State<ActiveDeliveriesScreen>
    with TickerProviderStateMixin {
  late List<DeliveryTask> _tasks;
  late AnimationController _staggerController;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _tasks = CourierMockData.deliveryTasks;

    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (_tasks.length * 60)),
    );

    for (int i = 0; i < _tasks.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _cardControllers.add(controller);

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ),
      );
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ),
      );
    }

    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) _cardControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _activeCount =>
      _tasks.where((t) => t.status != DeliveryStatus.delivered).length;

  void _showETASheet(DeliveryTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ETABottomSheet(
        task: task,
        onETASelected: (eta) {
          setState(() {
            task.lastETA = eta;
            task.etaSentAt = DateTime.now();
          });
          debugPrint(
            '[PUSH NOTIFICATION] To ${task.customerName}: '
            'Your China Stall delivery is estimated to arrive in $eta.',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'ETA sent to ${task.customerName}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _startDelivery(DeliveryTask task) async {
    setState(() {
      task.addressRevealed = true;
      task.status = DeliveryStatus.arriving;
    });

    final encodedAddress = Uri.encodeComponent(task.fullAddress);
    final mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _completeDelivery(DeliveryTask task) {
    context.push('/courier/deliver/${task.id}');
  }

  @override
  Widget build(BuildContext context) {
    final showAfternoonWarning = BatchUtils.isAfterAfternoonCutoff() &&
        _tasks.any((t) =>
            t.status == DeliveryStatus.inTransit && !t.addressRevealed);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Active Deliveries',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_activeCount',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _tasks.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                children: [
                  if (showAfternoonWarning) ...[
                    _buildAfternoonWarning(),
                    const SizedBox(height: 12),
                  ],
                  ..._tasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;

                    if (index >= _fadeAnimations.length) {
                      return _buildDeliveryCard(task);
                    }

                    return FadeTransition(
                      opacity: _fadeAnimations[index],
                      child: SlideTransition(
                        position: _slideAnimations[index],
                        child: _buildDeliveryCard(task),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.packageX, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No active deliveries',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick up items first to start delivering',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfternoonWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'It\'s past 3 PM. Remaining deliveries may need to be rescheduled for tomorrow morning.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.warning.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryTask task) {
    final isArriving = task.status == DeliveryStatus.arriving;
    final isDelivered = task.status == DeliveryStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: customer name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          task.customerName,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(task.status),
              ],
            ),
            const SizedBox(height: 10),

            // Location
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    task.addressRevealed ? task.fullAddress : task.suburb,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Items summary
            Text(
              task.itemSummary,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),

            // Order ref
            Text(
              task.orderRef,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),

            // ETA sent text
            if (task.etaAgoText != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 13, color: AppColors.success),
                  const SizedBox(width: 5),
                  Text(
                    task.etaAgoText!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Action buttons
            if (!isDelivered)
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Update ETA',
                      icon: LucideIcons.timer,
                      filled: false,
                      onTap: () => _showETASheet(task),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: isArriving ? 'Complete Delivery' : 'Start Delivery',
                      icon: isArriving ? LucideIcons.checkCircle : LucideIcons.navigation,
                      filled: true,
                      onTap: () {
                        if (isArriving) {
                          _completeDelivery(task);
                        } else {
                          _startDelivery(task);
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case DeliveryStatus.inTransit:
        bgColor = AppColors.warning.withValues(alpha: 0.12);
        textColor = AppColors.warning;
        label = 'In Transit';
        break;
      case DeliveryStatus.arriving:
        bgColor = AppColors.info.withValues(alpha: 0.12);
        textColor = AppColors.info;
        label = 'Arriving';
        break;
      case DeliveryStatus.delivered:
        bgColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        label = 'Delivered';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: filled ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ETA Bottom Sheet ───────────────────────────────────────────────────────

class _ETABottomSheet extends StatefulWidget {
  final DeliveryTask task;
  final ValueChanged<String> onETASelected;

  const _ETABottomSheet({
    required this.task,
    required this.onETASelected,
  });

  @override
  State<_ETABottomSheet> createState() => _ETABottomSheetState();
}

class _ETABottomSheetState extends State<_ETABottomSheet> {
  String? _flashedETA;

  static const _etaOptions = [
    '10 min',
    '15 min',
    '30 min',
    '1 hour',
    '2 hours',
    '3 hours',
  ];

  void _selectETA(String eta) async {
    setState(() => _flashedETA = eta);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      Navigator.of(context).pop();
      widget.onETASelected(eta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'How far are you from ${widget.task.customerName}?',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your estimated arrival time',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 3x2 grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: _etaOptions.map((eta) {
                final isLastSent = widget.task.lastETA == eta;
                final isFlashed = _flashedETA == eta;

                return GestureDetector(
                  onTap: () => _selectETA(eta),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 64,
                    decoration: BoxDecoration(
                      color: isFlashed
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLastSent
                            ? AppColors.primary
                            : isFlashed
                                ? AppColors.primary
                                : AppColors.border,
                        width: isLastSent ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 18,
                          color: isLastSent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eta,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLastSent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isLastSent) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Last sent',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
