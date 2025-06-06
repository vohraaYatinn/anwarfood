import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class BrandService {
  final AuthService _authService = AuthService();
  final String baseUrl = 'http://localhost:3000/api';

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/settings/brands'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch brands');
      }
    } catch (e) {
      throw Exception('Error fetching brands: $e');
    }
  }
} 