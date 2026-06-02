import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

class VersionInfo {
  final String minimumVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? updateUrl;
  final String? storeUrl;

  VersionInfo({
    required this.minimumVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.updateUrl,
    this.storeUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      minimumVersion: json['minimum_version'] as String? ?? '1.0.0',
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      forceUpdate: json['force_update'] as bool? ?? false,
      updateUrl: json['update_url'] as String?,
      storeUrl: json['store_url'] as String?,
    );
  }
}

class VersionCheckService {
  static const String _cacheKey = 'cached_version_info';
  static const String _lastCheckKey = 'last_version_check';
  static const Duration _cacheDuration = Duration(hours: 24);

  static Future<VersionInfo?> fetchVersionInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/app-version'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versionInfo = VersionInfo.fromJson(
          data is Map<String, dynamic> ? data : (data['data'] ?? data),
        );

        await _cacheVersionInfo(versionInfo);
        return versionInfo;
      }
    } catch (_) {}

    return await _getCachedVersionInfo();
  }

  static Future<bool> isUpdateRequired() async {
    final info = await fetchVersionInfo();
    if (info == null) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    return compareVersions(currentVersion, info.minimumVersion) < 0;
  }

  static Future<bool> isForceUpdateRequired() async {
    final info = await fetchVersionInfo();
    if (info == null) return false;

    if (!info.forceUpdate) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    return compareVersions(currentVersion, info.minimumVersion) < 0;
  }

  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1 - p2;
    }
    return 0;
  }

  static Future<void> _cacheVersionInfo(VersionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'minimum_version': info.minimumVersion,
      'latest_version': info.latestVersion,
      'force_update': info.forceUpdate,
      'update_url': info.updateUrl,
      'store_url': info.storeUrl,
    }));
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  static Future<VersionInfo?> _getCachedVersionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_lastCheckKey);
    if (lastCheck == null) return null;

    final lastCheckTime = DateTime.tryParse(lastCheck);
    if (lastCheckTime == null) return null;

    final cacheAge = DateTime.now().difference(lastCheckTime);
    if (cacheAge > _cacheDuration) return null;

    final cached = prefs.getString(_cacheKey);
    if (cached == null) return null;

    return VersionInfo.fromJson(jsonDecode(cached));
  }
}
