import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pickup_assignment.dart';
import '../services/courier_mock_data.dart';
import '../widgets/pickup_card.dart';

class PickupAssignmentsScreen extends StatefulWidget {
  const PickupAssignmentsScreen({super.key});

  @override
  State<PickupAssignmentsScreen> createState() =>
      _PickupAssignmentsScreenState();
}

class _PickupAssignmentsScreenState extends State<PickupAssignmentsScreen> {
  late List<PickupAssignment> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = CourierMockData.pickupAssignments;
  }

  @override
  Widget build(BuildContext context) {
    final batch = CourierMockData.currentBatch;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pickup Assignments',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    batch.shortLabel,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(LucideIcons.packageX, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pickups assigned for this batch',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Check back at the next batch window.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: _assignments.length,
              itemBuilder: (context, i) {
                final a = _assignments[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (i * 60)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: PickupCard(
                    assignment: a,
                    onTap: () => context.push('/courier/pickup/${a.id}'),
                  ),
                );
              },
            ),
    );
  }
}
