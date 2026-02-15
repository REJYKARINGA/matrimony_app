import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';


class ApiService {
  // static String get baseUrl {
  //   // Always use Railway production URL
  //   return 'https://matrimonybackend-production.up.railway.app/api';

  //   // Uncomment these lines if you want to test locally during development
  //   // if (kIsWeb) {
  //   //   return 'http://localhost:8000/api';
  //   // }
  //   // if (defaultTargetPlatform == TargetPlatform.android) {
  //   //   return 'http://192.168.220.3:8000/api';
  //   // }
  //   // return 'http://localhost:8000/api';
  // }

  static String get baseUrl => AppConfig.baseUrl;

  static String get authUrl => '$baseUrl/auth';

  // Store token in SharedPreferences
  static Future<void> storeToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Generic method to make authenticated requests
  static Future<http.Response> makeRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? token = await getToken();

    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    return response;
  }

  // Authentication methods
  static Future<http.Response> register({
    required String email,
    String? phone,
    required String password,
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': role,
      }),
    );
    return response;
  }

  static Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return response;
  }

  static Future<http.Response> logout() async {
    final response = await makeRequest('$authUrl/logout', method: 'POST');
    if (response.statusCode == 200) {
      await removeToken();
    }
    return response;
  }

  static Future<http.Response> getUser() async {
    final response = await makeRequest('$authUrl/user');
    return response;
  }

  static Future<http.Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await makeRequest(
      '$authUrl/change-password',
      method: 'POST',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );
    return response;
  }

  static Future<http.Response> updateUserInfo(
    Map<String, dynamic> userData,
  ) async {
    final response = await makeRequest(
      '$authUrl/update-info',
      method: 'PUT',
      body: userData,
    );
    return response;
  }

  static Future<http.Response> deleteAccount() async {
    final response = await makeRequest(
      '$authUrl/delete-account',
      method: 'DELETE',
    );
    if (response.statusCode == 200) {
      await removeToken(); // Remove token after successful account deletion
    }
    return response;
  }

  static Future<http.Response> createEngagementPoster(
    Map<String, dynamic> postData,
    File imageFile,
  ) async {
    String? token = await getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/engagement-posters'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add form fields
    postData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add image file if provided
    if (imageFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'poster_image',
          await imageFile.readAsBytes(),
          filename: imageFile.path
              .split('\\')
              .last
              .split('/')
              .last, // Handle both Windows and Unix paths
        ),
      );
    }

    var response = await request.send();
    return await http.Response.fromStream(response);
  }

  // Forgot Password Methods
  static Future<http.Response> sendOtp({required String email}) async {
    final response = await http.post(
      Uri.parse('$authUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response;
  }

  static Future<http.Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response;
  }

  static Future<http.Response> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': newPassword,
        'password_confirmation': newPassword,
      }),
    );
    return response;
  }

  // Helper method to construct proper image URLs
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // Ensure relative paths start with a slash
    String path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    
    // For web, use the proxy to avoid CORS issues
    if (kIsWeb && path.startsWith('/storage/')) {
      return '$baseUrl/images/proxy?path=${Uri.encodeComponent(path)}';
    }
    
    // If it's a storage path but doesn't have the base URL
    if (path.startsWith('/storage/')) {
      return baseUrl.replaceAll('/api', '') + path;
    }
    
    // Fallback: append to base URL (without /api)
    return baseUrl.replaceAll('/api', '') + path;
  }

  // Test method for Reverb broadcasting
  static Future<http.Response> triggerTestBroadcast() async {
    // Hit the /api/auth/test-broadcast endpoint
    return await makeRequest('$authUrl/test-broadcast');
  }
}
