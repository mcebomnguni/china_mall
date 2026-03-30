class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String? avatar;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.avatar,
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'buyer',
      avatar: json['avatar'],
      isActive: json['is_active'] ?? true,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get initials {
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    return username[0].toUpperCase();
  }

  bool get isBuyer => role == 'buyer';
  bool get isVendor => role == 'vendor';
  bool get isCourier => role == 'courier';
  bool get isStaff => role == 'staff' || role == 'admin';
}

class Store {
  final int id;
  final String name;
  final String? description;
  final String? logo;
  final String? banner;
  final String status;
  final double? averageRating;
  final int reviewCount;
  final int productCount;
  final String? ownerName;

  Store({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.banner,
    required this.status,
    this.averageRating,
    this.reviewCount = 0,
    this.productCount = 0,
    this.ownerName,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      logo: json['logo'],
      banner: json['banner'],
      status: json['status'] ?? 'pending',
      averageRating: json['average_rating'] != null
          ? (json['average_rating']).toDouble()
          : null,
      reviewCount: json['review_count'] ?? 0,
      productCount: json['product_count'] ?? 0,
      ownerName: json['owner_name'],
    );
  }

  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
}

class Payment {
  final int id;
  final int orderId;
  final String orderNumber;
  final double amount;
  final String status;
  final String? chargeId;
  final String createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.status,
    this.chargeId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      orderId: json['order'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      chargeId: json['charge_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
