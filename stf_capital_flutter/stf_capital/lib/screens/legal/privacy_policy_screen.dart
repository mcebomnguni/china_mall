// ─────────────────────────────────────────────────────────────────────
//  screens/legal/privacy_policy_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text('Privacy Policy',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STF Capital Privacy Policy',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('1. Information We Collect'),
                    _SectionContent([
                      'Account Information',
                      'When you register for an account, we collect your name, email address, phone number, and company information.',
                    ]),
                    _SectionContent([
                      'Application Data',
                      'When you submit applications, we collect personal and financial information necessary to process your application.',
                    ]),
                    _SectionContent([
                      'Usage Data',
                      'We collect information about how you use our application, including device information and usage patterns.',
                    ]),
                    _SectionContent([
                      'Communications',
                      'We may send you notifications about your application status and other important updates.',
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('2. How We Use Your Information'),
                    _SectionContent([
                      'Processing Applications',
                      'Your application information is used to process and evaluate your applications. We may share this information with authorized third parties as necessary.',
                    ]),
                    _SectionContent([
                      'Communication',
                      'We use your contact information to communicate with you about your applications and account status.',
                    ]),
                    _SectionContent([
                      'Analytics',
                      'We use analytics to understand how our application is used and to improve our services.',
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('3. Data Security'),
                    _SectionContent([
                      'Security Measures',
                      'We implement appropriate technical and organizational measures to protect your personal information.',
                    ]),
                    _SectionContent([
                      'Data Retention',
                      'We retain your information only as long as necessary to provide our services and comply with legal requirements.',
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('4. Your Rights'),
                    _SectionContent([
                      'Access and Correction',
                      'You have the right to access, correct, and delete your personal information.',
                    ]),
                    _SectionContent([
                      'Data Portability',
                      'You can request a copy of your personal data and delete your account.',
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('5. Cookies and Tracking'),
                    _SectionContent([
                      'Cookies',
                      'We use cookies to enhance your experience. You can control cookie settings in your browser.',
                    ]),
                    _SectionContent([
                      'Analytics',
                      'We use analytics to understand usage patterns and improve our services.',
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _SectionTitle('6. Changes to This Policy'),
                    _SectionContent([
                      'Updates',
                      'We may update this privacy policy from time to time. We will notify users of significant changes.',
                    ]),
                    _SectionContent([
                      'Contact Information',
                      'If you have questions about this privacy policy, please contact us at privacy@stfcapital.com.',
                    ]),
                  ]),
                  const SizedBox(height: 40),

                  // Accept Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('I Understand'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _SectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        title,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _SectionContent(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
