import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CartService {
  static const String baseUrl = 'http://localhost:3000';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
    required int unitId,
  }) async {
    print('addToCart method called with productId: $productId, quantity: $quantity, unitId: $unitId');
    final token = await _authService.getToken();
    print('Token retrieved: $token');
    if (token == null) throw Exception('No authentication token found');
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'unitId': unitId,
      }),
    );
    print('addToCart response status: ${response.statusCode}');
    final data = jsonDecode(response.body);
    print('addToCart response body: $data');
    return data;
  }

  Future<Map<String, dynamic>> getCartCount() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to get cart count');
      }
    } catch (e) {
      throw Exception('Error getting cart count: $e');
    }
  }
} 