import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and notifies listeners on change.
class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);

      Connectivity().onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);
        if (wasOnline != _isOnline) {
          notifyListeners();
        }
      });
    } catch (_) {
      _isOnline = true; // assume online if we can't check
    }
  }

  Future<bool> checkNow() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
      notifyListeners();
      return _isOnline;
    } catch (_) {
      return true;
    }
  }
}
