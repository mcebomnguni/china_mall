import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/batch_schedule.dart';
import 'countdown_timer.dart';

class BatchStatusCard extends StatelessWidget {
  final BatchSchedule batch;

  const BatchStatusCard({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCourier,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.courierColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                batch.label,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CountdownTimer(batch: batch),
          const SizedBox(height: 8),
          Text(
            batch.isPast
                ? 'Batch has started'
                : 'Time until next batch',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
