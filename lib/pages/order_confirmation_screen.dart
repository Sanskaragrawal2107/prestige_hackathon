import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Clear the cart after successful order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).clearCart();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Confirmed'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your order has been placed successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              _buildInfoCard(
                title: 'Order Number',
                content: '#${order.id.substring(0, 8)}',
                icon: Icons.receipt_long,
              ),
              
              SizedBox(height: 16),
              
              _buildInfoCard(
                title: 'Estimated Delivery',
                content: _getEstimatedDelivery(),
                icon: Icons.local_shipping,
              ),
              
              SizedBox(height: 16),
              
              _buildInfoCard(
                title: 'Shipping Address',
                content: _formatAddress(),
                icon: Icons.location_on,
              ),
              
              SizedBox(height: 16),
              
              _buildInfoCard(
                title: 'Payment Method',
                content: order.paymentMethod,
                icon: Icons.payment,
              ),
              
              SizedBox(height: 24),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildSummaryRow(
                        'Subtotal',
                        '\$${order.subtotal.toStringAsFixed(2)}',
                      ),
                      SizedBox(height: 8),
                      _buildSummaryRow(
                        'Shipping',
                        '\$${order.shippingCost.toStringAsFixed(2)}',
                      ),
                      SizedBox(height: 8),
                      _buildSummaryRow(
                        'Tax',
                        '\$${order.taxAmount.toStringAsFixed(2)}',
                      ),
                      if (order.discount > 0) ...[
                        SizedBox(height: 8),
                        _buildSummaryRow(
                          'Discount',
                          '-\$${order.discount.toStringAsFixed(2)}',
                          valueColor: Colors.red,
                        ),
                      ],
                      Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 18,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.shopping_bag_outlined),
                      label: Text('Continue Shopping'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.receipt_long_outlined),
                      label: Text('View Order'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/profile',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 16,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _getEstimatedDelivery() {
    final now = DateTime.now();
    final delivery = now.add(Duration(days: 5));
    final fastDelivery = now.add(Duration(days: 3));
    
    final deliveryMonth = _getMonthName(delivery.month);
    final fastDeliveryMonth = _getMonthName(fastDelivery.month);
    
    return '${fastDelivery.day} $fastDeliveryMonth - ${delivery.day} $deliveryMonth ${delivery.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatAddress() {
    return '${order.shippingAddress.name}, ${order.shippingAddress.street}, ${order.shippingAddress.city}, ${order.shippingAddress.state} ${order.shippingAddress.zip}, ${order.shippingAddress.country}';
  }
} 