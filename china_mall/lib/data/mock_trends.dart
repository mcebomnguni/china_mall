import 'package:flutter/material.dart';
import '../constants/product_images.dart';

// ─── Models ────────────────────────────────────────────────────────────────

class TrendCollection {
  final String hashtag;
  final String title;
  final bool isNew;
  final int countdownDays;
  final String heroImage;
  final List<TrendProduct> featuredProducts;

  const TrendCollection({
    required this.hashtag,
    required this.title,
    required this.isNew,
    required this.countdownDays,
    required this.heroImage,
    required this.featuredProducts,
  });
}

class TrendProduct {
  final String name;
  final double price;
  final String store;
  final String image;

  const TrendProduct({
    required this.name,
    required this.price,
    required this.store,
    required this.image,
  });
}

class TrendingProduct {
  final String brandName;
  final String hashtag;
  final int discount;
  final int hoursLeft;
  final String name;
  final double price;
  final double? originalPrice;
  final String image;
  final List<Color> colorVariants;

  const TrendingProduct({
    required this.brandName,
    required this.hashtag,
    required this.discount,
    required this.hoursLeft,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.image,
    required this.colorVariants,
  });
}

class MockStoreDetail {
  final int id;
  final String name;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String description;
  final int followers;
  final int productCount;
  final int positiveRate;
  final String bannerImage;

  const MockStoreDetail({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.description,
    required this.followers,
    required this.productCount,
    required this.positiveRate,
    required this.bannerImage,
  });
}

// ─── Mock Data ─────────────────────────────────────────────────────────────

final trendingCollections = [
  TrendCollection(
    hashtag: '#RedDragonCollection',
    title: 'Ignite Your Style with Scarlet Fire!',
    isNew: true,
    countdownDays: 7,
    heroImage: ProductImages.trendsRedCollection,
    featuredProducts: [
      TrendProduct(name: 'Silk Red Blouse', price: 109, store: 'China Dragon', image: ProductImages.redDress),
      TrendProduct(name: 'Dragon Midi Dress', price: 156, store: 'Store Belle', image: ProductImages.floralDress),
      TrendProduct(name: 'Scarlet Wrap Dress', price: 185, store: 'China Stores', image: ProductImages.summerDress),
    ],
  ),
  TrendCollection(
    hashtag: '#WinterEssentials',
    title: 'Stay Warm, Stay Stylish',
    isNew: false,
    countdownDays: 14,
    heroImage: ProductImages.trendsHero,
    featuredProducts: [
      TrendProduct(name: 'Wool Coat', price: 299, store: 'Fashion Hub', image: ProductImages.winterCoat),
      TrendProduct(name: 'Leather Boots', price: 249, store: 'Urban Edge', image: ProductImages.boots),
      TrendProduct(name: 'Knit Sweater', price: 169, store: 'Plaza Styles', image: ProductImages.greenKnit),
    ],
  ),
  TrendCollection(
    hashtag: '#StreetVibes',
    title: 'Urban Streetwear Drop',
    isNew: true,
    countdownDays: 3,
    heroImage: ProductImages.storeDragonFashion,
    featuredProducts: [
      TrendProduct(name: 'Black Hoodie', price: 189, store: 'Street Wear Co', image: ProductImages.menHoodie),
      TrendProduct(name: 'Retro Sneakers', price: 349, store: 'Urban Edge', image: ProductImages.sneakersBlack),
      TrendProduct(name: 'Denim Jacket', price: 279, store: 'Dragon Fashion', image: ProductImages.menJacket),
    ],
  ),
];

const trendHashtags = [
  'For You',
  '#NewArrivals',
  '#StreetStyle',
  '#WinterFashion',
  '#ElegantEdit',
  '#RedDragon',
];

