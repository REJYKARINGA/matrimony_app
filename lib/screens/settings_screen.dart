import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'profile_screen_view.dart';
import 'matching_screen.dart';
import 'profile_photos_screen.dart';
import 'account_settings_screen.dart';
import 'contact_us_screen.dart';
import 'engagement_poster_info_screen.dart';
import 'search_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'security_settings_screen.dart';
import 'verification_screen.dart';
import 'share_suggestion_screen.dart';
import 'notification_settings_screen.dart';

import '../services/payment_service.dart';
import 'wallet_transactions_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _walletBalance = 0.0;
  bool _isWalletLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    if (!mounted) return;
    setState(() => _isWalletLoading = true);
    try {
      final response = await PaymentService.getWalletBalance();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
            _isWalletLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWalletLoading = false);
      }
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

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showDivider = true,
  }) {
    final gradientColor = iconColor ?? const Color(0xFF00BCD4); // Turquoise

    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gradientColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: gradientColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                )
              : null,
          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Colors.grey[200],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profile = user?.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF5F7F9),
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        bottom: PreferredSize(
          child: Container(color: Colors.grey.shade100, height: 1.5),
          preferredSize: const Size.fromHeight(1.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletTransactionsScreen()),
                );
                _loadWalletBalance();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF00BCD4)),
                    const SizedBox(width: 6),
                    _isWalletLoading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00BCD4),
                            ),
                          )
                        : Text(
                            '₹${_walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.loadCurrentUserWithProfile();
          await _loadWalletBalance();
        },
        child: ListView(
          children: [
            // Enhanced Profile Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.1), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.displayImage != null &&
                              user!.displayImage!.isNotEmpty
                          ? NetworkImage(
                              ApiService.getImageUrl(user.displayImage!),
                            )
                          : null,
                      child: user?.displayImage == null ||
                              user!.displayImage!.isEmpty
                          ? Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00BCD4), // Turquoise
                                    Color(0xFF0D47A1), // Deep Blue
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  profile?.firstName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile?.firstName ?? 'User'} ${profile?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              user?.matrimonyId ?? 'ID: -',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (user?.matrimonyId != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: user!.matrimonyId!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Matrimony ID copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: Color(0xFF00BCD4),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: Color(0xFF4CD9A6), size: 24),
                ],
              ),
            ),

            // Profile Management Section
            _buildSectionHeader('PROFILE MANAGEMENT'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person,
                    title: 'View/Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.photo_library,
                    title: 'Manage Photos',
                    subtitle: 'Add or remove profile photos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePhotosScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.celebration,
                    title: 'Engagement Poster',
                    subtitle: 'Share your special moment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EngagementPosterInfoScreen(),
                        ),
                      );
                    },
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.verified_user_outlined,
                    title: 'Verify Account',
                    subtitle: 'Verify your ID for a trusted profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VerificationScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Search & Discovery Section
            _buildSectionHeader('SEARCH & DISCOVERY'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.search,
                    title: 'Search Profiles',
                    subtitle: 'Find potential matches',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.account_balance_wallet,
                    title: 'Wallet & Transactions',
                    subtitle: 'Recharge and view history',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WalletTransactionsScreen(),
                        ),
                      );
                      _loadWalletBalance();
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Account & Privacy Section
            _buildSectionHeader('ACCOUNT & PRIVACY'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings,
                    title: 'Account Settings',
                    subtitle: 'Privacy, security & preferences',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.history_rounded,
                    title: 'Security & Login History',
                    subtitle: 'Check recent login activity',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecuritySettingsScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Support & Feedback Section
            _buildSectionHeader('SUPPORT & FEEDBACK'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactUsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.rate_review,
                    title: 'Share Suggestion',
                    subtitle: 'Help us improve the app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShareSuggestionScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Logout Section
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMenuItem(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                iconColor: Colors.red,
                textColor: Colors.red,
                showDivider: false,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 28),
                            const SizedBox(width: 12),
                            const Text('Confirm Logout'),
                          ],
                        ),
                        content: const Text(
                          'Are you sure you want to logout from your account?',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              authProvider.logout();
                              Navigator.of(dialogContext).pop();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // App Version Footer
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  // Legal Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndConditionsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2025 All Rights Reserved',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}