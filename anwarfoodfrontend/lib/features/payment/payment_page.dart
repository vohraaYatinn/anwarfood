import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../order/order_success_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse('https://anwarfood.onrender.com/api/cart/place-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessPage(orderDetails: data['data']),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upiList = [
      {'icon': 'assets/images/google.png', 'id': 'Loremipsum@okicici'},
      {'icon': 'assets/images/google.png', 'id': 'Payment@okicici'},
      {'icon': 'assets/images/google.png', 'id': '799131480@paytm'},
    ];
    final cards = [
      {'icon': 'assets/images/visa.png', 'name': 'Axis Card', 'number': '**** 1380', 'isPreferred': true},
      {'icon': 'assets/images/visa.png', 'name': 'Slice Card', 'number': '**** 6222', 'isPreferred': false},
      {'icon': 'assets/images/visa.png', 'name': 'Jane', 'number': '**** 1172', 'isPreferred': false},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Options',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: const [
                  Text('3 items. Total: ₹284', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _isLoading ? null : _placeOrder,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delivery_dining,
                                color: Color(0xFF9B1B1B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pay on Delivery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pay when you receive your order',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Color(0xFFFFA726), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Introducing Swiggy Money', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA726))),
                          SizedBox(height: 2),
                          Text('Avail single click payments, instant refunds and cashbacks!\nActivate Swiggy Money by providing a Govt. ID number.', style: TextStyle(color: Colors.black, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Preferred Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/visa.png', width: 32, height: 20),
                        const SizedBox(width: 10),
                        const Text('Axis Card', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Text('•••• 1380', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('CVV'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DBF73),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {},
                              child: const Text('PAY ₹ 284', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    ...upiList.map((upi) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Image.asset(upi['icon'] as String, width: 28, height: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(upi['id'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              const Icon(Icons.radio_button_off, color: Colors.grey),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.add_circle_outline, color: Color(0xFFFFA726)),
                        SizedBox(width: 8),
                        Text('Add New UPI ID', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('You need to have a registered UPI ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Credit & Debit cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    ...cards.skip(1).map((card) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Image.asset(card['icon'] as String, width: 32, height: 20),
                              const SizedBox(width: 10),
                              Text(card['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(card['number'] as String, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              const Icon(Icons.radio_button_off, color: Colors.grey),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.add_circle_outline, color: Color(0xFFFFA726)),
                        SizedBox(width: 8),
                        Text('Add New Card', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('Save and Pay via Cards.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('More Payment Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _morePaymentOption(Icons.account_balance_wallet_outlined, 'Wallets', 'Paytm, PhonePe, Amazon Pay & more'),
                    _morePaymentOption(Icons.restaurant, 'Sodexo', 'Sodexo card valid only on Restaurants & In...'),
                    _morePaymentOption(Icons.account_balance, 'Netbanking', 'Select from a list of banks'),
                    _morePaymentOption(Icons.money, 'Pay on Delivery', 'Pay in cash or pay online.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _morePaymentOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      onTap: () {},
    );
  }
} 