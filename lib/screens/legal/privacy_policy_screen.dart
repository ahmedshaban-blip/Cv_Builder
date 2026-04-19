// lib/screens/legal/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                    // ── Header ──
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // ── Last Updated ──
                    _buildLastUpdated(),
                    const SizedBox(height: 24),

                    // ── Quick Summary Card ──
                    _buildQuickSummary(),
                    const SizedBox(height: 24),

                    // ══════════════════════════
                    // SECTIONS
                    // ══════════════════════════

                    _buildSection(
                      '1. Information We Collect',
                      'We collect the following types of information:',
                      subsections: [
                        _SubSection(
                          title:
                              '1.1 Information You Provide',
                          content:
                              '• Full Name\n'
                              '• Email Address\n'
                              '• Phone Number (for CV only)\n'
                              '• Address (for CV only)\n'
                              '• Professional Information (education, experience, skills)\n'
                              '• Profile Photo (if using Google Sign-In)\n'
                              '• Any other information you include in your CV',
                        ),
                        _SubSection(
                          title:
                              '1.2 Information Collected Automatically',
                          content:
                              '• Device information (model, OS version)\n'
                              '• App usage data\n'
                              '• Authentication tokens\n'
                              '• Crash reports and performance data',
                        ),
                        _SubSection(
                          title:
                              '1.3 Information from Third Parties',
                          content:
                              '• Google Account information (when using Google Sign-In): '
                              'name, email, profile picture\n'
                              '• Firebase Authentication data',
                        ),
                      ],
                    ),

                    _buildSection(
                      '2. How We Use Your Information',
                      'We use your information for the following purposes:\n\n'
                          '• To create and manage your account\n'
                          '• To store and display your CV data\n'
                          '• To generate PDF documents of your CVs\n'
                          '• To provide customer support\n'
                          '• To improve the App\'s functionality and user experience\n'
                          '• To send important service-related notifications\n'
                          '• To detect and prevent fraud or abuse\n'
                          '• To comply with legal obligations',
                    ),

                    _buildSection(
                      '3. Data Storage & Security',
                      '',
                      subsections: [
                        _SubSection(
                          title: '3.1 Where We Store Your Data',
                          content:
                              'Your data is stored securely on Google Firebase Cloud '
                              'Firestore servers. Firebase provides enterprise-grade '
                              'security including:\n\n'
                              '• Data encryption in transit (TLS/SSL)\n'
                              '• Data encryption at rest\n'
                              '• Regular security audits\n'
                              '• SOC 1, SOC 2, and SOC 3 compliance',
                        ),
                        _SubSection(
                          title: '3.2 Security Measures',
                          content:
                              '• Firebase Security Rules restrict data access to authorized users only\n'
                              '• Each user can only read and write their own data\n'
                              '• Authentication is required for all data operations\n'
                              '• Passwords are hashed and never stored in plain text\n'
                              '• We use secure HTTPS connections for all communications',
                        ),
                        _SubSection(
                          title: '3.3 Data Breach Protocol',
                          content:
                              'In the event of a data breach, we will:\n\n'
                              '• Notify affected users within 72 hours\n'
                              '• Take immediate steps to contain the breach\n'
                              '• Investigate the cause and implement preventive measures\n'
                              '• Report to relevant authorities as required by law',
                        ),
                      ],
                    ),

                    _buildSection(
                      '4. Data Sharing',
                      'We do NOT sell, trade, or rent your personal information '
                          'to third parties. We may share your information only in '
                          'the following cases:\n\n'
                          '• With your explicit consent\n'
                          '• To comply with legal obligations or court orders\n'
                          '• To protect our rights, property, or safety\n'
                          '• With service providers who assist in operating the App '
                          '(e.g., Firebase), who are bound by confidentiality agreements\n\n'
                          'When you share your CV via the share feature, you are '
                          'directly sharing your document with the recipients you choose.',
                    ),

                    _buildSection(
                      '5. Third-Party Services',
                      'The App uses the following third-party services that may '
                          'collect data:\n\n'
                          '🔹 Google Firebase\n'
                          '   • Authentication, Cloud Firestore\n'
                          '   • Privacy Policy: firebase.google.com/support/privacy\n\n'
                          '🔹 Google Sign-In\n'
                          '   • OAuth 2.0 authentication\n'
                          '   • Privacy Policy: policies.google.com/privacy\n\n'
                          '🔹 Google Fonts\n'
                          '   • Font rendering for PDF generation\n'
                          '   • Privacy Policy: policies.google.com/privacy\n\n'
                          'We encourage you to review the privacy policies of these '
                          'third-party services.',
                    ),

                    _buildSection(
                      '6. Your Rights',
                      'You have the following rights regarding your personal data:',
                      subsections: [
                        _SubSection(
                          title: '6.1 Access & Portability',
                          content:
                              '• View all your stored data within the App\n'
                              '• Export your CVs as PDF documents\n'
                              '• Request a copy of all your personal data',
                        ),
                        _SubSection(
                          title: '6.2 Modification',
                          content:
                              '• Edit or update your personal information at any time\n'
                              '• Modify or delete individual CVs\n'
                              '• Update your account settings',
                        ),
                        _SubSection(
                          title: '6.3 Deletion',
                          content:
                              '• Delete individual CVs at any time\n'
                              '• Delete your entire account and all associated data\n'
                              '• Request complete data deletion by contacting us\n'
                              '• Data will be permanently removed within 30 days of deletion request',
                        ),
                        _SubSection(
                          title: '6.4 Consent Withdrawal',
                          content:
                              '• You may withdraw consent at any time by deleting your account\n'
                              '• Withdrawal of consent does not affect the lawfulness of '
                              'processing performed before withdrawal',
                        ),
                      ],
                    ),

                    _buildSection(
                      '7. Data Retention',
                      '• Active accounts: Data is retained as long as your account is active\n'
                          '• Deleted CVs: Permanently removed immediately from our servers\n'
                          '• Deleted accounts: All data is removed within 30 days\n'
                          '• Backup data: May persist in backups for up to 90 days\n'
                          '• Anonymous analytics: May be retained indefinitely in aggregate form',
                    ),

                    _buildSection(
                      '8. Children\'s Privacy',
                      'The App is not intended for children under 13 years of age. '
                          'We do not knowingly collect personal information from children '
                          'under 13. If we discover that a child under 13 has provided '
                          'us with personal information, we will promptly delete it.\n\n'
                          'If you are a parent or guardian and believe your child has '
                          'provided us with personal information, please contact us '
                          'immediately.',
                    ),

                    _buildSection(
                      '9. Cookies & Tracking',
                      'The App does not use cookies. However, Firebase may use '
                          'local storage and device identifiers for authentication '
                          'and analytics purposes.\n\n'
                          'We do NOT:\n\n'
                          '• Track your location\n'
                          '• Access your contacts\n'
                          '• Read your messages\n'
                          '• Record your screen\n'
                          '• Use your camera or microphone',
                    ),

                    _buildSection(
                      '10. International Data Transfers',
                      'Your data may be processed and stored on servers located '
                          'outside your country of residence. Google Firebase servers '
                          'are located in various regions worldwide.\n\n'
                          'By using the App, you consent to the transfer of your '
                          'information to countries that may have different data '
                          'protection laws than your country of residence.',
                    ),

                    _buildSection(
                      '11. Changes to This Policy',
                      '• We may update this Privacy Policy from time to time\n'
                          '• Significant changes will be notified through the App '
                          'or via email\n'
                          '• The "Last Updated" date will be revised accordingly\n'
                          '• Continued use of the App after changes constitutes '
                          'acceptance\n'
                          '• We encourage you to review this policy periodically',
                    ),

                    _buildSection(
                      '12. Contact Us',
                      'If you have any questions, concerns, or requests regarding '
                          'this Privacy Policy or our data practices, please contact '
                          'us:\n\n'
                          '📧 Email: quvloxstudio@gmail.com\n'
                          'We will respond to your inquiry within 48 hours.\n\n'
                          'For data deletion requests, please email us from the '
                          'email address associated with your account.',
                      extra: GestureDetector(
                        onTap: () => _launchURL(
                          'https://sites.google.com/view/cvbuilder-pricavy-policy/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9-%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9',
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '🌐 Website: ',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'View Full Policy',
                              style: TextStyle(
                                color: Color(0xFF64B5F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0x8064B5F6),
                              ),
                            ),
                          ],
                        ),
                      ),
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
              'Privacy Policy',
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
              color: const Color(0xFF4CAF50)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50)
                    .withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF4CAF50),
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Privacy',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
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
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF2E7D32).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.privacy_tip_rounded,
              color: Color(0xFF4CAF50),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your privacy is important to us. This policy '
            'explains how we collect, use, and protect your '
            'personal information.',
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

  Widget _buildQuickSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFA726).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: Color(0xFFFFA726),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Quick Summary',
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            '🔒',
            'Your data is encrypted and stored securely',
          ),
          _buildSummaryItem(
            '🚫',
            'We never sell your personal information',
          ),
          _buildSummaryItem(
            '👤',
            'Only you can access your CV data',
          ),
          _buildSummaryItem(
            '🗑️',
            'You can delete your data anytime',
          ),
          _buildSummaryItem(
            '📍',
            'We don\'t track your location',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content, {
    List<_SubSection>? subsections,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50)
                  .withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4CAF50)
                    .withOpacity(0.1),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF81C784),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (content.isNotEmpty)
            Text(
              content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                height: 1.7,
              ),
            ),

          if (extra != null) ...[
            const SizedBox(height: 8),
            extra,
          ],

          if (subsections != null)
            ...subsections.map((sub) => Padding(
                  padding: const EdgeInsets.only(
                    top: 14,
                    left: 8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sub.content,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.5),
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                )),
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
            Icons.shield_rounded,
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
            'Your privacy matters to us',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '© 2025 All Rights Reserved',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

// ══════════════════════════════════════════════
// Helper class for subsections
// ══════════════════════════════════════════════
class _SubSection {
  final String title;
  final String content;

  _SubSection({
    required this.title,
    required this.content,
  });
}