import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import 'auth_service.dart';

class CategoryService {
  static const String baseUrl = 'http://192.168.29.96:3000';
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('http://192.168.29.96:3000/api/categories/list'),
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

  Future<List<Map<String, dynamic>>> getSubCategories(int categoryId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories/$categoryId/subcategories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data'].map((x) => {
            'id': x['SUB_CATEGORY_ID'],
            'name': x['SUB_CATEGORY_NAME'],
            'catId': x['SUB_CATEGORY_CAT_ID'],
            'image': x['SUB_CAT_IMAGE'],
          }));
        }
        throw Exception(data['message'] ?? 'Failed to load subcategories');
      }
      throw Exception('Failed to load subcategories');
    } catch (e) {
      throw Exception('Error loading subcategories: $e');
    }
  }

  Future<List<SubCategory>> getSubCategoriesByCategoryId(int categoryId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories/$categoryId/subcategories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> subCategoriesJson = data['data'];
      return subCategoriesJson.map((json) => SubCategory.fromJson(json)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load subcategories');
    }
  }
} 