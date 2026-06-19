import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepEmerald,
                AppColors.deepEmerald,
              ],
            ),
          ),
        ),
        foregroundColor: AppColors.cardDark,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              AppColors.cardDark,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              'WELCOME TO NIKKAH MATCH',
              [
                'Nikkah Match is a newly launched platform (2026) dedicated to providing a trusted and sincere matchmaking experience. We use the best-in-class features to keep scammers and fake profiles away, ensuring a safe environment for genuine seekers. Your privacy is our priority, and we are committed to protecting your personal information.',
                'This Privacy Policy explains how we collect, use, share, and safeguard your information when you use our mobile application, website, and related services (collectively referred to as the "Service").',
                'By using our Service, you agree to the practices described in this Privacy Policy. If you do not agree, please discontinue use of the Service immediately.',
              ],
            ),
            _buildSection(
              'INFORMATION WE COLLECT',
              [
                'Account Information: Name, email address, phone number, gender, date of birth, and password.',
                'Profile Information: Photos, videos, preferences, bio, interests, and other personal details you choose to share.',
                'Communication Data: Messages, chats, and interactions with other users.',
                'Payment Information: Details for premium services or subscriptions (processed securely through third-party payment providers).',
                'Selfie Verification Data: If you opt to verify your identity using our selfie verification feature, we may collect your photo and use it to confirm your identity.',
              ],
            ),
            _buildSection(
              'AUTOMATICALLY COLLECTED INFORMATION',
              [
                'Device Information: IP address, device type, operating system, browser type, and app usage data.',
                'Precise Location: GPS data collected with your explicit consent to provide location-based features (e.g., matches nearby).',
                'Approximate Location: Derived from your IP address for general location services.',
                'Usage Data: Interactions within the app, such as swipes, likes, and time spent on features.',
              ],
            ),
            _buildSection(
              'COOKIES AND TRACKING TECHNOLOGIES',
              [
                'Cookies: Small files stored on your device to remember preferences, improve app functionality, and analyze performance.',
                'Web Beacons and Pixels: Tiny graphics embedded in our app or emails to track engagement and app usage.',
                'Log Data: Automatically collected information about your interactions, such as pages viewed and features used.',
              ],
            ),
            _buildSection(
              'HOW WE USE YOUR INFORMATION',
              [
                'Create your account and manage your profile.',
                'Suggest compatible matches and enhance interactions.',
                'Use geolocation to display nearby matches and calculate approximate distances.',
                'Enable and process selfie verification to ensure the authenticity of user accounts.',
                'Remember your preferences and login information.',
                'Track app performance and user behavior to improve our features.',
                'Provide tailored advertising based on your interactions.',
                'Detect and prevent unauthorized access, fraud, or abuse.',
                'Monitor for suspicious activities to maintain platform safety.',
                'Send you notifications, updates, and promotional messages.',
                'Respond to customer service inquiries.',
                'Analyze usage trends to improve app performance and develop new features.',
                'Fulfill legal obligations and comply with regulatory requirements.',
              ],
            ),
            _buildSection(
              'SELFIE VERIFICATION',
              [
                'Selfie verification is used to confirm the authenticity of your profile and ensure that users on the platform are genuine. By providing a selfie for verification, you consent to the collection and processing of your image for verification purposes and comparison of the selfie with your uploaded profile photos.',
                'Your selfie is processed using secure algorithms to verify your identity. Once verification is complete, your selfie may be stored securely or deleted, depending on the retention policy outlined in this Privacy Policy.',
                'Selfie data is encrypted and stored securely. We do not share your selfie with other users or third parties, except for trusted vendors assisting with verification (bound by strict confidentiality agreements).',
              ],
            ),
            _buildSection(
              'SHARING YOUR INFORMATION',
              [
                'With Other Users: Profile details, such as name, photos, bio, and approximate location, are visible to other users. Selfie verification status (e.g., "Verified Profile") may be displayed on your profile, but your selfie image will not be shared.',
                'With Service Providers: Data, including selfie data, may be shared with trusted vendors who assist in verification, payment processing, hosting, analytics, and marketing.',
                'For Legal Obligations: Information may be disclosed to comply with legal processes, enforce agreements, or protect the rights of others.',
                'Business Transfers: If our company undergoes a merger, acquisition, or sale, your data may be transferred to the new entity.',
              ],
            ),
            _buildSection(
              'YOUR RIGHTS AND CHOICES',
              [
                'GDPR Rights (EU Users): Access - Request a copy of your data, including selfie verification data. Correction - Update incorrect or incomplete information. Deletion - Request the deletion of your data, including selfie data. Data Portability - Receive your data in a transferable format. Withdraw Consent - Revoke permission for selfie verification and other data processing.',
                'CCPA Rights (California Users): Access - Request details about the personal data we collect and share. Opt-Out - Prevent the sale of your personal data (we do not sell data). Deletion - Request the deletion of your personal data, including selfie data.',
                'To exercise these rights, contact us at support@nikkahmatch.com',
              ],
            ),
            _buildSection(
              'SECURITY MEASURES',
              [
                'Encryption: Selfie data and other sensitive information are encrypted during transmission and storage.',
                'Access Control: Limited access to selfie data and other personal information to authorized personnel only.',
                'Audits: Regular security reviews to ensure compliance with privacy standards.',
              ],
            ),
            _buildSection(
              'DATA RETENTION',
              [
                'Account Information: Retained until your account is deleted.',
                'Selfie Data: Retained for the duration of your account to validate your profile, or deleted immediately after verification depending on the process used.',
                'Geolocation Data: Stored temporarily to enhance matching services.',
              ],
            ),
            _buildSection(
              'UPDATES TO THIS PRIVACY POLICY',
              [
                'We may update this Privacy Policy periodically to reflect changes in our practices or legal requirements.',
                'Significant updates will be communicated via app notifications or emails.',
              ],
            ),
            _buildSection(
              'CONTACT US',
              [
                'If you have any questions or concerns about this Privacy Policy or your data, please contact us:',
                'Email: support@nikkahmatch.com',
                'Response Time: Within 48 hours',
              ],
            ),
            const SizedBox(height: 30),
            _buildLastUpdated(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepEmerald,
            AppColors.deepEmerald,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepEmerald.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardDark,
              border: Border.all(
                color: AppColors.primaryCyan,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/nikkah_match_app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.cardDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Last Updated: June 2026',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.deepEmerald,
                      AppColors.deepEmerald,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.cardDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.deepEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.deepEmerald.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.deepEmerald.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.deepEmerald,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This Privacy Policy is effective as of the last updated date. By using our Platform, you acknowledge that you have read and understood this Privacy Policy.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.deepEmerald,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
