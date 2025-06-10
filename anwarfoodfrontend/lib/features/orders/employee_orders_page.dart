import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeeOrdersPage extends StatefulWidget {
  const EmployeeOrdersPage({Key? key}) : super(key: key);

  @override
  State<EmployeeOrdersPage> createState() => _EmployeeOrdersPageState();
}

class _EmployeeOrdersPageState extends State<EmployeeOrdersPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  String _error = '';
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedEmployee;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredEmployees = _employees;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredEmployees = _employees.where((employee) {
        final searchTerm = _searchController.text.toLowerCase();
        final name = employee['USERNAME'].toString().toLowerCase();
        final email = employee['EMAIL'].toString().toLowerCase();
        final mobile = employee['MOBILE'].toString();
        return name.contains(searchTerm) || 
               email.contains(searchTerm) || 
               mobile.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://192.168.29.96:3000/api/admin/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data['data']);
          _filteredEmployees = _employees;
          _isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load employees');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeOrders(int userId) async {
    try {
      setState(() {
        _isLoadingOrders = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://192.168.29.96:3000/api/admin/employee-orders/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['data']);
          _isLoadingOrders = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load employee orders');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingOrders = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('HH:mm hrs, d MMM yyyy');
    return formatter.format(date);
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

  Widget _buildEmployeeDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Search TextField
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // Dropdown items
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                final employee = _filteredEmployees[index];
                final isSelected = _selectedEmployee?['USER_ID'] == employee['USER_ID'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEmployee = null;
                        _orders = [];
                      } else {
                        _selectedEmployee = employee;
                        _loadEmployeeOrders(employee['USER_ID']);
                      }
                      _searchController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF9B1B1B).withOpacity(0.1) : Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF9B1B1B).withOpacity(0.1),
                          child: Text(
                            employee['USERNAME'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee['USERNAME'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                employee['EMAIL'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '+91 ${employee['MOBILE']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF9B1B1B),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found for this employee',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/order-details', arguments: order);
          },
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['ORDER_NUMBER']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['ORDER_STATUS']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['ORDER_STATUS'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(order['ORDER_STATUS']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      order['CUSTOMER_NAME'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '+91 ${order['CUSTOMER_MOBILE']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${order['ORDER_TOTAL']}',
                      style: const TextStyle(
                        color: Color(0xFFFE6A00),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(order['CREATED_DATE']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          'Employee Orders',
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmployees,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Select Employee',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildEmployeeDropdown(),
                      if (_selectedEmployee != null) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                'Orders by ${_selectedEmployee!['USERNAME']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_isLoadingOrders)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildOrdersList(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
} 