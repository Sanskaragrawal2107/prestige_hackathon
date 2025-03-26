import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({Key? key, required this.cart}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;
  String _paymentMethod = 'Credit Card';

  // Shipping address form fields
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();

  // Payment form fields
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final order = await orderProvider.placeOrder(
        userId: authProvider.user!.id,
        cart: widget.cart,
        shippingAddress: {
          'name': _nameController.text,
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zip': _zipController.text,
          'country': _countryController.text,
          'phone': _phoneController.text,
        },
        paymentMethod: _paymentMethod,
        paymentDetails: _paymentMethod == 'Credit Card'
            ? {
                'card_number': _cardNumberController.text,
                'name': _cardNameController.text,
                'expiry': _expiryController.text,
                'cvv': _cvvController.text,
              }
            : null,
      );

      if (order != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() {
                      _currentStep += 1;
                    });
                  } else {
                    _placeOrder();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep -= 1;
                    });
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _currentStep == 2 ? 'Place Order' : 'Continue',
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          SizedBox(width: 12),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: Text('Back'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // Shipping address step
                  Step(
                    title: Text('Shipping Address'),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _streetController,
                          decoration: InputDecoration(
                            labelText: 'Street Address',
                            prefixIcon: Icon(Icons.home),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your street address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: 'City',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your city';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _zipController,
                                decoration: InputDecoration(
                                  labelText: 'ZIP Code',
                                  prefixIcon: Icon(Icons.pin),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your ZIP code';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _countryController,
                                decoration: InputDecoration(
                                  labelText: 'Country',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                  ),
                  
                  // Payment method step
                  Step(
                    title: Text('Payment Method'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text('Credit Card'),
                          leading: Radio<String>(
                            value: 'Credit Card',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_paymentMethod == 'Credit Card') ...[
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              prefixIcon: Icon(Icons.credit_card),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your card number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _cardNameController,
                            decoration: InputDecoration(
                              labelText: 'Name on Card',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the name on your card';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryController,
                                  decoration: InputDecoration(
                                    labelText: 'Expiry (MM/YY)',
                                    prefixIcon: Icon(Icons.date_range),
                                  ),
                                  keyboardType: TextInputType.datetime,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    prefixIcon: Icon(Icons.security),
                                  ),
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        ListTile(
                          title: Text('Cash on Delivery'),
                          leading: Radio<String>(
                            value: 'Cash on Delivery',
                            groupValue: _paymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _paymentMethod = value!;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                  ),
                  
                  // Order summary step
                  Step(
                    title: Text('Order Summary'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items (${widget.cart.items.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        // List of items
                        for (var item in widget.cart.items) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                            ),
                            title: Text(
                              item.product.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              '\$${(item.quantity * item.product.price).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(),
                        ],
                        
                        SizedBox(height: 16),
                        
                        // Price summary
                        _buildSummaryRow(
                          'Subtotal',
                          '\$${_calculateSubtotal().toStringAsFixed(2)}',
                        ),
                        SizedBox(height: 8),
                        _buildSummaryRow(
                          'Shipping',
                          '\$${_calculateShipping().toStringAsFixed(2)}',
                        ),
                        SizedBox(height: 8),
                        _buildSummaryRow(
                          'Tax',
                          '\$${_calculateTax().toStringAsFixed(2)}',
                        ),
                        Divider(height: 24),
                        _buildSummaryRow(
                          'Total',
                          '\$${_calculateTotal().toStringAsFixed(2)}',
                          isBold: true,
                          fontSize: 18,
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Shipping address summary
                        Text(
                          'Shipping To',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        _nameController.text.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_nameController.text),
                                  Text(_streetController.text),
                                  Text(
                                    '${_cityController.text}, ${_stateController.text} ${_zipController.text}',
                                  ),
                                  Text(_countryController.text),
                                  Text('Phone: ${_phoneController.text}'),
                                ],
                              )
                            : Text('Please fill in your shipping address'),
                            
                        SizedBox(height: 16),
                        
                        // Payment method summary
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(_paymentMethod),
                        if (_paymentMethod == 'Credit Card' &&
                            _cardNumberController.text.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            'Card ending in ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}',
                          ),
                        ],
                      ],
                    ),
                    isActive: _currentStep >= 2,
                    state: StepState.indexed,
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
          ),
        ),
      ],
    );
  }

  double _calculateSubtotal() {
    return widget.cart.items.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double _calculateShipping() {
    // Simplified shipping calculation
    return widget.cart.items.isNotEmpty ? 5.99 : 0;
  }

  double _calculateTax() {
    // Simplified tax calculation (e.g., 8% tax)
    return _calculateSubtotal() * 0.08;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateShipping() + _calculateTax();
  }
} 