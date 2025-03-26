import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  Cart _cart = Cart.empty();
  String? _error;
  String? _userId;

  bool get isLoading => _isLoading;
  Cart get cart => _cart;
  String? get error => _error;
  int get itemCount => _cart.items.length;
  double get totalPrice => _cart.totalPrice;
  double get discountedTotalPrice => _cart.discountedTotalPrice;
  double get savingsAmount => _cart.savingsAmount;

  void setUserId(String userId) {
    _userId = userId;
    loadCart(userId);
  }

  Future<void> loadCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loadedCart = await ApiService.getCart(userId);
      if (loadedCart != null) {
        _cart = loadedCart;
      } else {
        _cart = Cart.empty();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    if (_userId == null) {
      _error = "User not logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.addToCart(_userId!, product.id, quantity);
      if (success) {
        // Update local cart
        _cart.addItem(product, quantity);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to add item to cart';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCartItem(String itemId, int quantity) async {
    if (_userId == null) {
      _error = "User not logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.updateCartItem(_userId!, itemId, quantity);
      if (success) {
        // Update local cart
        _cart.updateItemQuantity(itemId, quantity);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update cart item';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(String itemId) async {
    if (_userId == null) {
      _error = "User not logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.removeFromCart(_userId!, itemId);
      if (success) {
        // Update local cart
        _cart.removeItem(itemId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to remove item from cart';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearCart() async {
    if (_userId == null) {
      _error = "User not logged in";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.clearCart(_userId!);
      if (success) {
        _cart = Cart.empty();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to clear cart';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 