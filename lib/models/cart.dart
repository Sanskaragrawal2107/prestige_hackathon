import 'package:flutter/material.dart';
import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get total => product.price * quantity;
  double get discountedTotal => product.discountedPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}

class Cart {
  final String id;
  List<CartItem> items;

  Cart({
    required this.id,
    required this.items,
  });

  factory Cart.empty() {
    return Cart(
      id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
      items: [],
    );
  }

  double get totalPrice {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  double get discountedTotalPrice {
    return items.fold(0, (sum, item) => sum + item.discountedTotal);
  }

  double get savingsAmount {
    return totalPrice - discountedTotalPrice;
  }

  void addItem(Product product, int quantity) {
    // Check if product already exists in cart
    final existingItemIndex = items.indexWhere((item) => item.product.id == product.id);

    if (existingItemIndex >= 0) {
      // Update quantity if product already exists
      items[existingItemIndex].quantity += quantity;
    } else {
      // Add new item if product doesn't exist in cart
      items.add(
        CartItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_${product.id}',
          product: product,
          quantity: quantity,
        ),
      );
    }
  }

  void updateItemQuantity(String itemId, int quantity) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      items[index].quantity = quantity;
      
      // Remove item if quantity is 0 or less
      if (items[index].quantity <= 0) {
        items.removeAt(index);
      }
    }
  }

  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }
} 