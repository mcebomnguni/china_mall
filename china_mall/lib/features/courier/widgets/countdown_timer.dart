import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/batch_schedule.dart';

class CountdownTimer extends StatefulWidget {
  final BatchSchedule batch;

  const CountdownTimer({super.key, required this.batch});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remaining = widget.batch.timeUntilBatch;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.batch.timeUntilBatch;
      });
      if (widget.batch.isUrgent && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    });

    if (widget.batch.isUrgent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.batch.isUrgent;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isUrgent ? 1.0 + (_pulseController.value * 0.04) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUrgent
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: isUrgent ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_remaining),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isUrgent ? AppColors.error : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
