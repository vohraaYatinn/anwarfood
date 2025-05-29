import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import 'auth_service.dart';

class CategoryService {
  static const String baseUrl = 'https://anwarfood.onrender.com';
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('https://anwarfood.onrender.com/api/categories/list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> categoriesJson = data['data'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load categories');
    }
  }
} 