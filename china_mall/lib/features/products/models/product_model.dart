class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final int stockQuantity;
  final String status;
  final double? averageRating;
  final int reviewCount;
  final int? salesCount;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? store;
  final List<dynamic> relatedProducts;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.stockQuantity,
    required this.status,
    this.averageRating,
    this.reviewCount = 0,
    this.salesCount,
    this.category,
    this.store,
    this.relatedProducts = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'],
      stockQuantity: json['stock_quantity'] ?? 0,
      status: json['status'] ?? 'pending',
      averageRating: json['average_rating'] != null
          ? (json['average_rating']).toDouble()
          : null,
      reviewCount: json['review_count'] ?? 0,
      salesCount: json['sales_count'],
      category: json['category'],
      store: json['store'],
      relatedProducts: json['related_products'] ?? [],
    );
  }

  bool get inStock => stockQuantity > 0;
  bool get isApproved => status == 'approved';
}

class Category {
  final int id;
  final String name;
  final String slug;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      productCount: json['product_count'] ?? 0,
    );
  }
}

class ProductReview {
  final int id;
  final String buyerName;
  final double rating;
  final String? comment;
  final String createdAt;

  ProductReview({
    required this.id,
    required this.buyerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? 0,
      buyerName: json['buyer_name'] ?? 'User',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
