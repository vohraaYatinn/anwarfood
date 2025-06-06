import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RetailerService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getRetailerList({int page = 1, int limit = 5, String status = 'active'}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/get-all-retailer-list?page=$page&limit=$limit&status=$status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch retailers');
      }
    } catch (e) {
      throw Exception('Error fetching retailers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchRetailers(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/retailers/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search retailers');
      }
    } catch (e) {
      throw Exception('Error searching retailers: $e');
    }
  }

  Future<Map<String, dynamic>> getRetailerDetails(int retailerId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/retailers/admin/retailer-details/$retailerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch retailer details');
      }
    } catch (e) {
      throw Exception('Error fetching retailer details: $e');
    }
  }
} 