import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'auth_service.dart';

class ProductService {
  static const String baseUrl = 'https://anwarfood.onrender.com';
  final AuthService _authService = AuthService();

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse('https://anwarfood.onrender.com/api/products/category/$categoryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> productsJson = data['data'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load products');
    }
  }

  Future<Product> getProductDetails(int productId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse('https://anwarfood.onrender.com/api/products/details/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      return Product.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to load product details');
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      final response = await http.get(
        Uri.parse('https://anwarfood.onrender.com/api/products/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search products');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }
} 