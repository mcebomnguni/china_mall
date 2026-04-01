import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
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
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
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
      ),
      body: _assignments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 56, color: AppColors.textTertiary),
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
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.courierColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      batch.shortLabel,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.courierColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._assignments.map((a) => PickupCard(
                        assignment: a,
                        onTap: () => context.push('/courier/pickup/${a.id}'),
                      )),
                ],
              ),
            ),
    );
  }
}
