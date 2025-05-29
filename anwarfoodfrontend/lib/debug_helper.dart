import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/category_service.dart';
import 'services/cart_service.dart';
import 'services/address_service.dart';
import 'services/http_client.dart';
import 'config/api_config.dart';

class DebugHelper {
  static void logAllServiceUrls() {
    print('=== SERVICE URL VERIFICATION ===');
    print('API Config Base URL: ${ApiConfig.baseUrl}');
    print('HTTP Client Base URL: ${HttpClient.baseUrl}');
    print('Auth Service Base URL: ${AuthService.baseUrl}');
    print('Product Service Base URL: ${ProductService.baseUrl}');
    print('Category Service Base URL: ${CategoryService.baseUrl}');
    print('Cart Service Base URL: ${CartService.baseUrl}');
    print('Address Service Base URL: ${AddressService.baseUrl}');
    print('Order Service: Uses hardcoded https://anwarfood.onrender.com');
    print('================================');
    
    // Print API configuration
    ApiConfig.printApiInfo();
  }

  static void clearAllAppData() async {
    final authService = AuthService();
    await authService.clearAllCache();
    print('All app data cleared!');
  }
} 