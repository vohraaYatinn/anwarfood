import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<Map<String, dynamic>> addProductWithImages(
    Map<String, dynamic> productData, 
    Map<String, File> files
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.29.96:3000/api/admin/add-product'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add image files with proper content type
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        // Get file extension
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Determine content type based on file extension
        String contentType = 'image/jpeg'; // default
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
        
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );
        
        request.files.add(multipartFile);
      }

      print('Sending multipart request with fields: ${request.fields.keys.toList()}');
      print('Sending files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})').toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add product');
      }
    } catch (e) {
      print('Error in addProductWithImages: $e');
      throw Exception('Error adding product with images: $e');
    }
  }

  Future<Map<String, dynamic>> updateProductWithImages(
    int productId,
    Map<String, dynamic> productData, 
    Map<String, File> files,
    {List<int> removeImages = const []}
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://192.168.29.96:3000/api/admin/edit-product/$productId'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add removeImages if any
      if (removeImages.isNotEmpty) {
        request.fields['removeImages'] = jsonEncode(removeImages);
      }

      // Add image files with proper content type
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        // Get file extension
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Determine content type based on file extension
        String contentType = 'image/jpeg'; // default
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
        
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );
        
        request.files.add(multipartFile);
      }

      print('Sending multipart update request with fields: ${request.fields.keys.toList()}');
      print('Sending files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})').toList()}');
      print('Remove images: $removeImages');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update product');
      }
    } catch (e) {
      print('Error in updateProductWithImages: $e');
      throw Exception('Error updating product with images: $e');
    }
  }
} 