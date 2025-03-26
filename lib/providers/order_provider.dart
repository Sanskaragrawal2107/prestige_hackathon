import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Order> _orders = [];
  Order? _currentOrder;
  String? _error;
  late Razorpay _razorpay;

  bool get isLoading => _isLoading;
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  String? get error => _error;

  OrderProvider() {
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_currentOrder != null) {
        await confirmPayment(
          _currentOrder!.id,
          response.paymentId!,
          response.signature!,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _error = response.message ?? 'Payment failed';
    _isLoading = false;
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  Future<void> loadOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ordersData = await ApiService.getUserOrders(userId);
      
      // Convert to Order objects
      _orders = ordersData.map((data) => Order.fromJson(data)).toList();
      
      // Sort by date (newest first)
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> getOrderDetails(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = await ApiService.getOrderDetails(orderId);
      if (orderData != null) {
        _isLoading = false;
        notifyListeners();
        return Order.fromJson(orderData);
      } else {
        _error = 'Order not found';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Order?> placeOrder({
    required String userId,
    required Cart cart,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = await ApiService.placeOrder(
        userId: userId,
        cart: cart,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
      );

      if (orderData != null) {
        final order = Order.fromJson(orderData);
        
        // Add to local orders list
        _orders.add(order);
        // Sort by date (newest first)
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        _isLoading = false;
        notifyListeners();
        return order;
      } else {
        _error = 'Failed to place order';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> initiateCheckout(String shippingAddress, String paymentMethod) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.initiateCheckout(shippingAddress, paymentMethod);
      
      if (response['error'] != null) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (response['order_id'] != null && response['payment'] != null) {
        // Store current order ID
        final orderId = response['order_id'];
        final orderDetails = await getOrderDetails(orderId);
        
        if (orderDetails != null) {
          _currentOrder = orderDetails;
          
          // Open Razorpay checkout
          var options = {
            'key': response['payment']['key'],
            'amount': response['payment']['amount'] * 100, // in paise
            'name': 'E-Commerce Checkout',
            'description': 'Order #$orderId',
            'order_id': response['payment']['id'],
            'prefill': {
              'contact': '1234567890',
              'email': 'customer@example.com',
            },
            'theme': {
              'color': '#8B4513',
            }
          };
          
          _razorpay.open(options);
          return true;
        } else {
          _error = 'Failed to get order details';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = response['detail'] ?? 'Failed to initiate checkout';
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

  Future<bool> confirmPayment(String orderId, String paymentId, String signature) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.confirmPayment(orderId, paymentId, signature);
      
      if (response['order_id'] != null && response['status'] != null) {
        // Reload the order to get updated status
        final orderDetails = await getOrderDetails(orderId);
        if (orderDetails != null) {
          _currentOrder = orderDetails;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['detail'] ?? 'Failed to confirm payment';
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

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 