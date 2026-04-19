// lib/screens/legal/terms_of_service_screen.dart
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _buildAppBar(context),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20, 8, 20, 40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ──
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // ── Last Updated ──
                    _buildLastUpdated(),
                    const SizedBox(height: 24),

                    // ══════════════════════════
                    // SECTIONS
                    // ══════════════════════════

                    _buildSection(
                      '1. Acceptance of Terms',
                      'By downloading, installing, or using the ATS CV Builder '
                          'application ("App"), you agree to be bound by these Terms '
                          'of Service ("Terms"). If you do not agree to these Terms, '
                          'please do not use the App.\n\n'
                          'These Terms constitute a legally binding agreement between '
                          'you ("User") and ATS CV Builder ("we", "us", "our"). We '
                          'reserve the right to modify these Terms at any time, and '
                          'your continued use of the App constitutes acceptance of '
                          'any modifications.',
                    ),

                    _buildSection(
                      '2. Description of Service',
                      'ATS CV Builder is a mobile application that allows users to:\n\n'
                          '• Create professional resumes/CVs\n'
                          '• Choose from ATS-compatible templates\n'
                          '• Store and manage multiple CVs\n'
                          '• Export CVs as PDF documents\n'
                          '• Share CVs digitally\n\n'
                          'The App is provided "as is" and we make no warranties '
                          'regarding the accuracy, reliability, or completeness of '
                          'the service.',
                    ),

                    _buildSection(
                      '3. User Accounts',
                      '3.1. To use certain features of the App, you must create '
                          'an account using either email/password or Google Sign-In.\n\n'
                          '3.2. You are responsible for maintaining the confidentiality '
                          'of your account credentials and for all activities that '
                          'occur under your account.\n\n'
                          '3.3. You agree to provide accurate, current, and complete '
                          'information during registration and to update such '
                          'information to keep it accurate.\n\n'
                          '3.4. You must be at least 13 years old to create an account '
                          'and use the App.\n\n'
                          '3.5. We reserve the right to suspend or terminate your '
                          'account if any information provided is found to be '
                          'inaccurate or incomplete.',
                    ),

                    _buildSection(
                      '4. User Content',
                      '4.1. You retain ownership of all content you create using '
                          'the App, including CV data, personal information, and '
                          'generated documents.\n\n'
                          '4.2. By using the App, you grant us a limited, non-exclusive '
                          'license to store and process your content solely for the '
                          'purpose of providing the service.\n\n'
                          '4.3. You are solely responsible for the accuracy and '
                          'legality of the content you create and share through '
                          'the App.\n\n'
                          '4.4. You agree not to create content that is false, '
                          'misleading, defamatory, or violates any third-party rights.',
                    ),

                    _buildSection(
                      '5. Acceptable Use',
                      'You agree NOT to:\n\n'
                          '• Use the App for any illegal purpose\n'
                          '• Attempt to gain unauthorized access to our systems\n'
                          '• Interfere with or disrupt the App\'s functionality\n'
                          '• Reverse engineer, decompile, or disassemble the App\n'
                          '• Use the App to distribute malware or harmful content\n'
                          '• Create multiple accounts for fraudulent purposes\n'
                          '• Use automated systems to access the App\n'
                          '• Violate any applicable laws or regulations',
                    ),

                    _buildSection(
                      '6. Intellectual Property',
                      '6.1. The App, including its design, code, templates, logos, '
                          'and other visual elements, is protected by intellectual '
                          'property laws.\n\n'
                          '6.2. You may not copy, modify, distribute, or create '
                          'derivative works based on the App without our express '
                          'written permission.\n\n'
                          '6.3. The CV templates provided are licensed for personal '
                          'use only and may not be redistributed or sold.',
                    ),

                    _buildSection(
                      '7. Data Storage & Security',
                      '7.1. Your CV data is stored securely using Google Firebase '
                          'Cloud Firestore with industry-standard encryption.\n\n'
                          '7.2. While we implement reasonable security measures, '
                          'no method of electronic storage is 100% secure. We cannot '
                          'guarantee absolute security of your data.\n\n'
                          '7.3. You are responsible for maintaining backups of your '
                          'important data.\n\n'
                          '7.4. We implement Firebase Security Rules to ensure that '
                          'each user can only access their own data.',
                    ),

                    _buildSection(
                      '8. Third-Party Services',
                      '8.1. The App uses the following third-party services:\n\n'
                          '• Google Firebase (Authentication & Storage)\n'
                          '• Google Sign-In (Authentication)\n'
                          '• Google Fonts (Typography)\n\n'
                          '8.2. Your use of these third-party services is subject '
                          'to their respective terms and privacy policies.\n\n'
                          '8.3. We are not responsible for the practices or policies '
                          'of third-party service providers.',
                    ),

                    _buildSection(
                      '9. Disclaimer of Warranties',
                      '9.1. The App is provided on an "AS IS" and "AS AVAILABLE" '
                          'basis without warranties of any kind.\n\n'
                          '9.2. We do not guarantee that:\n\n'
                          '• The App will meet your specific requirements\n'
                          '• The App will be uninterrupted or error-free\n'
                          '• CVs created will guarantee employment\n'
                          '• The App will be compatible with all ATS systems\n\n'
                          '9.3. We make no representations about the suitability '
                          'of the App for any particular purpose.',
                    ),

                    _buildSection(
                      '10. Limitation of Liability',
                      '10.1. To the maximum extent permitted by law, we shall not '
                          'be liable for any indirect, incidental, special, '
                          'consequential, or punitive damages.\n\n'
                          '10.2. Our total liability for any claims arising from '
                          'your use of the App shall not exceed the amount you '
                          'paid us in the 12 months preceding the claim.\n\n'
                          '10.3. We are not liable for any loss of data, revenue, '
                          'or business opportunities resulting from your use of '
                          'the App.',
                    ),

                    _buildSection(
                      '11. Account Termination',
                      '11.1. You may delete your account at any time through the '
                          'App settings.\n\n'
                          '11.2. We reserve the right to suspend or terminate your '
                          'account for violation of these Terms.\n\n'
                          '11.3. Upon termination, your data may be deleted from '
                          'our servers within 30 days.\n\n'
                          '11.4. Sections that by their nature should survive '
                          'termination will remain in effect.',
                    ),

                    _buildSection(
                      '12. Changes to Terms',
                      '12.1. We may update these Terms from time to time. We will '
                          'notify you of significant changes through the App or '
                          'via email.\n\n'
                          '12.2. Your continued use of the App after changes '
                          'constitutes acceptance of the updated Terms.\n\n'
                          '12.3. If you do not agree with the updated Terms, you '
                          'must stop using the App and delete your account.',
                    ),

                    _buildSection(
                      '13. Governing Law',
                      'These Terms shall be governed by and construed in '
                          'accordance with applicable laws. Any disputes arising '
                          'from these Terms shall be resolved through good-faith '
                          'negotiation first, and if unsuccessful, through binding '
                          'arbitration.',
                    ),

                    _buildSection(
                      '14. Contact Information',
                      'If you have any questions about these Terms of Service, '
                          'please contact us at:\n\n'
                          '📧 Email: support@atscvbuilder.com\n'
                          '🌐 Website: www.atscvbuilder.com\n\n'
                          'We will respond to your inquiry within 48 hours.',
                    ),

                    const SizedBox(height: 20),

                    // ── Footer ──
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🎨 WIDGETS
  // ══════════════════════════════════════════

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Terms of Service',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2196F3)
                    .withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: Color(0xFF2196F3),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Legal',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2196F3).withOpacity(0.1),
            const Color(0xFF1565C0).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Color(0xFF2196F3),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please read these terms carefully before using '
            'ATS CV Builder. By using our app, you agree to '
            'these terms.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Last Updated: January 1, 2025',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'v1.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3)
                  .withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2196F3)
                    .withOpacity(0.1),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64B5F6),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Section Content
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'ATS CV Builder',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 All Rights Reserved',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}