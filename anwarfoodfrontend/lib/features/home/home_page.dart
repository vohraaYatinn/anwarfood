import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../models/address_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/settings_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/brand_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/advertising_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryService _categoryService = CategoryService();
  final AddressService _addressService = AddressService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final BrandService _brandService = BrandService();
  final AdvertisingService _advertisingService = AdvertisingService();
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _debounce;
  Timer? _cartCountTimer;
  Timer? _autoPlayTimer;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _advertising = [];
  bool _isSearching = false;
  bool _isBrandsLoading = false;
  bool _isAdvertisingLoading = false;
  String _searchError = '';
  String? _brandsError;
  String? _advertisingError;
  bool _showSearchDropdown = false;
  int _cartCount = 0;
  int _currentAdIndex = 0;

  List<Category> _categories = [];
  Address? _defaultAddress;
  User? _user;
  bool _isLoading = true;
  bool _isAddressLoading = true;
  String? _error;
  String? _addressError;
  bool _isLoadingLocation = false;
  String? _locationError;
  String _appName = 'SHOPPURS APP'; // Default name until loaded

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDefaultAddress();
    _loadUserData();
    _loadBrands();
    _loadAdvertising();
    _loadAppName();
    _searchController.addListener(_onSearchChanged);
    _startAutoPlay();
    if (!kIsWeb) {
      _checkLocationPermission();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    _cartCountTimer?.cancel();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchProducts(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchDropdown = false;
        });
      }
    });
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchDropdown = true;
    });
    try {
      final results = await _productService.searchProducts(query);
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

  void _onSearchResultTap(Map<String, dynamic> product) {
    setState(() {
      _showSearchDropdown = false;
    });
    Navigator.pushNamed(context, '/product-detail', arguments: product['PROD_ID']);
  }

  void _onShowAllResults() {
    // Optionally navigate to a full search results page
    setState(() {
      _showSearchDropdown = false;
    });
    // Navigator.pushNamed(context, '/search-results', arguments: _searchController.text.trim());
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
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

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _user = user;
      });
      
      // Start fetching cart count if user is a customer
      if (user?.role.toLowerCase() == 'customer') {
        await _fetchCartCount();
        // Setup periodic cart count refresh
        _cartCountTimer?.cancel();
        _cartCountTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchCartCount());
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _fetchCartCount() async {
    if (_user?.role.toLowerCase() != 'customer') return;
    
    try {
      final cartData = await _cartService.getCartCount();
      if (mounted) {
        setState(() {
          _cartCount = cartData['totalItems'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isBrandsLoading = true;
      _brandsError = null;
    });
    try {
      final brands = await _brandService.getBrands();
      setState(() {
        _brands = brands;
        _isBrandsLoading = false;
      });
    } catch (e) {
      setState(() {
        _brandsError = e.toString();
        _isBrandsLoading = false;
      });
    }
  }

  Future<void> _loadAdvertising() async {
    setState(() {
      _isAdvertisingLoading = true;
      _advertisingError = null;
    });
    try {
      final advertising = await _advertisingService.getAdvertising();
      setState(() {
        _advertising = advertising;
        _isAdvertisingLoading = false;
      });
    } catch (e) {
      setState(() {
        _advertisingError = e.toString();
        _isAdvertisingLoading = false;
      });
    }
  }

  Future<void> _loadAppName() async {
    try {
      final appName = await _settingsService.getAppName();
      setState(() {
        _appName = appName;
      });
    } catch (e) {
      // Keep default name if error occurs
      print('Error loading app name: $e');
    }
  }

  void _showAdminOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Admin Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            const SizedBox(height: 24),
            _buildAdminOption(
              icon: Icons.add_shopping_cart,
              title: 'Add Products',
              subtitle: 'Add new products to inventory',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-product');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.people_outline,
              title: 'Manage Users',
              subtitle: 'View and manage user accounts',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manage-users');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.pending_actions,
              title: 'View Pending Orders',
              subtitle: 'Review orders awaiting processing',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.category_outlined,
              title: 'Category Management',
              subtitle: 'Manage product categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/category-management');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF9B1B1B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'We need your location to provide better service and show nearby stores. '
            'Please grant location permission.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      setState(() {
        _locationError = 'Location services are not available in web browser. Please use the mobile app for location features.';
        _isLoadingLocation = false;
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Create an address object
        Address currentLocation = Address(
          addressId: 0,
          userId: 0,
          address: '${place.street}, ${place.subLocality}',
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          pincode: place.postalCode ?? '',
          landmark: '',
          addressType: 'Current Location',
          isDefault: false,
          delStatus: 'N',
          createdDate: DateTime.now(),
          updatedDate: DateTime.now(),
        );

        setState(() {
          _defaultAddress = currentLocation;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
      print('Error getting location: $e');
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_advertising.isNotEmpty) {
        final nextPage = (_currentAdIndex + 1) % _advertising.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Widget _buildAdvertisingCarousel() {
    if (_isAdvertisingLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_advertisingError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_advertisingError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAdvertising,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_advertising.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No advertising banners available')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: _advertising.length,
            itemBuilder: (context, index) {
              final item = _advertising[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: _advertising.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).primaryColor,
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = [
      {'name': 'Amul', 'image': 'assets/images/brand_8.png'},
      {'name': 'Pepsi', 'image': 'assets/images/brand_2.png'},
      {'name': 'Britannia', 'image': 'assets/images/brand_3.png'},
      {'name': 'Parle', 'image': 'assets/images/brand_4.png'},
      {'name': 'Cadbury', 'image': 'assets/images/brand_5.png'},
      {'name': 'CocaCola', 'image': 'assets/images/brand_6.png'},
      {'name': 'ITC', 'image': 'assets/images/brand_7.png'},
      {'name': 'Colgate', 'image': 'assets/images/brand_1.png'},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        title: Row(
          children: [
            if (_user?.role.toLowerCase() == 'admin') ...[
              const Text(
                'ADMIN',
                style: TextStyle(
                  color: Color(0xFF9B1B1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
            ] else ...[
              const Icon(Icons.location_on, color: Colors.black, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/address-list');
                  },
                  child: _buildAddressSection(),
                ),
              ),
              const Spacer(),
            ],
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            if (_user?.role.toLowerCase() == 'customer')
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart').then((_) {
                        _fetchCartCount();
                      });
                    },
                  ),
                  if (_cartCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for groceries and more',
                            prefixIcon: const Icon(Icons.search),
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
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F6F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _appName,
                                    style: const TextStyle(
                                      color: Color(0xFFB00060),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'shop purchases made easy',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Delivering in',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: const [
                                    Icon(Icons.flash_on, color: Color(0xFFB00060), size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      '12 Hrs',
                                      style: TextStyle(
                                        color: Color(0xFFB00060),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(thickness: 1, color: Color(0xFFE0CFE6)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'want branded products for your retail store ? We are here to deliver all branded products in your retail store.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/images/hourglass_illustration.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Store Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_categories.isEmpty)
                    const Center(child: Text('No categories found'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/product-list',
                              arguments: cat,
                            );
                          },
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  cat.imageUrl,
                                  width: double.infinity,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  _buildAdvertisingCarousel(),
                  const SizedBox(height: 18),
                  const Text(
                    'Brands In Store',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isBrandsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_brandsError != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_brandsError!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadBrands,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_brands.isEmpty)
                    const Center(child: Text('No brands found'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _brands.length,
                      itemBuilder: (context, index) {
                        final brand = _brands[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            brand['image_url'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
                                  child: Text('No results found'),
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
                                    final prod = _searchResults[index];
                                    return ListTile(
                                      leading: prod['PROD_IMAGE_1'] != null && prod['PROD_IMAGE_1'].toString().isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                '${prod['PROD_IMAGE_1']}',
                                                width: 38,
                                                height: 38,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.image, size: 38, color: Colors.grey),
                                      title: _highlightSearchTerm(prod['PROD_NAME'] ?? '', _searchController.text.trim()),
                                      onTap: () => _onSearchResultTap(prod),
                                    );
                                  },
                                ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _user?.role.toLowerCase() == 'customer'
        ? Stack(
            children: [
              FloatingActionButton(
                backgroundColor: const Color(0xFF9B1B1B),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart').then((_) {
                    // Refresh cart count when returning from cart page
                    _fetchCartCount();
                  });
                },
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _cartCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9B1B1B),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/orders');
              break;
            case 1:
              Navigator.pushNamed(context, '/product-list');
              break;
            case 2:
              if (_user?.role?.toLowerCase() == 'admin') {
                Navigator.pushNamed(context, '/retailer-list');
              } else {
              Navigator.pushNamed(context, '/self-retailer-detail');
              }
              break;
            case 3:
              // Already on search
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

  Widget _buildAddressSection() {
    if (_isLoadingLocation) {
      return const SizedBox(
        height: 18,
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Web Browser',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'Location features available in mobile app',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_defaultAddress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (_defaultAddress!.addressType == 'Current Location')
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _getCurrentLocation,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Access Required',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          _locationError ?? 'Enable location for better service',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _highlightSearchTerm(String text, String term) {
    if (term.isEmpty) return Text(text);
    final lcText = text.toLowerCase();
    final lcTerm = term.toLowerCase();
    final start = lcText.indexOf(lcTerm);
    if (start == -1) return Text(text);
    final end = start + term.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
} 