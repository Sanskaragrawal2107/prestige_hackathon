class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountedPrice;
  final bool inStock;
  final String imageUrl;
  final String category;
  final String? brand;
  final double? rating;
  final String createdAt;
  final double discountPercentage;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    this.inStock = true,
    required this.imageUrl,
    required this.createdAt,
    required this.stock,
    this.category = '',
    this.brand,
    this.rating,
    this.discountPercentage = 0,
  });

  double get effectivePrice {
    return discountedPrice ?? price;
  }

  double get savingsAmount {
    return price - effectivePrice;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle different numeric types from the database
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.parse(value.toString());
    }

    final price = parseDouble(json['price']);
    final discountedPrice = json['discounted_price'] != null
        ? parseDouble(json['discounted_price'])
        : null;
        
    // Calculate discount percentage if we have a discounted price
    final discountPercentage = (discountedPrice != null && price > 0)
        ? ((price - discountedPrice) / price * 100)
        : 0.0;

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unnamed Product',
      description: json['description'] ?? '',
      price: price,
      discountedPrice: discountedPrice,
      inStock: json['in_stock'] ?? true,
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      category: json['category'] ?? '',
      brand: json['brand'],
      rating: json['rating'] != null ? parseDouble(json['rating']) : null,
      discountPercentage: discountPercentage,
      stock: json['in_stock'] == true ? 10 : 0, // Default to 10 if in stock
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discounted_price': discountedPrice,
      'in_stock': inStock,
      'image_url': imageUrl,
      'created_at': createdAt,
      'category': category,
      'brand': brand,
      'rating': rating,
    };
  }
} 