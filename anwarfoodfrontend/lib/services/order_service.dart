import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getOrders() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders/details/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> adminGetOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/get-order-details/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> adminUpdateOrderStatus(int orderId, String status, {String? notes}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/admin/edit-order-status/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'orderNotes': notes ?? '',
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/orders/cancel/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/orders/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminOrders(String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/fetch-all-orders?status=$status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch admin orders');
      }
    } catch (e) {
      throw Exception('Error fetching admin orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> adminSearchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/admin/search-orders?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> getEmployeeOrders() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/employee/orders?status=confirmed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch employee orders');
      }
    } catch (e) {
      throw Exception('Error fetching employee orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> employeeSearchOrders(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/employee/orders/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']['orders']);
      } else {
        throw Exception(data['message'] ?? 'Failed to search orders');
      }
    } catch (e) {
      throw Exception('Error searching orders: $e');
    }
  }

  Future<Map<String, dynamic>> employeeGetOrderDetails(int orderId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/employee/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      throw Exception('Error fetching order details: $e');
    }
  }

  Future<Map<String, dynamic>> employeeUpdateOrderStatus(int orderId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/employee/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }
} 