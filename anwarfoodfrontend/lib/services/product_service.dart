import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProductService {
  final AuthService _authService = AuthService();

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse(ApiConfig.productsByCategory(categoryId)),
      headers: ApiConfig.defaultHeaders,
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> productsJson = data['data'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load products');
    }
  }

  Future<List<Product>> getProductsBySubCategory(int subCategoryId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await http.get(
      Uri.parse('http://192.168.29.96:3000/api/products/subcategory/$subCategoryId'),
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
      Uri.parse('http://192.168.29.96:3000/api/products/details/$productId'),
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

  Future<List<Map<String, dynamic>>> searchProducts(String query, {int? subcategoryId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://192.168.29.96:3000/api/products/search?query=$query'),
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
      throw Exception('Failed to search products: $e');
    }
  }

  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.put(
        Uri.parse('http://192.168.29.96:3000/api/admin/edit-product/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse('http://192.168.29.96:3000/api/admin/add-product'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(productData),
      );
      
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }
} 