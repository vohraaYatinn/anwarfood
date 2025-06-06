import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/address_service.dart';
import '../../models/address_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  final AddressService _addressService = AddressService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  bool _showSearchDropdown = false;
  bool _isLoading = true;
  bool _isAddressLoading = true;
  String _error = '';
  String? _addressError;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _retailerInfo;
  Address? _defaultAddress;
  User? _user;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this is a return navigation from another page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isInitialized) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isInitialized = true;
        });
        _fetchOrders();
        if (_user?.role.toLowerCase() == 'customer') {
          _loadDefaultAddress();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchOrders(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchDropdown = false;
          _fetchOrders(); // Reset to show all orders
        });
      }
    });
  }

  Future<void> _searchOrders(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchDropdown = true;
    });
    try {
      final results = _user?.role.toLowerCase() == 'admin'
          ? await _orderService.adminSearchOrders(query)
          : _user?.role.toLowerCase() == 'employee'
          ? await _orderService.employeeSearchOrders(query)
          : await _orderService.searchOrders(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showSearchDropdown = true;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
        _showSearchDropdown = true;
      });
    }
  }

  void _onSearchResultTap(Map<String, dynamic> order) {
    setState(() {
      _showSearchDropdown = false;
      _searchController.text = '';
    });
    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: order['ORDER_ID'],
    );
  }

  void _onShowAllResults() {
    setState(() {
      _showSearchDropdown = false;
      if (_searchResults.isNotEmpty) {
        _orders = _searchResults; // Show all search results
      }
    });
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = _user?.role.toLowerCase() == 'admin'
          ? await _orderService.getAdminOrders('pending')
          : _user?.role.toLowerCase() == 'employee'
          ? await _orderService.getEmployeeOrders()
          : await _orderService.getOrders();

      setState(() {
        if (_user?.role.toLowerCase() == 'employee') {
          _orders = (response['data']['orders'] as List).cast<Map<String, dynamic>>();
        } else {
          _orders = (response['orders'] as List).cast<Map<String, dynamic>>();
          _retailerInfo = response['retailer_info'] as Map<String, dynamic>?;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDefaultAddress() async {
    setState(() {
      _isAddressLoading = true;
      _addressError = null;
    });
    try {
      final address = await _addressService.getDefaultAddress();
      setState(() {
        _defaultAddress = address;
        _isAddressLoading = false;
      });
    } catch (e) {
      setState(() {
        _addressError = e.toString();
        _isAddressLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        title: _user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'employee'
          ? const Text(
              'Orders',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : Row(
          children: [
            const Icon(Icons.location_on, color: Colors.black, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/address-list');
                },
                child: _isAddressLoading
                    ? const SizedBox(
                        height: 18,
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    : _defaultAddress != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _defaultAddress!.addressType.isNotEmpty
                                    ? _defaultAddress!.addressType
                                    : 'Default Address',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_defaultAddress!.address}, ${_defaultAddress!.city}, ${_defaultAddress!.state}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            _addressError != null
                                ? 'No address found'
                                : 'No address set',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
        ),
        toolbarHeight: _user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'employee' ? 56 : 60,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search your orders',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: () {},
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Review Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
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
                                  onPressed: _fetchOrders,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _orders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No orders found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // Clear search results when refreshing
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                    _showSearchDropdown = false;
                                  });
                                  await _fetchOrders();
                                },
                                color: const Color(0xFF9B1B1B),
                                backgroundColor: Colors.white,
                                strokeWidth: 2.5,
                                displacement: 40,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
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
                                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _retailerInfo != null && _retailerInfo!['RET_PHOTO'] != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      _retailerInfo!['RET_PHOTO'],
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons.shopping_bag_outlined,
                                                          color: Color(0xFF9B1B1B),
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Color(0xFF9B1B1B),
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Order No - ${order['ORDER_NUMBER']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _formatDate(order['CREATED_DATE']),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '₹${double.parse(order['ORDER_TOTAL'].toString()).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFE6A00),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${order['total_items']} items',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '•',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade400,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        order['ORDER_STATUS'].toString().toUpperCase(),
                                                        style: TextStyle(
                                                          color: _getStatusColor(order['ORDER_STATUS']),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
          if (_showSearchDropdown && _searchController.text.trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 60,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _searchError.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(_searchError, style: const TextStyle(color: Colors.red)),
                            )
                          : _searchResults.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No orders found'),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length + 1,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    if (index == _searchResults.length) {
                                      return ListTile(
                                        title: Text.rich(
                                          TextSpan(
                                            text: 'Show all results for ',
                                            style: const TextStyle(color: Colors.black),
                                            children: [
                                              TextSpan(
                                                text: _searchController.text.trim(),
                                                style: const TextStyle(color: Color(0xFF9B1B1B), fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: _onShowAllResults,
                                      );
                                    }
                                    final order = _searchResults[index];
                                    return ListTile(
                                      title: Text(
                                        'Order ${order['ORDER_NUMBER']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${order['total_items']} items • ${_formatDate(order['CREATED_DATE'])}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      trailing: Text(
                                        '₹${order['ORDER_TOTAL']}',
                                        style: const TextStyle(
                                          color: Color(0xFFFE6A00),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () => _onSearchResultTap(order),
                                    );
                                  },
                                ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9B1B1B),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on orders
              break;
            case 1:
              Navigator.pushNamed(context, '/product-list');
              break;
            case 2:
              Navigator.pushNamed(context, '/self-retailer-detail');
              break;
            case 3:
              Navigator.pushNamed(context, '/home');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'ORDERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'PRODUCTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'RETAILERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'SEARCH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ACCOUNT',
          ),
        ],
      ),
    );
  }
} 