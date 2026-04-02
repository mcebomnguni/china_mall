enum DeliveryStatus { inTransit, arriving, delivered }

class DeliveryItem {
  final String productName;
  final int quantity;
  final String storeName;
  final String? size;

  const DeliveryItem({
    required this.productName,
    required this.quantity,
    required this.storeName,
    this.size,
  });
}

class DeliveryTask {
  final int id;
  final String customerFirstName;
  final String customerLastName;
  final String suburb;
  final String fullAddress;
  final String customerPhone;
  final String orderRef;
  final List<DeliveryItem> items;
  final String deliveryCode;
  DeliveryStatus status;
  String? lastETA;
  DateTime? etaSentAt;
  bool addressRevealed;

  DeliveryTask({
    required this.id,
    required this.customerFirstName,
    required this.customerLastName,
    required this.suburb,
    required this.fullAddress,
    required this.customerPhone,
    required this.orderRef,
    required this.items,
    required this.deliveryCode,
    this.status = DeliveryStatus.inTransit,
    this.lastETA,
    this.etaSentAt,
    this.addressRevealed = false,
  });

  String get customerName => '$customerFirstName ${customerLastName[0]}.';
  String get customerFullName => '$customerFirstName $customerLastName';

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

  String? get etaAgoText {
    if (etaSentAt == null || lastETA == null) return null;
    final diff = DateTime.now().difference(etaSentAt!);
    if (diff.inMinutes < 1) return 'ETA sent: $lastETA just now';
    if (diff.inMinutes < 60) return 'ETA sent: $lastETA ${diff.inMinutes} min ago';
    return 'ETA sent: $lastETA ${diff.inHours}h ago';
  }
}

class DeliveryHistoryEntry {
  final DateTime date;
  final String batchWindow;
  final List<String> stores;
  final int deliveriesCompleted;
  final double earnings;

  const DeliveryHistoryEntry({
    required this.date,
    required this.batchWindow,
    required this.stores,
    required this.deliveriesCompleted,
    required this.earnings,
  });
}

class CourierEarnings {
  final double thisWeek;
  final int deliveriesThisWeek;
  final DateTime nextPayoutDate;
  final double estimatedPayout;
  final String bankName;
  final String bankAccountLast4;
  final List<PayoutEntry> payoutHistory;

  const CourierEarnings({
    required this.thisWeek,
    required this.deliveriesThisWeek,
    required this.nextPayoutDate,
    required this.estimatedPayout,
    required this.bankName,
    required this.bankAccountLast4,
    required this.payoutHistory,
  });
}

class PayoutEntry {
  final String period;
  final double amount;
  final PayoutStatus status;

  const PayoutEntry({
    required this.period,
    required this.amount,
    required this.status,
  });
}

enum PayoutStatus { paid, pending }
