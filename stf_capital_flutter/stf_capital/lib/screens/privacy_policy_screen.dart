// ─────────────────────────────────────────────────────────────────────────────
//  screens/privacy_policy_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StfScaffold(
      title: 'Privacy Policy',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STF Capital Privacy Policy',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text('Last updated: January 2025',
                  style: GoogleFonts.montserrat(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                const GoldDivider(width: 80),
                const SizedBox(height: 28),

                _Section(
                  title: '1. Introduction',
                  body: 'STF Capital (Pty) Ltd ("STF Capital", "we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile and web application and related services.',
                ),
                _Section(
                  title: '2. Information We Collect',
                  body: 'We collect information you provide directly to us, including:\n\n'
                      '- Personal identification information: your full name, email address, username, phone number, and company name.\n'
                      '- Business documents: company profile, certificate of incorporation, articles of association, CR6, CR14, tax clearance certificates, financial or bank statements, contracts or purchase orders, and tender documents.\n'
                      '- Account credentials: your username and encrypted password.\n'
                      '- Usage data: information about how you interact with our application.',
                ),
                _Section(
                  title: '3. How We Use Your Information',
                  body: 'We use the information we collect to:\n\n'
                      '- Create and manage your account.\n'
                      '- Process your service applications and communicate their status to you.\n'
                      '- Verify your identity and the legitimacy of your business.\n'
                      '- Comply with applicable legal and regulatory requirements.\n'
                      '- Improve and personalise your experience with our services.\n'
                      '- Send you administrative communications regarding your account or applications.\n'
                      '- Prevent fraud and ensure the security of our platform.',
                ),
                _Section(
                  title: '4. Sharing of Information',
                  body: 'STF Capital does not sell, trade, or otherwise transfer your personal information to third parties without your consent, except:\n\n'
                      '- To service providers who assist us in operating our platform under strict confidentiality obligations.\n'
                      '- To insurance providers, financial institutions, or other counterparties necessary to process your specific service request, with your implicit consent through application submission.\n'
                      '- Where required by law, court order, or regulatory authority.\n'
                      '- To protect the rights and safety of STF Capital, our clients, or the public.',
                ),
                _Section(
                  title: '5. Document and Data Storage',
                  body: 'Documents you upload are stored securely using industry-standard encryption on our cloud infrastructure. Documents are retained for the duration of your account and for a minimum of five years thereafter to comply with financial services record-keeping requirements. You may request deletion of your account and associated documents, subject to our legal and regulatory retention obligations.',
                ),
                _Section(
                  title: '6. Data Security',
                  body: 'We implement appropriate technical and organisational security measures to protect your personal information against unauthorised access, alteration, disclosure, or destruction. All data is transmitted over encrypted HTTPS connections. Account passwords are hashed and never stored in plain text. Access to personal data is restricted to authorised STF Capital staff on a need-to-know basis.',
                ),
                _Section(
                  title: '7. Your Rights',
                  body: 'Under the Protection of Personal Information Act (POPIA) and applicable law, you have the right to:\n\n'
                      '- Access the personal information we hold about you.\n'
                      '- Request correction of inaccurate or incomplete information.\n'
                      '- Request deletion of your personal information, subject to legal retention requirements.\n'
                      '- Object to the processing of your personal information.\n'
                      '- Lodge a complaint with the Information Regulator of South Africa.\n\n'
                      'To exercise any of these rights, please contact us at privacy@stfcapital.co.za.',
                ),
                _Section(
                  title: '8. Cookies and Analytics',
                  body: 'Our web application may use cookies and similar technologies to enhance your experience and collect usage analytics. You may disable cookies through your browser settings; however, this may affect the functionality of certain features.',
                ),
                _Section(
                  title: '9. Children\'s Privacy',
                  body: 'Our services are intended solely for business and commercial use by persons aged 18 years or older. We do not knowingly collect personal information from minors.',
                ),
                _Section(
                  title: '10. Changes to This Policy',
                  body: 'We may update this Privacy Policy from time to time. We will notify you of material changes by posting the updated policy within the application and updating the "Last updated" date above. Your continued use of the application after such changes constitutes your acceptance of the revised policy.',
                ),
                _Section(
                  title: '11. Contact Us',
                  body: 'If you have any questions, concerns, or requests relating to this Privacy Policy, please contact our Information Officer:\n\n'
                      'STF Capital (Pty) Ltd\n'
                      'Email: privacy@stfcapital.co.za\n'
                      'Website: www.stfcapital.co.za',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 30, height: 1.5,
          color: AppTheme.gold.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(body,
          style: GoogleFonts.montserrat(
            fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.7,
          ),
        ),
      ],
    ),
  );
}
