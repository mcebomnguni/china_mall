enum DeliveryStatus { inTransit, arriving, delivered }

class DeliveryItem {
  final String productName;
  final int quantity;
  final String storeName;

  const DeliveryItem({
    required this.productName,
    required this.quantity,
    required this.storeName,
  });
}

class DeliveryTask {
  final int id;
  final String customerName;
  final String deliveryAddress;
  final String customerPhone;
  final String orderRef;
  final List<DeliveryItem> items;
  final String deliveryCode;
  DeliveryStatus status;

  DeliveryTask({
    required this.id,
    required this.customerName,
    required this.deliveryAddress,
    required this.customerPhone,
    required this.orderRef,
    required this.items,
    required this.deliveryCode,
    this.status = DeliveryStatus.inTransit,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get itemSummary {
    final byStore = <String, int>{};
    for (final item in items) {
      byStore[item.storeName] = (byStore[item.storeName] ?? 0) + item.quantity;
    }
    return byStore.entries.map((e) => '${e.value} items from ${e.key}').join(', ');
  }

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.arriving:
        return 'Arriving';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }
}

class DeliveryHistoryEntry {
  final DateTime date;
  final String batchWindow;
  final String storeName;
  final int deliveriesCompleted;
  final double earnings;

  const DeliveryHistoryEntry({
    required this.date,
    required this.batchWindow,
    required this.storeName,
    required this.deliveriesCompleted,
    required this.earnings,
  });
}
