import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// Shared safe-pop helper (used by every screen in this file)
// ─────────────────────────────────────────────────────────────────────────────
 
void _safePop(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  } else if (context.canPop()) {
    context.pop();
  } else {
    context.go('/profile');
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Shared URL launcher helper
// ─────────────────────────────────────────────────────────────────────────────
 
Future<void> _launch(String url, {BuildContext? context}) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open: $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// TERMS AND CONDITIONS
// ─────────────────────────────────────────────────────────────────────────────
 
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return _StaticContentScreen(
      title: 'Terms & Conditions',
      lastUpdated: '18 March 2026',
      sections: const [
        _Section('1. Acceptance of Terms',
            'By accessing or using the China Stall Market Place application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.'),
        _Section('2. Use of the Platform',
            'China Stall Market Place is a marketplace connecting buyers, store owners, and delivery partners in South Africa. You must be 18 years or older to use this platform. You are responsible for maintaining the confidentiality of your account credentials.'),
        _Section('3. Store Owners',
            'Store owners must submit accurate business information including a valid South African ID or passport, business registration number, and banking details. All products must comply with South African consumer protection laws. Products are subject to admin review before going live.'),
        _Section('4. Payments',
            'All payments are processed securely through Yoco. China Stall Market Place does not store your card details. Prices are listed in South African Rand (ZAR). A platform fee applies to each transaction.'),
        _Section('5. Delivery',
            'Deliveries are fulfilled through The Courier Guy or registered app drivers. Delivery times are estimates and not guaranteed. China Stall Market Place is not liable for delays caused by third-party couriers.'),
        _Section('6. Returns & Refunds',
            'Customers may request a refund within 7 days of delivery for damaged or incorrect items. Refund requests are subject to review. See our Return & Refund Policy for full details.'),
        _Section('7. Prohibited Items',
            'The sale of illegal goods, counterfeit products, weapons, hazardous materials, or any items prohibited under South African law is strictly forbidden and will result in immediate account suspension.'),
        _Section('8. Intellectual Property',
            'All content on China Stall Market Place including logos, designs, and software is the property of Bountiful AI Labs (Pty) Ltd. You may not reproduce or distribute any content without written permission.'),
        _Section('9. Limitation of Liability',
            'China Stall Market Place is not liable for any indirect, incidental, or consequential damages arising from your use of the platform. Our total liability shall not exceed the amount paid for the transaction in question.'),
        _Section('10. Governing Law',
            'These Terms are governed by the laws of the Republic of South Africa. Any disputes shall be resolved in the courts of South Africa.'),
        _Section('11. Changes to Terms',
            'We reserve the right to update these Terms at any time. Continued use of the app after changes constitutes acceptance of the new Terms.'),
        _Section('12. Contact',
            'For questions about these Terms, contact us at legal@China Stall Market Place.co.za'),
      ],
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY POLICY
// ─────────────────────────────────────────────────────────────────────────────
 
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return _StaticContentScreen(
      title: 'Privacy Policy',
      lastUpdated: '18 March 2026',
      sections: const [
        _Section('1. Information We Collect',
            'We collect information you provide when registering (name, email, phone number), transactional data (orders, payments), device information (device ID for biometric login), and location data (for delivery tracking, with your permission).'),
        _Section('2. How We Use Your Information',
            'Your information is used to: process orders and payments, provide delivery tracking, improve our services, send order updates and notifications, and comply with legal obligations under South African law (POPIA).'),
        _Section('3. POPIA Compliance',
            'China Stall Market Place complies with the Protection of Personal Information Act (POPIA) No. 4 of 2013. You have the right to access, correct, or delete your personal information. Contact our Information Officer at privacy@China Stall Market Place.co.za.'),
        _Section('4. Data Sharing',
            'We share your information with: delivery partners (name, address, phone for delivery), payment processors (Yoco — card data only), and where required by law. We do not sell your personal information to third parties.'),
        _Section('5. Data Security',
            'We use AES-256 encryption for sensitive data at rest, HTTPS for all data in transit, and secure token storage on your device. Biometric data never leaves your device — we only store a device-specific token.'),
        _Section('6. Cookies & Tracking',
            'The app does not use browser cookies. We use anonymous analytics to improve app performance. You may opt out of analytics in Settings > Preferences.'),
        _Section('7. Data Retention',
            'We retain your account data for as long as your account is active. After deletion, personal data is removed within 30 days, except where retention is required by law (e.g. financial records — 5 years).'),
        _Section('8. Your Rights',
            'Under POPIA you have the right to: access your data, correct inaccurate data, delete your account and data, object to processing, and lodge a complaint with the Information Regulator of South Africa.'),
        _Section('9. Children\'s Privacy',
            'China Stall Market Place is not intended for users under 18. We do not knowingly collect data from minors.'),
        _Section('10. Contact',
            'Privacy Officer: privacy@China Stall Market Place.co.za\nInformation Regulator SA: inforeg.org.za'),
      ],
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// RETURN & REFUND POLICY
// ─────────────────────────────────────────────────────────────────────────────
 
class ReturnRefundScreen extends StatelessWidget {
  const ReturnRefundScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return _StaticContentScreen(
      title: 'Return & Refund Policy',
      lastUpdated: '18 March 2026',
      sections: const [
        _Section('Eligibility for Returns',
            'You may request a return within 7 days of delivery if: the item is damaged or defective, the wrong item was delivered, or the item does not match the product description.'),
        _Section('Non-Returnable Items',
            'The following cannot be returned: perishable goods, digital products, items marked as final sale, items without original packaging, or items showing signs of use.'),
        _Section('How to Request a Return',
            'Go to Orders > Select Order > Request Return. Provide photos of the item and a reason for return. Our team will review within 2 business days.'),
        _Section('Refund Process',
            'Approved refunds are processed within 5–7 business days back to your original payment method via Yoco. Partial refunds may apply if only part of the order is returned.'),
        _Section('Delivery Costs',
            'Return delivery costs are covered by China Stall Market Place for damaged or incorrect items. For change-of-mind returns, the customer covers return delivery.'),
        _Section('Disputes',
            'If your return request is declined and you disagree, you may escalate to our disputes team at disputes@China Stall Market Place.co.za. We aim to resolve all disputes within 5 business days.'),
        _Section('Consumer Protection Act',
            'Your rights under the Consumer Protection Act 68 of 2008 are not affected by this policy. You retain all statutory rights.'),
      ],
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// HELP & SUPPORT
// ─────────────────────────────────────────────────────────────────────────────
 
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
 
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}
 
class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Track which FAQ index is currently expanded (-1 = none).
  int _expandedIndex = -1;
 
  static const _faqs = [
    _FAQ('How do I track my order?',
        'Go to Orders in the bottom menu, select your order, and tap "Track Delivery". You\'ll see live updates for app driver deliveries, and a Courier Guy tracking link for courier deliveries.'),
    _FAQ('How do I request a refund?',
        'Go to Orders > Select the order > Tap "Request Refund". Fill in the reason and attach photos if the item is damaged. We\'ll respond within 2 business days.'),
    _FAQ('My payment failed — what do I do?',
        'Check that your card details are correct and you have sufficient funds. If the problem persists, try a different card or contact your bank. Your account will not be charged for failed payments.'),
    _FAQ('How do I become a store owner?',
        'Tap your profile > Become a Seller. Complete your store profile, upload your ID/business registration, and submit for review. Approval takes 1–3 business days.'),
    _FAQ('How do I become a delivery driver?',
        'Go to Profile > Become a Driver. Upload all required documents (driver\'s licence, PrDP, ID, etc.). Once approved, you can go online and start accepting deliveries.'),
    _FAQ('How does fingerprint login work?',
        'After logging in, go to Profile > Security > Enable Biometric Login. Your fingerprint data stays on your device — we only store a secure token linked to your account.'),
    _FAQ('Can I use a voucher code?',
        'Yes! At checkout, tap "Apply Voucher" and enter your code. Valid vouchers will be automatically applied to your order total.'),
    _FAQ('How do I delete my account?',
        'Go to Profile > Delete Account. This action is permanent and removes all your data within 30 days. Your order history will be anonymised for legal compliance.'),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: () => _safePop(context),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
 
          // ── Contact options ──────────────────────────────────────────
          _ContactCard(
            icon: Icons.chat_bubble_outline,
            label: 'Live Chat',
            subtitle: 'Available 8am–8pm Mon–Sat',
            color: Colors.blue,
            onTap: () => _launch(
              'https://China Stall Market Place.co.za/chat',
              context: context,
            ),
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.email_outlined,
            label: 'Email Support',
            subtitle: 'support@China Stall Market Place.co.za',
            color: Colors.green,
            onTap: () => _launch(
              'mailto:support@China Stall Market Place.co.za',
              context: context,
            ),
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.phone_outlined,
            label: 'Call Us',
            subtitle: '+27 10 123 4567',
            color: Colors.orange,
            onTap: () => _launch(
              'tel:+27101234567',
              context: context,
            ),
          ),
 
          const SizedBox(height: 28),
 
          // ── FAQ header ───────────────────────────────────────────────
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
 
          // ── FAQ accordion — only one open at a time ──────────────────
          ...List.generate(_faqs.length, (i) {
            final faq      = _faqs[i];
            final expanded = _expandedIndex == i;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: expanded
                    ? BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1)
                    : BorderSide.none,
              ),
              child: Theme(
                // Remove the default expansion tile dividers.
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  key: PageStorageKey(i),
                  initiallyExpanded: false,
                  onExpansionChanged: (open) =>
                      setState(() => _expandedIndex = open ? i : -1),
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: expanded
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: expanded
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
 
          const SizedBox(height: 24),
 
          // ── Still need help? ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.question_circle_fill,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Still need help?',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                              builder: (_) => const ContactUsScreen()),
                        ),
                        child: const Text(
                          'Send us a message →',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 13,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// CONTACT US
// ─────────────────────────────────────────────────────────────────────────────
 
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});
 
  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}
 
class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _subject    = 'General Enquiry';
  bool   _sending    = false;
 
  static const _subjects = [
    'General Enquiry',
    'Order Issue',
    'Payment Problem',
    'Delivery Issue',
    'Store / Seller Query',
    'Driver Query',
    'Report a Bug',
    'Other',
  ];
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
 
    // TODO: replace with real API call when backend endpoint is ready.
    await Future.delayed(const Duration(seconds: 1));
 
    if (!mounted) return;
    setState(() => _sending = false);
 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Message sent! We'll respond within 24 hours."),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _safePop(context);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: () => _safePop(context),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // ── Header ───────────────────────────────────────────────
              const Text(
                'Send us a message',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "We'll get back to you within 24 hours.",
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
 
              // ── Name ─────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Your Name',
                    icon: CupertinoIcons.person),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
 
              // ── Email ─────────────────────────────────────────────────
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email Address',
                    icon: CupertinoIcons.mail),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final rx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  return rx.hasMatch(v.trim())
                      ? null
                      : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 12),
 
              // ── Subject dropdown ──────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: _dec('Subject',
                    icon: CupertinoIcons.tag),
                items: _subjects
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v!),
              ),
              const SizedBox(height: 12),
 
              // ── Message ───────────────────────────────────────────────
              TextFormField(
                controller: _messageCtrl,
                maxLines: 5,
                decoration: _dec('Message',
                    icon: CupertinoIcons.chat_bubble_text),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Please enter at least 10 characters'
                    : null,
              ),
              const SizedBox(height: 28),
 
              // ── Send button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Send Message',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
 
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
 
              // ── Other contact info ────────────────────────────────────
              const Text(
                'Other ways to reach us',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                Icons.email_outlined,
                'support@China Stall Market Place.co.za',
                onTap: () => _launch(
                    'mailto:support@China Stall Market Place.co.za',
                    context: context),
              ),
              _InfoRow(
                Icons.phone_outlined,
                '+27 10 123 4567',
                onTap: () => _launch('tel:+27101234567',
                    context: context),
              ),
              const _InfoRow(
                Icons.location_on_outlined,
                '123 Commerce Street, Sandton, Johannesburg, 2196',
              ),
              const _InfoRow(
                Icons.access_time_outlined,
                'Mon–Sat: 8am – 8pm',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
 
  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Shared models
// ─────────────────────────────────────────────────────────────────────────────
 
class _Section {
  final String title, content;
  const _Section(this.title, this.content);
}
 
class _FAQ {
  final String question, answer;
  const _FAQ(this.question, this.answer);
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
 
/// Reusable static content screen (Terms, Privacy, Refunds).
class _StaticContentScreen extends StatelessWidget {
  final String title, lastUpdated;
  final List<_Section> sections;
 
  const _StaticContentScreen({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: () => _safePop(context),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Last updated badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last updated: $lastUpdated',
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
 
          // Sections
          ...sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.content,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
 
/// Contact card used in Help & Support.
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
 
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(
              fontFamily: 'Satoshi', fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12),
        ),
        trailing: Icon(CupertinoIcons.chevron_right,
            size: 14, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
 
/// Info row used in Contact Us (email, phone, address, hours).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
 
  const _InfoRow(this.icon, this.text, {this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: onTap != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  decoration: onTap != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
