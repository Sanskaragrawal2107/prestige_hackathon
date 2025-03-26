import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/user.dart' as app_user;
import '../models/cart.dart';

class ApiService {
  static final _supabase = Supabase.instance.client;

  // ====== Authentication ======

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      // Register with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.error != null) {
        return {'detail': response.error!.message};
      }

      // Create user profile in 'users' table
      if (response.user != null) {
        final userId = response.user!.id;
        
        final userResponse = await _supabase.from('users').insert({
          'id': userId,
          'name': name,
          'email': email,
        }).execute();

        if (userResponse.error != null) {
          return {'detail': userResponse.error!.message};
        }
        
        return {'message': 'User registered successfully'};
      } else {
        return {'detail': 'Registration failed'};
      }
    } catch (e) {
      return {'detail': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.error != null) {
        return {'detail': response.error!.message};
      }

      if (response.user != null) {
        final session = response.session;
        if (session != null) {
          // Save token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', session.accessToken);
          
          return {
            'access_token': session.accessToken,
            'user': {
              'id': response.user!.id,
              'email': response.user!.email,
            }
          };
        }
      }
      
      return {'detail': 'Login failed'};
    } catch (e) {
      return {'detail': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _supabase.auth.signOut();
      
      if (response.error != null) {
        return {'detail': response.error.message};
      }
      
      // Remove token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      return {'message': 'Logged out successfully'};
    } catch (e) {
      return {'detail': e.toString()};
    }
  }

  static Future<app_user.User?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single()
            .execute();
        
        if (response.error != null) {
          throw response.error!.message;
        }
        
        if (response.data != null) {
          return app_user.User.fromJson(response.data);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ====== Products ======

  static Future<List<Product>> getProducts({int skip = 0, int limit = 20, String? category}) async {
    try {
      // Build query
      var query = _supabase
          .from('products')
          .select()
          .range(skip, skip + limit - 1);
      
      // Add category filter if provided
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      
      // Order by creation date (newest first)
      query = query.order('created_at', ascending: false);
      
      // Execute query
      final response = await query.execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      final productsList = (response.data as List)
          .map((item) => Product.fromJson(item))
          .toList();
          
      return productsList;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<Product?> getProduct(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single()
          .execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      return Product.fromJson(response.data);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      // Perform search using ilike for case-insensitive partial matches
      final response = await _supabase
          .from('products')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      final productsList = (response.data as List)
          .map((item) => Product.fromJson(item))
          .toList();
          
      return productsList;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // ====== Cart ======

  static Future<bool> addToCart(String userId, String productId, int quantity) async {
    try {
      // Get the product
      final product = await getProduct(productId);
      if (product == null) {
        return false;
      }

      // Check if item already exists in cart
      final existingCartItem = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle()
          .execute();
          
      if (existingCartItem.error != null) {
        throw existingCartItem.error!.message;
      }
      
      if (existingCartItem.data != null) {
        // Update quantity if item exists
        final newQuantity = (existingCartItem.data['quantity'] as int) + quantity;
        final updateResponse = await _supabase
            .from('cart_items')
            .update({'quantity': newQuantity})
            .eq('id', existingCartItem.data['id'])
            .execute();
            
        if (updateResponse.error != null) {
          throw updateResponse.error!.message;
        }
      } else {
        // Insert new cart item
        final insertResponse = await _supabase
            .from('cart_items')
            .insert({
              'user_id': userId,
              'product_id': productId,
              'quantity': quantity,
              'created_at': DateTime.now().toIso8601String(),
            })
            .execute();
            
        if (insertResponse.error != null) {
          throw insertResponse.error!.message;
        }
      }
      
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  static Future<Cart?> getCart(String userId) async {
    try {
      // Get cart items for user
      final response = await _supabase
          .from('cart_items')
          .select('id, product_id, quantity, products(*)')
          .eq('user_id', userId)
          .execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      // Create new cart with items
      final cart = Cart.empty();
      
      if (response.data != null) {
        final cartItemsList = response.data as List;
        
        for (var item in cartItemsList) {
          final product = Product.fromJson(item['products']);
          final cartItem = CartItem(
            id: item['id'],
            product: product,
            quantity: item['quantity'],
          );
          
          cart.items.add(cartItem);
        }
      }
      
      return cart;
    } catch (e) {
      print('Error getting cart: $e');
      return null;
    }
  }

  static Future<bool> updateCartItem(String userId, String itemId, int quantity) async {
    try {
      // If quantity <= 0, remove the item
      if (quantity <= 0) {
        return removeFromCart(userId, itemId);
      }
      
      // Update the cart item
      final response = await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', itemId)
          .eq('user_id', userId)
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      return true;
    } catch (e) {
      print('Error updating cart item: $e');
      return false;
    }
  }

  static Future<bool> removeFromCart(String userId, String itemId) async {
    try {
      // Delete the cart item
      final response = await _supabase
          .from('cart_items')
          .delete()
          .eq('id', itemId)
          .eq('user_id', userId)
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  static Future<bool> clearCart(String userId) async {
    try {
      // Delete all cart items for user
      final response = await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  // ====== CSRF Token Management ======

  static Future<String?> getCsrfToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      // Call the RPC to create a CSRF token
      final response = await _supabase
          .rpc('create_csrf_token', params: {'user_id': user.id})
          .execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      return response.data as String;
    } catch (e) {
      print('Error generating CSRF token: $e');
      return null;
    }
  }

  static Future<bool> validateCsrfToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Call the RPC to validate the CSRF token
      final response = await _supabase
          .rpc('validate_csrf_token', params: {
            'input_token': token,
            'user_id': user.id
          })
          .execute();

      if (response.error != null) {
        throw response.error!.message;
      }

      return response.data as bool;
    } catch (e) {
      print('Error validating CSRF token: $e');
      return false;
    }
  }

  // ====== Orders ======

  static Future<Map<String, dynamic>?> placeOrder({
    required String userId,
    required Cart cart,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Get a CSRF token
      final csrfToken = await getCsrfToken();
      if (csrfToken == null) {
        return null;
      }

      // Validate the token (in a real app, this would be done server-side)
      final isValid = await validateCsrfToken(csrfToken);
      if (!isValid) {
        return null;
      }
      
      // Calculate totals
      final subtotal = cart.items.fold(
          0.0,
          (sum, item) => sum + (item.product.discountedPrice * item.quantity));
      
      final shippingCost = 5.99;
      final taxAmount = subtotal * 0.08;
      final totalAmount = subtotal + shippingCost + taxAmount;

      // Create the order
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'shipping_address': shippingAddress,
            'payment_method': paymentMethod,
            'payment_details': paymentDetails,
            'subtotal': subtotal,
            'shipping_cost': shippingCost,
            'tax_amount': taxAmount,
            'discount': 0.0,
            'total_amount': totalAmount,
            'status': 'processing',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .execute();
          
      if (orderResponse.error != null) {
        throw orderResponse.error!.message;
      }
      
      final order = orderResponse.data;
      final orderId = order['id'];
      
      // Create order items
      for (var item in cart.items) {
        final orderItemResponse = await _supabase
            .from('order_items')
            .insert({
              'order_id': orderId,
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price': item.product.price,
              'discounted_price': item.product.discountedPrice,
              'created_at': DateTime.now().toIso8601String(),
            })
            .execute();
            
        if (orderItemResponse.error != null) {
          throw orderItemResponse.error!.message;
        }
      }
      
      // Clear the cart
      await clearCart(userId);

      // Add order items to response for returning
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId)
          .execute();
          
      if (orderItemsResponse.error != null) {
        throw orderItemsResponse.error!.message;
      }
      
      order['items'] = orderItemsResponse.data;
      
      return order;
    } catch (e) {
      print('Error placing order: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      final orders = response.data as List;
      final result = <Map<String, dynamic>>[];
      
      // Get order items for each order
      for (var order in orders) {
        final orderItemsResponse = await _supabase
            .from('order_items')
            .select('*, products(*)')
            .eq('order_id', order['id'])
            .execute();
            
        if (orderItemsResponse.error != null) {
          throw orderItemsResponse.error!.message;
        }
        
        order['items'] = orderItemsResponse.data;
        result.add(Map<String, dynamic>.from(order));
      }
      
      return result;
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single()
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      final order = response.data;
      
      // Get order items
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId)
          .execute();
          
      if (orderItemsResponse.error != null) {
        throw orderItemsResponse.error!.message;
      }
      
      order['items'] = orderItemsResponse.data;
      
      return order;
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }
  
  // Add methods for payment confirmation and checkout
  
  static Future<Map<String, dynamic>> initiateCheckout(String shippingAddress, String paymentMethod) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'error': 'User not logged in'};
      }
      
      // Get user's cart
      final cart = await getCart(user.id);
      if (cart == null || cart.items.isEmpty) {
        return {'error': 'Cart is empty'};
      }
      
      // Return placeholder for now (would be implemented with Razorpay or other payment provider)
      return {
        'order_id': 'temp_order_id',
        'payment': {
          'key': 'razorpay_key',
          'amount': cart.discountedTotalPrice + 5.99 + (cart.discountedTotalPrice * 0.08),
          'id': 'razorpay_order_id',
        }
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> confirmPayment(String orderId, String paymentId, String signature) async {
    try {
      // Update order payment status
      final response = await _supabase
          .from('orders')
          .update({
            'status': 'paid',
            'payment_details': {
              'payment_id': paymentId,
              'signature': signature,
              'paid_at': DateTime.now().toIso8601String(),
            }
          })
          .eq('id', orderId)
          .execute();
          
      if (response.error != null) {
        throw response.error!.message;
      }
      
      return {
        'order_id': orderId,
        'status': 'success',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
} 