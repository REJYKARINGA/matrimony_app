import '../../../../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';
import '../utils/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  // Notification Preferences
  bool _pushNotifications = true;
  bool _newMatches = true;
  bool _messages = true;
  bool _profileViews = true;
  bool _interestRequests = true;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // 1. Try to load from backend first
      final response = await ApiService.getNotificationSettings();
      if (response.statusCode == 200) {
        final settingsData = jsonDecode(response.body)['data'];
        
        if (settingsData != null) {
          setState(() {
            _pushNotifications = _parseBool(settingsData['notify_push'], true);
            _newMatches = _parseBool(settingsData['notify_matches'], true);
            _messages = _parseBool(settingsData['notify_messages'], true);
            _profileViews = _parseBool(settingsData['notify_profile_views'], true);
            _interestRequests = _parseBool(settingsData['notify_interests'], true);
            _emailNotifications = _parseBool(settingsData['notify_email'], true);
          });
          
          // Sync local storage with backend data
          final localPrefs = await SharedPreferences.getInstance();
          await localPrefs.setBool('pref_push_notifications', _pushNotifications);
          await localPrefs.setBool('pref_new_matches', _newMatches);
          await localPrefs.setBool('pref_messages', _messages);
          await localPrefs.setBool('pref_profile_views', _profileViews);
          await localPrefs.setBool('pref_interest_requests', _interestRequests);
          await localPrefs.setBool('pref_email_notifications', _emailNotifications);
          
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Fallback to local SharedPreferences if backend fails or doesn't have data
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('pref_push_notifications') ?? true;
        _newMatches = prefs.getBool('pref_new_matches') ?? true;
        _messages = prefs.getBool('pref_messages') ?? true;
        _profileViews = prefs.getBool('pref_profile_views') ?? true;
        _interestRequests = prefs.getBool('pref_interest_requests') ?? true;
        _emailNotifications = prefs.getBool('pref_email_notifications') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  Future<void> _updateSetting(String localKey, String backendKey, bool value) async {
    try {
      // 1. Update local storage immediately for responsive UI
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(localKey, value);

      // 2. Sync with backend
      final response = await ApiService.updatePreferences({
        backendKey: value,
      });

      if (response.statusCode != 200) {
        debugPrint('Failed to sync notification setting to backend: ${response.body}');
        // Optionally show a subtle warning to the user
      }
    } catch (e) {
      debugPrint('Error syncing to backend: $e');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isMaster = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isMaster ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          value: value,
          activeColor: AppColors.deepEmerald,
          onChanged: (newValue) {
            onChanged(newValue);
          },
        ),
        if (!isMaster)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey[200],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.backgroundLight,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.cardDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: AppColors.midnightEmerald, height: 1.5),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepEmerald),
            )
          : ListView(
              children: [
                _buildSectionHeader('PUSH NOTIFICATIONS'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white70.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        title: 'Allow Push Notifications',
                        subtitle: 'Enable or disable all push notifications',
                        value: _pushNotifications,
                        isMaster: true,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                            _updateSetting('pref_push_notifications', 'notify_push', val);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (_pushNotifications) ...[
                  _buildSectionHeader('NOTIFICATION TYPES'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white70.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchItem(
                          title: 'New Matches',
                          subtitle: 'Get notified when we find a new match',
                          value: _newMatches,
                          onChanged: (val) {
                            setState(() {
                              _newMatches = val;
                              _updateSetting('pref_new_matches', 'notify_matches', val);
                            });
                          },
                        ),
                        _buildSwitchItem(
                          title: 'Messages',
                          subtitle: 'Get notified when you receive a new message',
                          value: _messages,
                          onChanged: (val) {
                            setState(() {
                              _messages = val;
                              _updateSetting('pref_messages', 'notify_messages', val);
                            });
                          },
                        ),
                        _buildSwitchItem(
                          title: 'Profile Views',
                          subtitle: 'Know when someone visits your profile',
                          value: _profileViews,
                          onChanged: (val) {
                            setState(() {
                              _profileViews = val;
                              _updateSetting('pref_profile_views', 'notify_profile_views', val);
                            });
                          },
                        ),
                        _buildSwitchItem(
                          title: 'Interest Requests',
                          subtitle: 'Alerts for new or accepted interests',
                          value: _interestRequests,
                          onChanged: (val) {
                            setState(() {
                              _interestRequests = val;
                              _updateSetting('pref_interest_requests', 'notify_interests', val);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                _buildSectionHeader('EMAIL SETTINGS'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white70.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        title: 'Email Notifications',
                        subtitle: 'Receive updates and recommendations via email',
                        value: _emailNotifications,
                        isMaster: true,
                        onChanged: (val) {
                          setState(() {
                            _emailNotifications = val;
                            _updateSetting('pref_email_notifications', 'notify_email', val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}















