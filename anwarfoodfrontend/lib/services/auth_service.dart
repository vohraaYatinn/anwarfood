import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'onboarding_completed';

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authLogin),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          // Store token in both secure storage and shared preferences
          await _storage.write(key: 'token', value: data['token']);
          await _saveToken(data['token']);
          
          // Store user data if available
          if (data['user'] != null) {
            await _saveUser(User.fromJson(data['user']));
          }
        }
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Password Reset Methods
  Future<Map<String, dynamic>> requestPasswordReset(String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authRequestPasswordReset),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'phone': phone,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authResendOtp),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'phone': phone,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> confirmOtpForPassword(String phone, String verificationCode, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authConfirmOtpForPassword),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'phone': phone,
          'verification_code': verificationCode,
          'otp': otp,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithPhone(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authResetPasswordWithPhone),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<String?> getToken() async {
    // First try to get from secure storage
    final secureToken = await _storage.read(key: 'token');
    if (secureToken != null) {
      return secureToken;
    }
    
    // Fallback to shared preferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all stored data
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await _storage.delete(key: 'token');
    // Clear all other stored data if any
    await prefs.clear();
  }

  // Onboarding methods
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Clear all cached data including any localhost references
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _storage.deleteAll();
    print('All cached data cleared');
  }
} 