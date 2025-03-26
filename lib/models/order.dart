import 'product.dart';

class OrderItem {
  final String productId;
  final double price;
  final int quantity;
  final Product product;

  OrderItem({
    required this.productId,
    required this.price,
    required this.quantity,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      product: Product.fromJson(json['product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'product': product.toJson(),
    };
  }

  double get total => price * quantity;
}

class ShippingAddress {
  final String name;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String? phone;

  ShippingAddress({
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name'],
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
      country: json['country'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'phone': phone,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String? paymentId;
  final String createdAt;
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double discount;
  final double totalAmount;
  final Map<String, dynamic>? paymentDetails;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentId,
    required this.createdAt,
    required this.subtotal,
    required this.shippingCost,
    required this.taxAmount,
    required this.discount,
    required this.totalAmount,
    this.paymentDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      total: json['total'].toDouble(),
      status: json['status'],
      shippingAddress: ShippingAddress.fromJson(json['shipping_address']),
      paymentMethod: json['payment_method'],
      paymentId: json['payment_id'],
      createdAt: json['created_at'],
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      shippingCost: json['shipping_cost']?.toDouble() ?? 0.0,
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      discount: json['discount']?.toDouble() ?? 0.0,
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      paymentDetails: json['payment_details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'shipping_address': shippingAddress.toJson(),
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'created_at': createdAt,
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'tax_amount': taxAmount,
      'discount': discount,
      'total_amount': totalAmount,
      'payment_details': paymentDetails,
    };
  }
}
