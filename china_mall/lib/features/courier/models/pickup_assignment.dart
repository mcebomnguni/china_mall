enum PickupStatus { pending, enRoute, atStore, pickedUp }

class PickupOrderItem {
  final int id;
  final String productName;
  final int quantity;
  final String? sizeOrColor;
  final String orderRef;
  final double price;
  bool isVerified;
  bool isMissing;
  String? missingNote;

  PickupOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.sizeOrColor,
    required this.orderRef,
    required this.price,
    this.isVerified = false,
    this.isMissing = false,
    this.missingNote,
  });
}

class PickupAssignment {
  final int id;
  final String storeName;
  final String storeLocation;
  final String storePhone;
  final List<PickupOrderItem> items;
  final List<String> orderRefs;
  final String pickupCode;
  PickupStatus status;

  PickupAssignment({
    required this.id,
    required this.storeName,
    required this.storeLocation,
    required this.storePhone,
    required this.items,
    required this.orderRefs,
    required this.pickupCode,
    this.status = PickupStatus.pending,
  });

  int get totalItems => items.length;
  int get verifiedCount => items.where((i) => i.isVerified || i.isMissing).length;
  bool get allVerified => verifiedCount == totalItems;
  int get orderCount => orderRefs.length;

  String get statusLabel {
    switch (status) {
      case PickupStatus.pending:
        return 'Pending';
      case PickupStatus.enRoute:
        return 'En Route';
      case PickupStatus.atStore:
        return 'At Store';
      case PickupStatus.pickedUp:
        return 'Picked Up';
    }
  }
}
