import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pickup_assignment.dart';

class PickupCard extends StatelessWidget {
  final PickupAssignment assignment;
  final VoidCallback onTap;

  const PickupCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  Color _statusColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.pending:
        return AppColors.textTertiary;
      case PickupStatus.enRoute:
        return AppColors.warning;
      case PickupStatus.atStore:
        return AppColors.info;
      case PickupStatus.pickedUp:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(assignment.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.storeName,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignment.storeLocation,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    assignment.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '${assignment.orderCount} orders (${assignment.totalItems} items)',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: assignment.orderRefs.map((ref) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
