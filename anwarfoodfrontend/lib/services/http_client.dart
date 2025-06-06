import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class HttpClient {
  static const String baseUrl = 'http://localhost:3000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static http.Client _client = http.Client();

  // Configure HTTP client for mobile
  static void configureClient() {
    _client = http.Client();
  }

  // GET request with proper error handling
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making GET request to: $uri');
    
    try {
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('Error in GET request: $e');
      throw Exception('Request failed: $e');
    }
  }

  // POST request with proper error handling
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making POST request to: $uri');
    if (body != null) {
      print('Request body: ${jsonEncode(body)}');
    }
    
    try {
      final response = await _client
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('Error in POST request: $e');
      throw Exception('Request failed: $e');
    }
  }

  // PUT request with proper error handling
  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    print('Making PUT request to: $uri');
    
    try {
      final response = await _client
          .put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeoutDuration);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('Error in PUT request: $e');
      throw Exception('Request failed: $e');
    }
  }

  // Close the client
  static void close() {
    _client.close();
  }
} 