final trendingProducts = [
  TrendingProduct(
    brandName: 'Siren Gaze',
    hashtag: '#SummerOutfit',
    discount: -32,
    hoursLeft: 11,
    name: "Siren Gaze Women's Wrap Dress",
    price: 169,
    originalPrice: 249,
    image: ProductImages.blackDress,
    colorVariants: [Colors.red, Colors.black, const Color(0xFFF5F0EB)],
  ),
  TrendingProduct(
    brandName: 'Dragon Fashion',
    hashtag: '#StreetStyle',
    discount: -25,
    hoursLeft: 8,
    name: 'Premium Faux Leather Jacket',
    price: 349,
    originalPrice: 465,
    image: ProductImages.leatherJacket,
    colorVariants: [Colors.black, Colors.brown, Colors.grey],
  ),
  TrendingProduct(
    brandName: 'Fashion Hub',
    hashtag: '#NewArrivals',
    discount: -15,
    hoursLeft: 23,
    name: 'Elegant Floral Midi Dress',
    price: 199,
    originalPrice: 234,
    image: ProductImages.floralDress,
    colorVariants: [Colors.pink, Colors.white, Colors.teal],
  ),
  TrendingProduct(
    brandName: 'Urban Edge',
    hashtag: '#WinterFashion',
    discount: -40,
    hoursLeft: 5,
    name: 'Classic Winter Coat',
    price: 299,
    originalPrice: 499,
    image: ProductImages.winterCoat,
    colorVariants: [Colors.grey, Colors.black, const Color(0xFF8B4513)],
  ),
  TrendingProduct(
    brandName: 'Plaza Styles',
    hashtag: '#ElegantEdit',
    discount: -20,
    hoursLeft: 16,
    name: 'Silk Blouse Collection',
    price: 149,
    originalPrice: 186,
    image: ProductImages.whiteBlouse,
    colorVariants: [Colors.white, Colors.pink, const Color(0xFFD4A843)],
  ),
  TrendingProduct(
    brandName: 'Street Wear Co',
    hashtag: '#StreetStyle',
    discount: -30,
    hoursLeft: 9,
    name: 'Premium Black Hoodie',
    price: 189,
    originalPrice: 270,
    image: ProductImages.menHoodie,
    colorVariants: [Colors.black, Colors.grey, Colors.white],
  ),
  TrendingProduct(
    brandName: 'Classic Threads',
    hashtag: '#NewArrivals',
    discount: -18,
    hoursLeft: 20,
    name: 'Red Evening Dress',
    price: 259,
    originalPrice: 316,
    image: ProductImages.redDress,
    colorVariants: [Colors.red, Colors.black, const Color(0xFF4A0E0E)],
  ),
  TrendingProduct(
    brandName: 'Fashion Hub',
    hashtag: '#SummerOutfit',
    discount: -22,
    hoursLeft: 14,
    name: 'Summer Maxi Dress',
    price: 179,
    originalPrice: 230,
    image: ProductImages.summerDress,
    colorVariants: [const Color(0xFFF5F0EB), Colors.blue, Colors.pink],
  ),
  TrendingProduct(
    brandName: 'Urban Edge',
    hashtag: '#StreetStyle',
    discount: -35,
    hoursLeft: 3,
    name: 'Retro Running Sneakers',
    price: 349,
    originalPrice: 537,
    image: ProductImages.sneakersBlack,
    colorVariants: [Colors.red, Colors.black, Colors.white],
  ),
  TrendingProduct(
    brandName: 'Dragon Fashion',
    hashtag: '#WinterFashion',
    discount: -28,
    hoursLeft: 7,
    name: 'Men Bomber Jacket',
    price: 279,
    originalPrice: 388,
    image: ProductImages.menJacket,
    colorVariants: [Colors.green, Colors.black, Colors.grey],
  ),
  TrendingProduct(
    brandName: 'Plaza Styles',
    hashtag: '#ElegantEdit',
    discount: -15,
    hoursLeft: 19,
    name: 'Knit Turtleneck Sweater',
    price: 169,
    originalPrice: 199,
    image: ProductImages.greenKnit,
    colorVariants: [Colors.green, Colors.grey, Colors.white],
  ),
  TrendingProduct(
    brandName: 'Siren Gaze',
    hashtag: '#NewArrivals',
    discount: -20,
    hoursLeft: 12,
    name: 'Pink Satin Blouse',
    price: 139,
    originalPrice: 174,
    image: ProductImages.pinkTop,
    colorVariants: [Colors.pink, Colors.white, const Color(0xFFD4A843)],
  ),
  TrendingProduct(
    brandName: 'Classic Threads',
    hashtag: '#SummerOutfit',
    discount: -10,
    hoursLeft: 48,
    name: 'Denim Slim Jeans',
    price: 219,
    originalPrice: 243,
    image: ProductImages.denimJeans,
    colorVariants: [Colors.blue, Colors.black, Colors.grey],
  ),
  TrendingProduct(
    brandName: 'Fashion Hub',
    hashtag: '#ElegantEdit',
    discount: -25,
    hoursLeft: 6,
    name: 'Gold Statement Necklace',
    price: 89,
    originalPrice: 119,
    image: ProductImages.goldJewelry,
    colorVariants: [const Color(0xFFD4A843), Colors.grey, Colors.white],
  ),
  TrendingProduct(
    brandName: 'Urban Edge',
    hashtag: '#StreetStyle',
    discount: -30,
    hoursLeft: 10,
    name: 'Leather Crossbody Bag',
    price: 199,
    originalPrice: 284,
    image: ProductImages.handbag,
    colorVariants: [Colors.brown, Colors.black, const Color(0xFF8B4513)],
  ),
  TrendingProduct(
    brandName: 'Street Wear Co',
    hashtag: '#NewArrivals',
    discount: -12,
    hoursLeft: 30,
    name: 'White Canvas Sneakers',
    price: 249,
    originalPrice: 283,
    image: ProductImages.sneakersWhite,
    colorVariants: [Colors.white, Colors.black, Colors.grey],
  ),
];

