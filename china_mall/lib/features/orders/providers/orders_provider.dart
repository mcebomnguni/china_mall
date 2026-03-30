import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';

class OrdersProvider extends ChangeNotifier {
  List<dynamic> _orders = [];
  List<dynamic> _returns = [];
  List<dynamic> _disputes = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get orders => _orders;
  List<dynamic> get returns => _returns;
  List<dynamic> get disputes => _disputes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await ApiService.getOrders(status: status);
    _loading = false;

    if (res.isSuccess) {
      _orders = res.data as List? ?? [];
    } else {
      _error = res.errorMessage;
    }
    notifyListeners();
  }

  Future<void> loadReturns() async {
    final res = await ApiService.getReturns();
    if (res.isSuccess) {
      _returns = res.data as List? ?? [];
      notifyListeners();
    }
  }

  Future<void> loadDisputes() async {
    final res = await ApiService.getDisputes();
    if (res.isSuccess) {
      _disputes = res.data as List? ?? [];
      notifyListeners();
    }
  }

  Future<Map?> getOrder(int id) async {
    final res = await ApiService.getOrder(id);
    return res.isSuccess ? res.data : null;
  }

  Future<Map?> trackOrder(int id) async {
    final res = await ApiService.trackOrder(id);
    return res.isSuccess ? res.data : null;
  }

  Future<bool> cancelOrder(int id) async {
    final res = await ApiService.cancelOrder(id);
    if (res.isSuccess) {
      await loadOrders();
      return true;
    }
    return false;
  }

  Future<bool> createReturn({
    required int orderId,
    required String reason,
    required String description,
  }) async {
    final res = await ApiService.createReturn({
      'order': orderId,
      'reason': reason,
      'description': description,
    });
    if (res.isSuccess) {
      await loadReturns();
      return true;
    }
    return false;
  }

  Future<bool> createDispute({
    required int orderId,
    required String description,
  }) async {
    final res = await ApiService.createDispute({
      'order': orderId,
      'description': description,
    });
    if (res.isSuccess) {
      await loadDisputes();
      return true;
    }
    return false;
  }
}
