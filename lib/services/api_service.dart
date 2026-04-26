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

  static Future<http.Response> getLoginHistory() async {
    final response = await makeRequest('$authUrl/login-history');
    return response;
  }

  static Future<http.Response> sendEmailOtp({
    required String email,
    bool isSignup = false,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/send-email-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'is_signup': isSignup}),
    );
    return response;
  }

  static Future<http.Response> sendPhoneOtp({
    required String phone,
    bool isSignup = false,
    bool isReset = false,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/send-phone-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'is_signup': isSignup, 'is_reset': isReset}),
    );
    return response;
  }

  static Future<http.Response> verifyPhoneOtp({
    required String sessionId,
    required String otp,
    String? phone,
    bool isReset = false,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/verify-phone-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'otp': otp,
        if (phone != null) 'phone': phone,
        'is_reset': isReset
      }),
    );
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

  static Future<http.Response> submitSuggestion(
    String title,
    String? category,
    String description,
    List<Map<String, dynamic>> photos,
  ) async {
    String? token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/suggestions'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    if (category != null) {
      request.fields['category'] = category;
    }
    request.fields['description'] = description;

    for (int i = 0; i < photos.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'user_photos[]',
          photos[i]['bytes'],
          filename: photos[i]['fileName'],
        ),
      );
    }

    var response = await request.send();
    return await http.Response.fromStream(response);
  }

  static Future<http.Response> getMySuggestions() async {
    return await makeRequest('$baseUrl/suggestions');
  }

  static Future<http.Response> createEngagementPoster(
    Map<String, dynamic> postData,
    Uint8List imageBytes,
    String fileName,
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
    request.files.add(
      http.MultipartFile.fromBytes(
        'poster_image',
        imageBytes,
        filename: fileName,
      ),
    );

    var response = await request.send();
    return await http.Response.fromStream(response);
  }

  static Future<http.Response> getMyEngagementPoster() async {
    return await makeRequest('$baseUrl/engagement-posters/my');
  }

  static Future<http.Response> updateEngagementPoster(
    int posterId,
    Map<String, dynamic> postData, {
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    String? token = await getToken();

    var request = http.MultipartRequest(
      'POST', // Laravel multipart forms use POST with _method=PUT
      Uri.parse('$baseUrl/engagement-posters/$posterId'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Spoof PUT for Laravel
    request.fields['_method'] = 'PUT';

    // Add form fields
    postData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add image file only if a new one was selected
    if (imageBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'poster_image',
          imageBytes,
          filename: fileName,
        ),
      );
    }

    var response = await request.send();
    return await http.Response.fromStream(response);
  }

  static Future<http.Response> respondToEngagementPoster(int id, String status) async {
    return await makeRequest(
      '$baseUrl/engagement-posters/$id/partner-confirm',
      method: 'POST',
      body: {'status': status},
    );
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

  // Preferences methods
  static Future<http.Response> updatePreferences(Map<String, dynamic> preferences) async {
    return await makeRequest(
      '$baseUrl/notification-settings',
      method: 'PUT',
      body: preferences,
    );
  }

  static Future<http.Response> getNotificationSettings() async {
    return await makeRequest('$baseUrl/notification-settings');
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
