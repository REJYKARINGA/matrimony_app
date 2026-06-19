import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_theme_config.dart';
import 'api_service.dart';
import '../utils/app_colors.dart';

class ThemeConfigService {
  static ThemeConfigService? _instance;
  AppThemeConfig? _config;

  ThemeConfigService._();

  static ThemeConfigService get instance {
    _instance ??= ThemeConfigService._();
    return _instance!;
  }

  AppThemeConfig get config {
    if (_config != null) return _config!;
    return AppThemeConfig();
  }

  bool get isLoaded => _config != null;

  Future<void> load() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await ApiService.makeRequest(
        '${ApiService.baseUrl}/config/theme',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _config = AppThemeConfig.fromJson(data);
        
        // Update AppColors globally
        AppColors.primaryGreen = _config!.primaryColor;
        AppColors.deepGreen = _config!.secondaryColor;
        AppColors.darkGreen = _config!.darkPrimary;
        AppColors.mintTint = _config!.primaryColor.withOpacity(0.2);
        AppColors.softMint = _config!.primaryColor.withOpacity(0.1);
        
        debugPrint('THEME_CONFIG: loaded successfully');
      } else {
        debugPrint('THEME_CONFIG: status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ThemeConfigService._fetch ERROR: $e');
    }
  }
}
