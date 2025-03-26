import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Product> _products = [];
  List<Product> _searchResults = [];
  String? _error;
  String? _selectedCategory;

  bool get isLoading => _isLoading;
  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;

  Future<void> loadProducts({int skip = 0, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedProducts = await ApiService.getProducts(
        skip: skip, 
        limit: limit,
        category: _selectedCategory,
      );
      
      if (skip == 0) {
        // Replace products if loading from the beginning
        _products = fetchedProducts;
      } else {
        // Append products if loading more (pagination)
        _products.addAll(fetchedProducts);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> getProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await ApiService.getProduct(productId);
      _isLoading = false;
      notifyListeners();
      return product;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await ApiService.searchProducts(query);
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    loadProducts(skip: 0, limit: 20); // Reload products with the new category
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 