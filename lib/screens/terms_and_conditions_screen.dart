import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BCD4), // Turquoise
                Color(0xFF0D47A1), // Deep Blue
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              '1. ELIGIBILITY',
              [
                'You must be at least 18 years of age to use this Platform.',
                'You must be Single, Divorced, Widowed, or Nikkah Divorced.',
                'You cannot use this Platform if you have been previously suspended or convicted of a crime involving moral turpitude.',
              ],
            ),
            _buildSection(
              '2. ACCOUNT REGISTRATION',
              [
                'You must provide a valid email address and/or phone number.',
                'Create a secure password (minimum 8 characters).',
                'Complete the profile creation process with accurate information.',
                'You may only maintain one active account at a time.',
                'Each user receives a unique Matrimony ID (e.g., VE1234567).',
                'Mediators receive a unique 6-letter reference code for referrals.',
              ],
            ),
            _buildSection(
              '3. PROFILE ACCURACY',
              [
                'Provide truthful, accurate, and complete information.',
                'Do not impersonate another person or create a fake identity.',
                'Do not upload photos of other people.',
                'Update your profile promptly if any information changes.',
                'Do not create profiles for other individuals.',
                'False information may result in account suspension or termination.',
              ],
            ),
            _buildSection(
              '4. PHOTO AND MEDIA POLICY',
              [
                'Photos must be clear, recent (within 12 months), and show your face clearly.',
                'You must own the rights to all photos uploaded.',
                'Nudity, sexually explicit, violent, or inappropriate images are prohibited.',
                'All photos are subject to admin review before public display.',
                'Engagement posters must be your own and comply with content guidelines.',
              ],
            ),
            _buildSection(
              '5. MATCHING AND DISCOVERY',
              [
                'The Platform uses an algorithm to suggest matches based on your preferences.',
                'Preferences include: age, height, religion, caste, location, education, occupation, and lifestyle.',
                'Distance between profiles is calculated using GPS coordinates.',
                'Profiles are sorted by recent login activity to encourage active participation.',
              ],
            ),
            _buildSection(
              '6. INTEREST AND COMMUNICATION',
              [
                'You can express interest in other profiles with an optional message.',
                'Interest requests have status: Pending, Accepted, Rejected, or Withdrawn.',
                'When interest is accepted, a Match is created and messaging becomes available.',
                'Messaging is available only between matched users.',
                'Harassment, threats, solicitation, or inappropriate messages are prohibited.',
                'The Platform reserves the right to monitor messages for safety.',
              ],
            ),
            _buildSection(
              '7. SUBSCRIPTION AND PAYMENTS',
              [
                'The Platform offers various subscription plans with different features.',
                'Payments are processed through Razorpay payment gateway.',
                'The Platform includes a wallet system for transactions.',
                'Subscription fees are non-refundable once activated.',
                'Subscriptions do NOT auto-renew by default.',
                'Wallet balance is non-transferable and non-refundable.',
              ],
            ),
            _buildSection(
              '8. USER CONDUCT',
              [
                'Treat other users with respect and dignity.',
                'Do not harass, abuse, threaten, or solicit money from other users.',
                'Do not engage in commercial activities or spam.',
                'Do not share contact information publicly in your profile.',
                'Do not use automated tools (bots, scripts) to interact with the Platform.',
                'Use the Platform for genuine matrimonial purposes only.',
              ],
            ),
            _buildSection(
              '9. PRIVACY AND DATA',
              [
                'We collect personal information, profile data, photos, usage data, and location.',
                'Your data is used to provide match suggestions and facilitate communication.',
                'We may share data with service providers and legal authorities when required.',
                'We do NOT sell your personal data to third parties.',
                'Location data is used for distance-based matching.',
                'You can request account deletion at any time.',
              ],
            ),
            _buildSection(
              '10. BLOCKING AND REPORTING',
              [
                'You can block other users to prevent them from contacting you.',
                'You can report users for fake profiles, inappropriate behavior, or violations.',
                'Reports are reviewed by admin staff.',
                'Appropriate action is taken based on severity (warnings, suspension, termination).',
              ],
            ),
            _buildSection(
              '11. DISCLAIMER',
              [
                'The Platform is provided "as is" without warranties of any kind.',
                'We do not guarantee that you will find a match.',
                'We do not guarantee the quality, suitability, or authenticity of other users.',
                'You are solely responsible for your interactions with other users.',
                'We do not conduct background checks on users.',
              ],
            ),
            _buildSection(
              '12. LIMITATION OF LIABILITY',
              [
                'Vivah Matrimony shall not be liable for indirect, incidental, or consequential damages.',
                'We are not responsible for personal injury, financial losses, or offline meetings.',
                'Our total liability shall not exceed ₹1,000 or the amount you paid in the last 6 months.',
                'You agree to indemnify Vivah Matrimony from claims arising from your use of the Platform.',
              ],
            ),
            _buildSection(
              '13. ACCOUNT TERMINATION',
              [
                'We may suspend or terminate your account for violations of these Terms.',
                'You can voluntarily delete your account at any time through settings.',
                'Upon termination, your profile will no longer be visible.',
                'Subscriptions are non-refundable upon termination.',
              ],
            ),
            _buildSection(
              '14. MODIFICATIONS TO TERMS',
              [
                'We reserve the right to modify these Terms at any time.',
                'Changes will be posted on the Platform.',
                'Continued use after changes constitutes acceptance.',
              ],
            ),
            _buildSection(
              '15. GOVERNING LAW',
              [
                'These Terms shall be governed by the laws of India.',
                'Courts in [Your City/State], India shall have exclusive jurisdiction.',
                'Before filing a lawsuit, contact our support team to resolve the issue.',
              ],
            ),
            _buildSection(
              '16. MEDIATOR PROVISIONS',
              [
                'Mediators receive a unique reference code to track referrals.',
                'Mediators must act in good faith when making referrals.',
                'Mediators are recognized for successful matches.',
                'Mediator stats are displayed in the admin panel.',
              ],
            ),
            _buildSection(
              '17. CONTACT INFORMATION',
              [
                'Email: support@vivahmatrimony.com',
                'Grievance Officer: grievance@vivahmatrimony.com',
                'Response Time: Within 48 hours',
              ],
            ),
            const SizedBox(height: 30),
            _buildAcceptanceText(),
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
            Color(0xFF00BCD4), // Turquoise
            Color(0xFF0D47A1), // Deep Blue
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.gavel_rounded,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
                      Color(0xFF00BCD4), // Turquoise
                      Color(0xFF0D47A1), // Deep Blue
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
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
                    color: const Color(0xFF00BCD4),
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

  Widget _buildAcceptanceText() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BCD4).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF00BCD4),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'By using this Platform, you acknowledge that you have read these Terms and Conditions in full and agree to be bound by them.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D47A1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