final mockStores = [
  MockStoreDetail(
    id: 1,
    name: 'Fashion Hub',
    location: 'Shop 247, Ground Floor - Oriental Plaza, Fordsburg',
    rating: 4.8,
    reviewCount: 324,
    isVerified: true,
    description: 'Premium fashion, accessories and leather goods. Established 2019.',
    followers: 1200,
    productCount: 486,
    positiveRate: 98,
    bannerImage: ProductImages.storeFashionHub,
  ),
  MockStoreDetail(
    id: 2,
    name: 'Dragon Fashion',
    location: 'Shop 112, First Floor - China Mall, Crown Mines',
    rating: 4.6,
    reviewCount: 198,
    isVerified: true,
    description: 'Trendy streetwear and casual fashion for men and women.',
    followers: 890,
    productCount: 312,
    positiveRate: 95,
    bannerImage: ProductImages.storeDragonFashion,
  ),
  MockStoreDetail(
    id: 3,
    name: 'Plaza Styles',
    location: 'Shop 56, Ground Floor - China Mall, Crown Mines',
    rating: 4.5,
    reviewCount: 156,
    isVerified: true,
    description: 'Elegant women\'s fashion and beauty products.',
    followers: 670,
    productCount: 245,
    positiveRate: 94,
    bannerImage: ProductImages.storePlazaStyles,
  ),
  MockStoreDetail(
    id: 4,
    name: 'Urban Edge',
    location: 'Shop 89, Second Floor - Oriental Plaza, Fordsburg',
    rating: 4.7,
    reviewCount: 267,
    isVerified: true,
    description: 'Cutting-edge streetwear, sneakers and urban fashion.',
    followers: 1050,
    productCount: 398,
    positiveRate: 97,
    bannerImage: ProductImages.storeUrbanEdge,
  ),
  MockStoreDetail(
    id: 5,
    name: 'Classic Threads',
    location: 'Shop 33, Ground Floor - China Mall, Crown Mines',
    rating: 4.4,
    reviewCount: 142,
    isVerified: false,
    description: 'Timeless fashion pieces for men and women. Quality at great prices.',
    followers: 540,
    productCount: 189,
    positiveRate: 92,
    bannerImage: ProductImages.storeFashionHub,
  ),
  MockStoreDetail(
    id: 6,
    name: 'Street Wear Co',
    location: 'Shop 201, First Floor - Oriental Plaza, Fordsburg',
    rating: 4.3,
    reviewCount: 98,
    isVerified: false,
    description: 'Bold streetwear, hoodies, sneakers and accessories.',
    followers: 380,
    productCount: 156,
    positiveRate: 91,
    bannerImage: ProductImages.storeDragonFashion,
  ),
];

// Mock featured products for the home screen
final mockFeaturedProducts = [
  {'id': 1, 'name': 'Premium Faux Leather Jacket', 'price': 349.0, 'image': ProductImages.leatherJacket, 'discount': 20},
  {'id': 2, 'name': 'Men\'s Polo Shirt', 'price': 149.0, 'image': ProductImages.menPoloShirt, 'discount': 0},
  {'id': 3, 'name': 'Classic Winter Coat', 'price': 299.0, 'image': ProductImages.winterCoat, 'discount': 15},
  {'id': 4, 'name': 'Knit Turtleneck', 'price': 169.0, 'image': ProductImages.greenKnit, 'discount': 0},
  {'id': 5, 'name': 'White Blouse', 'price': 129.0, 'image': ProductImages.whiteBlouse, 'discount': 10},
];

final mockTrendingProducts = [
  {'id': 6, 'name': 'Floral Midi Dress', 'price': 199.0, 'image': ProductImages.floralDress, 'discount': 25},
  {'id': 7, 'name': 'Red Evening Dress', 'price': 259.0, 'image': ProductImages.redDress, 'discount': 30},
  {'id': 8, 'name': 'Summer Maxi Dress', 'price': 179.0, 'image': ProductImages.summerDress, 'discount': 0},
  {'id': 9, 'name': 'Classic Sneakers', 'price': 349.0, 'image': ProductImages.sneakersWhite, 'discount': 20},
  {'id': 10, 'name': 'Leather Handbag', 'price': 199.0, 'image': ProductImages.handbag, 'discount': 15},
];
