import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RetailerService {
  static const String baseUrl = 'http://192.168.29.96:3000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get retailers for employee with pagination
  Future<Map<String, dynamic>> getRetailers({
    int page = 1,
    int limit = 10,
    String status = 'active',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/employee/retailers')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
      });

      print('Fetching retailers from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailers response status: ${response.statusCode}');
      print('Retailers response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailers');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailers. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailers: $e');
      rethrow;
    }
  }

  // Search retailers for employee
  Future<List<Map<String, dynamic>>> searchRetailers(String query) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/employee/retailers/search')
          .replace(queryParameters: {'query': query});

      print('Searching retailers with query: $query');
      print('Search URL: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['retailers'] as List).cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to search retailers');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to search retailers. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in searchRetailers: $e');
      rethrow;
    }
  }

  // Store selected retailer phone number
  Future<void> storeSelectedRetailerPhone(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_retailer_phone', phoneNumber);
      print('Stored retailer phone: $phoneNumber');
    } catch (e) {
      print('Error storing retailer phone: $e');
      throw Exception('Failed to store retailer information');
    }
  }

  // Get stored retailer phone number
  Future<String?> getSelectedRetailerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_retailer_phone');
    } catch (e) {
      print('Error getting retailer phone: $e');
      return null;
    }
  }

  // Clear stored retailer phone number
  Future<void> clearSelectedRetailerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_retailer_phone');
      print('Cleared stored retailer phone');
    } catch (e) {
      print('Error clearing retailer phone: $e');
    }
  }

  // Legacy methods for backward compatibility
  Future<Map<String, dynamic>> getRetailerList({
    int page = 1,
    int limit = 5,
    String status = 'active',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/admin/get-all-retailer-list')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
      });

      print('Fetching retailer list from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailer list response status: ${response.statusCode}');
      print('Retailer list response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer list');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailer list. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailerList: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRetailerDetails(int retailerId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/retailers/admin/retailer-details/$retailerId');

      print('Fetching retailer details from: $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      );

      print('Retailer details response status: ${response.statusCode}');
      print('Retailer details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch retailer details');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch retailer details. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      print('Error in getRetailerDetails: $e');
      rethrow;
    }
  }
} 