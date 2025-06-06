import 'package:flutter/material.dart';
import '../../services/retailer_service.dart';

class RetailerListPage extends StatefulWidget {
  const RetailerListPage({Key? key}) : super(key: key);

  @override
  State<RetailerListPage> createState() => _RetailerListPageState();
}

class _RetailerListPageState extends State<RetailerListPage> {
  final RetailerService _retailerService = RetailerService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _retailers = [];
  Map<String, dynamic>? _pagination;
  int _currentPage = 1;
  final int _limit = 5;
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRetailers();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isSearching && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_pagination != null && _currentPage < _pagination!['totalPages']) {
        _loadMoreRetailers();
      }
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      await _loadRetailers();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _retailerService.searchRetailers(query);
      setState(() {
        _retailers = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRetailers() async {
    if (_isSearching) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _retailerService.getRetailerList(page: 1, limit: _limit);
      setState(() {
        _retailers = List<Map<String, dynamic>>.from(data['retailers']);
        _pagination = data['pagination'];
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRetailers() async {
    if (_isLoading || _isSearching) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _retailerService.getRetailerList(
        page: _currentPage + 1,
        limit: _limit,
      );
      
      setState(() {
        _retailers.addAll(List<Map<String, dynamic>>.from(data['retailers']));
        _pagination = data['pagination'];
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          'Retailer List',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, shop, or mobile',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => _onSearchChanged(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
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
                          onPressed: _loadRetailers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRetailers,
                    child: _retailers.isEmpty && !_isLoading
                        ? const Center(
                            child: Text(
                              'No retailers found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _retailers.length + (_isLoading && !_isSearching ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
                            itemBuilder: (context, index) {
                              if (index == _retailers.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final retailer = _retailers[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/retailer-detail',
                                    arguments: retailer['RET_ID'],
                                  );
                                },
                                child: Container(
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          retailer['RET_PHOTO'] ?? '',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.store, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              retailer['RET_NAME'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (retailer['RET_SHOP_NAME'] != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                retailer['RET_SHOP_NAME'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            Text(
                                              retailer['RET_MOBILE_NO']?.toString() ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${retailer['RET_ADDRESS']}, ${retailer['RET_CITY']}, ${retailer['RET_STATE']}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9B1B1B),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/orders');
              break;
            case 1:
              Navigator.pushNamed(context, '/product-list');
              break;
            case 2:
              // Already on retailers page
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