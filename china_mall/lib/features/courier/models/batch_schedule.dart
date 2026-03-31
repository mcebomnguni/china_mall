enum BatchWindow { morning, afternoon }

class BatchSchedule {
  final BatchWindow window;
  final DateTime cutoffTime;
  final DateTime batchTime;

  const BatchSchedule({
    required this.window,
    required this.cutoffTime,
    required this.batchTime,
  });

  String get label {
    switch (window) {
      case BatchWindow.morning:
        return 'Morning Batch \u2014 9:00 AM';
      case BatchWindow.afternoon:
        return 'Afternoon Batch \u2014 3:00 PM';
    }
  }

  String get shortLabel {
    switch (window) {
      case BatchWindow.morning:
        return '9:00 AM Batch';
      case BatchWindow.afternoon:
        return '3:00 PM Batch';
    }
  }

  Duration get timeUntilBatch => batchTime.difference(DateTime.now());
  bool get isUrgent => timeUntilBatch.inMinutes < 30 && !timeUntilBatch.isNegative;
  bool get isPast => timeUntilBatch.isNegative;

  static BatchSchedule current() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 9);
    final afternoon = DateTime(now.year, now.month, now.day, 15);

    if (now.isBefore(morning)) {
      return BatchSchedule(
        window: BatchWindow.morning,
        cutoffTime: DateTime(now.year, now.month, now.day, 8, 30),
        batchTime: morning,
      );
    } else if (now.isBefore(afternoon)) {
      return BatchSchedule(
        window: BatchWindow.afternoon,
        cutoffTime: DateTime(now.year, now.month, now.day, 14, 30),
        batchTime: afternoon,
      );
    } else {
      // After 3 PM — show next morning
      final tomorrow = now.add(const Duration(days: 1));
      return BatchSchedule(
        window: BatchWindow.morning,
        cutoffTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 30),
        batchTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      );
    }
  }
}
