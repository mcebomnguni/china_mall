/// Post-3pm cutoff logic and batch scheduling utilities.
class BatchUtils {
  BatchUtils._();

  static bool isAfterAfternoonCutoff() {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 15, 0);
    return now.isAfter(cutoff);
  }

  static String getCurrentBatchLabel() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 9, 0);
    final afternoon = DateTime(now.year, now.month, now.day, 15, 0);

    if (now.isBefore(morning)) return 'Morning Batch \u2014 9:00 AM';
    if (now.isBefore(afternoon)) return 'Afternoon Batch \u2014 3:00 PM';
    return 'Batches complete for today';
  }

  static Duration timeUntilNextBatch() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 9, 0);
    final afternoon = DateTime(now.year, now.month, now.day, 15, 0);
    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 9, 0);

    if (now.isBefore(morning)) return morning.difference(now);
    if (now.isBefore(afternoon)) return afternoon.difference(now);
    return tomorrowMorning.difference(now);
  }

  static bool get batchesCompleteForToday => isAfterAfternoonCutoff();

  static String customerNotificationText({required bool isAfterCutoff}) {
    if (isAfterCutoff) {
      return 'Your package has been picked up. Delivery is scheduled for tomorrow morning.';
    }
    return 'Your package has been picked up! Expected delivery within the next few hours.';
  }

  static String formatDuration(Duration d) {
    if (d.isNegative) return '0m';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
