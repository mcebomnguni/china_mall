class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final double subtotal;
  final double deliveryFee;
  final String deliveryMethod;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryProvince;
  final String deliveryPostalCode;
  final String? buyerNotes;
  final String createdAt;
  final String? cancellationDeadline;
  final List<dynamic> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryMethod,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryProvince,
    required this.deliveryPostalCode,
    this.buyerNotes,
    required this.createdAt,
    this.cancellationDeadline,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '#${json['id']}',
      status: json['status'] ?? 'pending_payment',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      deliveryMethod: json['delivery_method'] ?? 'standard',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryCity: json['delivery_city'] ?? '',
      deliveryProvince: json['delivery_province'] ?? '',
      deliveryPostalCode: json['delivery_postal_code'] ?? '',
      buyerNotes: json['buyer_notes'],
      createdAt: json['created_at'] ?? '',
      cancellationDeadline: json['cancellation_deadline'],
      items: json['items'] ?? [],
    );
  }

  bool get canCancel =>
      status == 'pending_payment' || status == 'payment_confirmed';
  bool get canTrack =>
      ['in_transit', 'out_for_delivery', 'picked_up', 'awaiting_pickup']
          .contains(status);
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

class OrderItem {
  final int id;
  final Map<String, dynamic>? product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      product: json['product'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }
}

class ReturnRequest {
  final int id;
  final int orderId;
  final String reason;
  final String description;
  final String status;
  final String createdAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] ?? 0,
      orderId: json['order'] ?? 0,
      reason: json['reason'] ?? 'other',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Dispute {
  final int id;
  final int orderId;
  final String description;
  final String status;
  final String createdAt;

  Dispute({
    required this.id,
    required this.orderId,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] ?? 0,
      orderId: json['order'] ?? 0,
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
    );
  }
}
