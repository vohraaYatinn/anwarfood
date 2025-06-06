import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  bool _isCancelling = false;
  bool _isUpdatingStatus = false;
  User? _user;
  dynamic _deliveryImage; // Changed to dynamic to handle both File and XFile
  bool _showDeliveryConfirmation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
        // Load order details after getting user data
        final args = ModalRoute.of(context)?.settings.arguments;
        int? orderId;
        if (args is Map<String, dynamic> && args['ORDER_ID'] != null) {
          orderId = args['ORDER_ID'] as int;
        } else if (args is int) {
          orderId = args;
        }
        if (orderId != null) {
          _fetchOrderDetails(orderId);
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Order ID not found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOrderDetails(int orderId) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      if (_user?.role?.toLowerCase() == 'admin') {
        final data = await _orderService.adminGetOrderDetails(orderId);
        setState(() {
          _order = data;
          _items = data['ORDER_ITEMS'] ?? [];
          _isLoading = false;
        });
      } else if (_user?.role?.toLowerCase() == 'employee') {
        final data = await _orderService.employeeGetOrderDetails(orderId);
        setState(() {
          _order = data;
          _items = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        final data = await _orderService.getOrderDetails(orderId);
        setState(() {
          _order = data['order'];
          _items = data['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDeliveryImage() async {
    try {
      if (kIsWeb) {
        // Web implementation
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1000,
        );
        
        if (image != null && mounted) {
          setState(() {
            _deliveryImage = image;
          });
        }
      } else {
        // Mobile implementation
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          if (status.isDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission is required to pick an image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1000,
        );
        
        if (image != null && mounted) {
          setState(() {
            _deliveryImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsDelivered() async {
    if (_order == null) return;

    setState(() {
      _showDeliveryConfirmation = true;
    });
  }

  Future<void> _confirmDelivery() async {
    if (_order == null) return;
    if (_deliveryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a delivery confirmation image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      // For now, we'll just update the status without sending the image
      // In a real implementation, you would upload the image to your server first
      final result = await _orderService.employeeUpdateOrderStatus(_order!['ORDER_ID'], 'delivered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showDeliveryConfirmation = false;
          _order!['ORDER_STATUS'] = 'delivered';
          _deliveryImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('hh:mm a, dd MMM yyyy');
    return formatter.format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF9B1B1B);
      case 'cancelled':
        return Colors.red;
      case 'accepted':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptOrder() async {
    if (_order == null) return;
    
    try {
      setState(() {
        _isCancelling = true; // Reuse the loading state
      });
      
      final result = await _orderService.adminUpdateOrderStatus(_order!['ORDER_ID'], 'confirmed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh order details
        _fetchOrderDetails(_order!['ORDER_ID']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;
    
    // Show confirmation dialog first
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cancel Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel order #${_order!['ORDER_NUMBER']}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF9B1B1B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'No, Keep It',
                        style: TextStyle(
                          color: Color(0xFF9B1B1B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Yes, Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // If user didn't confirm, return
    if (shouldCancel != true) return;
    
    try {
      setState(() {
        _isCancelling = true;
      });
      
      final result = await _orderService.adminUpdateOrderStatus(_order!['ORDER_ID'], 'cancelled');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh order details
        _fetchOrderDetails(_order!['ORDER_ID']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Widget _buildDeliveryConfirmation() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF9B1B1B),
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirm Delivery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please upload a delivery confirmation image',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            if (_deliveryImage != null)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(_deliveryImage.path)
                        : FileImage(_deliveryImage) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 40),
                  onPressed: _pickDeliveryImage,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() {
                      _showDeliveryConfirmation = false;
                      _deliveryImage = null;
                    }),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1B1B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isUpdatingStatus ? null : _confirmDelivery,
                    child: _isUpdatingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_order == null) return const SizedBox.shrink();
    
    final orderStatus = _order!['ORDER_STATUS']?.toString().toLowerCase() ?? '';
    final isAdmin = _user?.role?.toLowerCase() == 'admin';
    final isEmployee = _user?.role?.toLowerCase() == 'employee';

    // For delivered orders, show no buttons
    if (orderStatus == 'delivered') {
      return const SizedBox.shrink();
    }

    // For employee users
    if (isEmployee) {
      if (orderStatus == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9B1B1B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUpdatingStatus ? null : _markAsDelivered,
              child: _isUpdatingStatus
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Mark as Delivered',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // For admin users
    if (isAdmin) {
      if (orderStatus == 'pending') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCancelling ? null : _acceptOrder,
                  child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Accept Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCancelling ? null : _cancelOrder,
                  child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cancel Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
            ],
          ),
        );
      } else if (orderStatus == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCancelling ? null : _cancelOrder,
              child: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Cancel Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        );
      }
    }

    // For regular users, show cancel button only for pending orders
    if (orderStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isCancelling ? null : _cancelOrder,
            child: _isCancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Cancel Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F6F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F6F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Order Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : _order == null
                      ? const Center(child: Text('Order not found'))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Info
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F6F9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Order #${_order!['ORDER_NUMBER']}',
                                            style: const TextStyle(
                                              color: Color(0xFF9B1B1B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_order!['ORDER_STATUS'] ?? '').withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            (_order!['ORDER_STATUS'] ?? '').toString().capitalize(),
                                            style: TextStyle(
                                              color: _getStatusColor(_order!['ORDER_STATUS'] ?? ''),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Order Placed',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(_order!['CREATED_DATE']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Delivery Address
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: Color(0xFF9B1B1B)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _order!['DELIVERY_ADDRESS'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_order!['DELIVERY_CITY'] ?? ''}, ${_order!['DELIVERY_STATE'] ?? ''}, ${_order!['DELIVERY_COUNTRY'] ?? ''} - ${_order!['DELIVERY_PINCODE'] ?? ''}\n${_order!['DELIVERY_LANDMARK'] ?? ''}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Order Items
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Order Items',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _items.length,
                                      separatorBuilder: (_, __) => const Divider(height: 24),
                                      itemBuilder: (context, index) {
                                        final item = _items[index];
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: item['PROD_IMAGE_1'] != null && item['PROD_IMAGE_1'].toString().isNotEmpty
                                                  ? Image.network(
                                                      '${item['PROD_IMAGE_1']}',
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.image, color: Colors.grey),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['PROD_NAME'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Quantity: ${item['QUANTITY']}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Rs. ${item['TOTAL_PRICE']}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF9B1B1B),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Payment Details
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${_order!['ORDER_TOTAL']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          'Delivery Fee',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Rs. 0.00',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${_order!['ORDER_TOTAL']}',
                                          style: const TextStyle(
                                            color: Color(0xFF9B1B1B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
        ),
        if (_showDeliveryConfirmation)
          Container(
            color: Colors.black54,
            child: Center(
              child: _buildDeliveryConfirmation(),
            ),
          ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
} 