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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepEmerald, // Turquoise
                AppColors.deepEmerald, // Deep Blue
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
              '1. INTRODUCTION',
              [
                'Vivah Matrimony ("we," "us," "our") is committed to protecting your privacy.',
                'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our matrimonial services.',
                'Please read this policy carefully to understand our practices regarding your personal data.',
              ],
            ),
            _buildSection(
              '2. INFORMATION WE COLLECT',
              [
                'Personal Information: Name, email address, phone number, date of birth, gender',
                'Profile Information: Religion, caste, education, occupation, income, location, marital status',
                'Photos and Media: Profile pictures, engagement posters, and other uploaded images',
                'Preference Data: Your match preferences including age, height, religion, caste, location',
                'Usage Data: Login times, profiles viewed, interests sent, messages exchanged',
                'Device Information: IP address, browser type, operating system, device identifiers',
                'Location Data: GPS coordinates (with your permission) for distance-based matching',
                'Payment Information: Transaction details, subscription history, wallet balance (processed securely through Razorpay)',
              ],
            ),
            _buildSection(
              '3. HOW WE COLLECT INFORMATION',
              [
                'Directly from you when you register, create a profile, or update information',
                'Automatically through cookies, log files, and tracking technologies',
                'From your activity on the Platform (profiles viewed, interests sent, matches)',
                'From third-party services (payment processors, analytics providers)',
                'When you contact customer support or respond to surveys',
              ],
            ),
            _buildSection(
              '4. HOW WE USE YOUR INFORMATION',
              [
                'To create and maintain your matrimonial profile',
                'To provide match suggestions based on your preferences',
                'To facilitate communication between matched users',
                'To process payments and manage subscriptions',
                'To verify profiles and photos for authenticity',
                'To send notifications about interests, matches, and messages',
                'To improve our services and Platform features',
                'To detect and prevent fraud, spam, and abuse',
                'To comply with legal obligations and enforce our Terms',
                'To send promotional communications (with your consent)',
              ],
            ),
            _buildSection(
              '5. INFORMATION SHARING AND DISCLOSURE',
              [
                'With Other Users: Your profile information (name, photos, details) is visible to other users for matchmaking purposes',
                'With Service Providers: Payment processors (Razorpay), cloud hosting, analytics, customer support tools',
                'With Legal Authorities: When required by law, court order, or government request',
                'With Your Consent: When you explicitly agree to share information',
                'Business Transfers: In connection with merger, acquisition, or sale of assets',
                'We do NOT sell your personal data to third parties for commercial purposes',
              ],
            ),
            _buildSection(
              '6. INFORMATION VISIBLE TO OTHER USERS',
              [
                'Public Profile Information: Name, age, height, religion, caste, education, occupation, location',
                'Photos: Profile pictures (verified photos receive a badge)',
                'Matrimony ID: Your unique identifier (e.g., VE1234567)',
                'Preferences: Your match preferences may be partially visible',
                'Activity Status: When you were last active on the Platform',
                'Contact information is NOT displayed publicly on your profile',
              ],
            ),
            _buildSection(
              '7. COOKIES AND TRACKING',
              [
                'We use cookies to enhance your experience and analyze Platform traffic',
                'Types of cookies used: Essential, Performance, Analytics, Advertising',
                'You can control cookie settings through your browser',
                'Disabling cookies may limit some Platform features',
                'Third-party services may also use cookies (Google Analytics, Razorpay)',
              ],
            ),
            _buildSection(
              '8. LOCATION SERVICES',
              [
                'We collect location data to calculate distance between profiles',
                'Location is used for distance-based match suggestions',
                'You can disable location services in your device settings',
                'Some features may be limited without location access',
                'Location data is encrypted and stored securely',
              ],
            ),
            _buildSection(
              '9. PAYMENT AND FINANCIAL DATA',
              [
                'Payments are processed through Razorpay payment gateway',
                'We do not store your complete credit/debit card details',
                'Transaction history is stored for your reference',
                'Wallet balance and transactions are recorded in your account',
                'All payment data is encrypted using industry-standard security',
              ],
            ),
            _buildSection(
              '10. DATA RETENTION',
              [
                'We retain your data while your account is active',
                'Inactive accounts may be archived after 2 years of no activity',
                'You can request account deletion at any time',
                'Some data may be retained for legal compliance even after deletion',
                'Deleted profiles are removed from public view immediately',
                'Backup copies may retain data for up to 90 days after deletion',
              ],
            ),
            _buildSection(
              '11. DATA SECURITY',
              [
                'We implement industry-standard security measures to protect your data',
                'Data is encrypted in transit (SSL/TLS) and at rest',
                'Access to personal data is restricted to authorized personnel',
                'Regular security audits and updates are conducted',
                'Password hashing is used to protect login credentials',
                'Despite our efforts, no system is 100% secure',
              ],
            ),
            _buildSection(
              '12. YOUR PRIVACY RIGHTS',
              [
                'Access: Request a copy of your personal data',
                'Correction: Update or correct inaccurate information',
                'Deletion: Request deletion of your account and data',
                'Portability: Receive your data in a structured format',
                'Opt-Out: Unsubscribe from promotional communications',
                'Restriction: Request limitation of data processing',
                'To exercise these rights, contact: support@vivahmatrimony.com',
              ],
            ),
            _buildSection(
              '13. COMMUNICATION PREFERENCES',
              [
                'Service Notifications: Match alerts, interest notifications, messages (cannot be disabled)',
                'Email Notifications: You can manage email preferences in settings',
                'SMS Notifications: You can opt-out of promotional SMS',
                'Push Notifications: Control through your device settings',
                'Promotional Communications: Unsubscribe anytime via email link',
              ],
            ),
            _buildSection(
              '14. CHILDREN\'S PRIVACY',
              [
                'Our services are only available to users 18 years and older',
                'We do not knowingly collect data from children under 18',
                'If we discover underage users, their accounts will be terminated',
                'Parents should monitor their children\'s online activity',
              ],
            ),
            _buildSection(
              '15. THIRD-PARTY SERVICES',
              [
                'Razorpay: Payment processing (subject to Razorpay\'s privacy policy)',
                'Cloud Hosting: Data storage on secure cloud servers',
                'Analytics: Google Analytics for usage tracking',
                'Email/SMS Services: For notifications and communications',
                'We are not responsible for third-party privacy practices',
              ],
            ),
            _buildSection(
              '16. INTERNATIONAL DATA TRANSFER',
              [
                'Your data may be transferred to and processed in India',
                'By using the Platform, you consent to data transfer to India',
                'We ensure adequate safeguards for international transfers',
                'International users must comply with their local laws',
              ],
            ),
            _buildSection(
              '17. CHANGES TO THIS PRIVACY POLICY',
              [
                'We may update this Privacy Policy from time to time',
                'Changes will be posted on this page with updated date',
                'Material changes will be communicated via email or notification',
                'Continued use after changes constitutes acceptance',
                'Please review this policy periodically for updates',
              ],
            ),
            _buildSection(
              '18. GRIEVANCE OFFICER',
              [
                'In accordance with Indian law, we have appointed a Grievance Officer',
                'For privacy concerns, contact: grievance@vivahmatrimony.com',
                'Response Time: Within 48 hours',
                'Escalation: If unresolved, contact support@vivahmatrimony.com',
              ],
            ),
            _buildSection(
              '19. CONTACT US',
              [
                'For privacy-related questions or concerns:',
                'Email: support@vivahmatrimony.com',
                'Privacy Email: privacy@vivahmatrimony.com',
                'Grievance Officer: grievance@vivahmatrimony.com',
                'Address: [Your Business Address]',
                'Phone: [Your Contact Number]',
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepEmerald, // Turquoise
            AppColors.deepEmerald, // Deep Blue
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
      child: const Column(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 48,
            color: AppColors.cardDark,
          ),
          SizedBox(height: 12),
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.cardDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Last Updated: March 2025',
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.deepEmerald, // Turquoise
                      AppColors.deepEmerald, // Deep Blue
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      child: const Row(
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
                fontWeight: FontWeight.w600,
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















