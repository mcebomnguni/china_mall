class Product {
  final int id;
  final String name;
  final String description;
  final double price;           // customer price (vendor_price × 1.20)
  final double? vendorPrice;
  final String? image;          // first image URL (backward compat)
  final List<String> images;    // all images, sorted by ordinal
  final int stockQuantity;
  final String status;
  final double? averageRating;
  final int reviewCount;
  final int? salesCount;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? store;
  final List<dynamic> relatedProducts;
  // Enhanced fields
  final List<String> sizes;
  final Map<String, dynamic> dimensions;
  final List<String> colours;
  final String? fabricMaterial;
  final String? productRefId;
  final double? salePrice;
  final bool isOnSale;
  final double discountPercent;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.vendorPrice,
    this.image,
    this.images = const [],
    required this.stockQuantity,
    required this.status,
    this.averageRating,
    this.reviewCount = 0,
    this.salesCount,
    this.category,
    this.store,
    this.relatedProducts = const [],
    this.sizes = const [],
    this.dimensions = const {},
    this.colours = const [],
    this.fabricMaterial,
    this.productRefId,
    this.salePrice,
    this.isOnSale = false,
    this.discountPercent = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract images from product_images join, sorted by ordinal
    List<String> imagesList = [];
    final rawImages = json['product_images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      final sorted = List<Map>.from(rawImages)
        ..sort((a, b) => (a['ordinal'] ?? 0).compareTo(b['ordinal'] ?? 0));
      imagesList = sorted
          .where((e) => e['url'] != null)
          .map((e) => e['url'] as String)
          .toList();
    }
    // Also check pre-mapped list from ApiService
    final preMapped = json['product_image_urls'];
    if (imagesList.isEmpty && preMapped is List) {
      imagesList = preMapped.map((e) => e.toString()).toList();
    }

    // Flatten category from Supabase join
    Map<String, dynamic>? categoryMap = json['category'];
    final catJoin = json['categories'];
    if (categoryMap == null && catJoin is Map) {
      categoryMap = Map<String, dynamic>.from(catJoin);
    }

    // Flatten store from Supabase join
    Map<String, dynamic>? storeMap = json['store'];
    final storeJoin = json['stores'];
    if (storeMap == null && storeJoin is Map) {
      storeMap = Map<String, dynamic>.from(storeJoin);
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      vendorPrice: json['vendor_price'] != null
          ? (json['vendor_price']).toDouble()
          : null,
      image: json['image'] ??
          (imagesList.isNotEmpty ? imagesList.first : null),
      images: imagesList,
      stockQuantity: json['stock_quantity'] ?? json['stock'] ?? 0,
      status: json['status'] ??
          (json['is_active'] == true ? 'approved' : 'pending'),
      averageRating: json['average_rating'] != null
          ? (json['average_rating']).toDouble()
          : null,
      reviewCount: json['review_count'] ?? 0,
      salesCount: json['sales_count'],
      category: categoryMap,
      store: storeMap,
      relatedProducts: json['related_products'] ?? [],
      sizes: _parseStringList(json['sizes']),
      dimensions: json['dimensions'] is Map
          ? Map<String, dynamic>.from(json['dimensions'])
          : {},
      colours: _parseStringList(json['colours']),
      fabricMaterial: json['fabric_material'],
      productRefId: json['product_ref_id'],
      salePrice: json['sale_price'] != null
          ? (json['sale_price']).toDouble()
          : null,
      isOnSale: json['is_on_sale'] ?? false,
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent']).toDouble()
          : 0,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  bool get inStock => stockQuantity > 0;
  bool get isApproved => status == 'approved';
  String? get firstImage => images.isNotEmpty ? images.first : image;
  double get displayPrice =>
      isOnSale && salePrice != null ? salePrice! : price;
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
      name: json['name'] ?? json['label'] ?? '',
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
