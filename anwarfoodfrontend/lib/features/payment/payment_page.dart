import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../order/order_success_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isBankDetailsLoading = true;
  Map<String, dynamic>? _bankDetails;
  String? _error;
  dynamic _paymentScreenshot; // File for mobile, XFile for web
  bool _showImageUpload = false;
  Uint8List? _webImage; // For web platform

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    try {
      final details = await _settingsService.getBankDetails();
      setState(() {
        _bankDetails = details;
        _isBankDetailsLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isBankDetailsLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // Handle web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _paymentScreenshot = image;
          });
        } else {
          // Handle mobile platforms
          setState(() {
            _paymentScreenshot = File(image.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadDialog() {
    setState(() {
      _showImageUpload = true;
    });
  }

  Future<void> _placeOrder({required bool isPaidOnline}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _authService.getToken();
      final user = await _authService.getUser();
      
      if (token == null) throw Exception('No authentication token found');
      if (user == null) throw Exception('User not found');
      if (user.role.toLowerCase() != 'customer') throw Exception('Only customers can place orders');
      
      if (isPaidOnline && _paymentScreenshot == null) {
        throw Exception('Please upload payment screenshot');
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cart/place-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paid_online': isPaidOnline,
          'authentication': token,
          'user_id': user.id,
          'paymentMethod': isPaidOnline ? 'online' : 'cod',
          // Add payment screenshot handling here when backend is ready
        }),
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

  Widget _buildImagePreview() {
    if (_paymentScreenshot == null) return const SizedBox.shrink();

    if (kIsWeb) {
      if (_webImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _webImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _paymentScreenshot as File,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageUploadSection() {
    return Container(
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
            'Upload Payment Screenshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentScreenshot != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentScreenshot == null ? const Color(0xFF9B1B1B) : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _pickImage,
              child: Text(
                _paymentScreenshot == null ? 'Select Screenshot' : 'Change Screenshot',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_paymentScreenshot != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B1B1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : () => _placeOrder(isPaidOnline: true),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
              if (!_showImageUpload) ...[
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
                        onTap: _isLoading ? null : () => _placeOrder(isPaidOnline: false),
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
                const SizedBox(height: 24),
                if (_isBankDetailsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadBankDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_bankDetails != null) ...[
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
                          'Bank Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Bank Name', _bankDetails!['bank_name']),
                        _buildDetailRow('Branch', _bankDetails!['branch']),
                        _buildDetailRow('Account Number', _bankDetails!['account_number']),
                        _buildDetailRow('IFSC Code', _bankDetails!['ifsc_code']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_bankDetails!['upi_image_url'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Scan QR Code to Pay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Image.network(
                            _bankDetails!['upi_image_url'],
                            height: 200,
                            width: 200,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1B1B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _showUploadDialog,
                      child: const Text(
                        'Confirm Online Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                _buildImageUploadSection(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 