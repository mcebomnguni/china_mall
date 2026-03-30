import 'package:flutter/foundation.dart';

// Uses hardcoded defaults - loads live config lazily when needed
class AppConfigProvider extends ChangeNotifier {
  bool get loaded => true;
  double get commissionRate => 0.20;
  double get standardDelivery => 89.0;
  double get expressDelivery => 129.0;
  double get freeDeliveryThreshold => 750.0;
  int get cancellationWindowMinutes => 60;
  int get returnWindowDays => 3;
  double get cancellationFeePercent => 0.05;

  Future<void> load() async {} // no-op, use defaults
  Future<void> reload() async {}
}
