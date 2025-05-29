class ApiConfig {
  // Production API URL
  static const String baseUrl = 'https://anwarfood.onrender.com';
  
  // API Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authSignup = '/api/auth/signup';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String categoriesList = '/api/categories/list';
  static const String productsList = '/api/products/list';
  static const String productsSearch = '/api/products/search';
  static const String cartAdd = '/api/cart/add';
  static const String cartFetch = '/api/cart/fetch';
  static const String cartIncreaseQuantity = '/api/cart/increase-quantity';
  static const String cartDecreaseQuantity = '/api/cart/decrease-quantity';
  static const String cartPlaceOrder = '/api/cart/place-order';
  static const String addressList = '/api/address/list';
  static const String addressAdd = '/api/address/add';
  static const String addressEdit = '/api/address/edit';
  static const String addressDefault = '/api/address/default';
  static const String ordersList = '/api/orders/list';
  static const String ordersDetails = '/api/orders/details';
  static const String retailersMyRetailer = '/api/retailers/my-retailer';
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Test connectivity
  static String get healthCheckUrl => '$baseUrl/health';
  
  // Debug info
  static void printApiInfo() {
    print('=== API CONFIGURATION ===');
    print('Base URL: $baseUrl');
    print('Timeout: ${timeout.inSeconds} seconds');
    print('Health Check: $healthCheckUrl');
    print('========================');
  }
} 