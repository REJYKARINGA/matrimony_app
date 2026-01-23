import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    String? token = await ApiService.getToken();
    if (token != null) {
      // Token exists, try to load the user
      await loadCurrentUser();
    }
  }

  Future<bool> register({
    required String email,
    String? phone,
    required String password,
    String role = 'user',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        
        // Store the token
        if (data['token'] != null) {
          await ApiService.storeToken(data['token']);
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['error'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        
        // Store the token
        if (data['token'] != null) {
          await ApiService.storeToken(data['token']);
        }
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['error'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await ApiService.getUser();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> loadCurrentUserWithProfile() async {
    try {
      final response = await ApiService.getUser();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        notifyListeners();
        return true;
      } else {
        // If API returns non-200, clear the user and token
        await ApiService.removeToken();
        _user = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadCurrentUser() async {
    try {
      final response = await ApiService.getUser();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        notifyListeners();
        return true;
      } else {
        // If API returns non-200, clear the user and token
        await ApiService.removeToken();
        _user = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // If API call fails (e.g., network error), we still have a token
      // so we can assume the user was previously authenticated
      // We'll return true to allow access but the user data might be stale
      // until they refresh or make another API call
      String? token = await ApiService.getToken();
      if (token != null) {
        // We have a token, so the user was previously authenticated
        // Even though we couldn't fetch fresh user data, we'll return true
        // This allows the app to continue as if the user is logged in
        return true;
      }
      return false;
    }
  }

  Future<bool> sendOtp({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.sendOtp(email: email);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'OTP sent successfully';
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'OTP verified successfully';
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['error'] ?? 'Invalid OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.resetPassword(
        email: email,
        newPassword: newPassword,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Password reset successfully';
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['error'] ?? 'Failed to reset password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}