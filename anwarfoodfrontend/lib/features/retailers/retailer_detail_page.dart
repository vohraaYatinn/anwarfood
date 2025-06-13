import 'package:flutter/material.dart';
import '../../services/retailer_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';

class RetailerDetailPage extends StatefulWidget {
  const RetailerDetailPage({Key? key}) : super(key: key);

  @override
  State<RetailerDetailPage> createState() => _RetailerDetailPageState();
}

class _RetailerDetailPageState extends State<RetailerDetailPage> {
  final RetailerService _retailerService = RetailerService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _retailerData;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRetailerDetails();
      _loadCurrentUser();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _editRetailer() async {
    if (_retailerData?['retailer'] == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/admin-edit-retailer',
      arguments: _retailerData!['retailer'],
    );
    
    // If the edit was successful, refresh the retailer data
    if (result == true) {
      _loadRetailerDetails();
    }
  }

  Future<void> _loadRetailerDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) {
      setState(() {
        _error = 'No retailer ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      // Convert args to int if it's not already
      final retailerId = args is int ? args : int.parse(args.toString());
      final data = await _retailerService.getRetailerDetails(retailerId);
      setState(() {
        _retailerData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return formatter.format(date);
  }

  String _formatCurrency(num amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
          'Retailer Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_currentUser != null && 
              (_currentUser!.role.toLowerCase() == 'admin' || 
               _currentUser!.role.toLowerCase() == 'employee'))
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => _editRetailer(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRetailerDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRetailerDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          const SizedBox(height: 16),
                          // Retailer Basic Info
                          _buildRetailerInfo(),
                          const SizedBox(height: 16),
                          // Sales Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sales Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                    fontSize: 16,
                    ),
                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Orders',
                                        _retailerData!['sales_summary']['total_orders'].toString(),
                                        Icons.shopping_bag_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Sales',
                                        _formatCurrency(_retailerData!['sales_summary']['total_sales_amount']),
                                        Icons.payments_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Items Sold',
                                        _retailerData!['sales_summary']['total_items_sold'].toString(),
                                        Icons.inventory_2_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Avg. Order Value',
                                        _formatCurrency(_retailerData!['sales_summary']['average_order_value']),
                                        Icons.analytics_outlined,
                    ),
                  ),
                ],
              ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Recent Orders
                          if (_retailerData!['recent_orders'].isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
              const Text(
                                    'Recent Orders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                                      fontSize: 16,
                ),
              ),
                                  const SizedBox(height: 16),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _retailerData!['recent_orders'].length,
                                    separatorBuilder: (context, index) => const Divider(height: 24),
                                    itemBuilder: (context, index) {
                                      final order = _retailerData!['recent_orders'][index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/order-details',
                                            arguments: order['order_id'],
                                          );
                                        },
                child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order['order_number'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatDate(order['order_date']),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                                                Text(
                                                  _formatCurrency(order['total_amount']),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                                                    color: _getStatusColor(order['status']).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    order['status'].toUpperCase(),
                                                    style: TextStyle(
                                                      color: _getStatusColor(order['status']),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
              ),
              const SizedBox(height: 24),
            ],
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetailerInfo() {
    final retailer = _retailerData?['retailer'];
    if (retailer == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop name title
        Text(
          retailer['RET_SHOP_NAME'] ?? retailer['RET_NAME'] ?? 'Retailer',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        
        // QR Code section (if available)
        if (retailer['BARCODE_URL'] != null) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Shop QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9B1B1B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9B1B1B).withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Image.network(
                      '${ApiConfig.baseUrl}/uploads/retailers/qrcode/${retailer['BARCODE_URL']}',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.qr_code,
                        size: 150,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Scan to view shop details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Retailer photo section
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: retailer['RET_PHOTO'] != null
                ? Image.network(
                    retailer['RET_PHOTO'].toString().startsWith('http')
                        ? retailer['RET_PHOTO']
                        : '${ApiConfig.baseUrl}/uploads/retailers/profiles/${retailer['RET_PHOTO']}',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.store, size: 80, color: Colors.grey),
                        ),
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, size: 80, color: Colors.grey),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Retailer details card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retailer name and basic info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          retailer['RET_NAME'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (retailer['RET_SHOP_NAME'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            retailer['RET_SHOP_NAME'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Color(0xFF9B1B1B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${retailer['RET_ADDRESS']}, ${retailer['RET_CITY']}, ${retailer['RET_STATE']}, ${retailer['RET_COUNTRY']} - ${retailer['RET_PIN_CODE']}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Phone number
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Color(0xFF9B1B1B)),
                  const SizedBox(width: 8),
                  Text(
                    retailer['RET_MOBILE_NO']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              // Email (if available)
              if (retailer['RET_EMAIL_ID'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email, size: 18, color: Color(0xFF9B1B1B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        retailer['RET_EMAIL_ID'],
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // GST number (if available)
              if (retailer['RET_GST_NO'] != null && retailer['RET_GST_NO'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 18, color: Color(0xFF9B1B1B)),
                    const SizedBox(width: 8),
                    Text(
                      'GST: ${retailer['RET_GST_NO']}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 