// ─────────────────────────────────────────────────────────────────────
//  screens/legal/about_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text('About',
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
              // App Information
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
                    Text(
                      'STF Capital',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Financial Services Application',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Build Date: January 2025',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Company Information
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
                    Text(
                      'Company',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'STF Capital (Pty) Ltd',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Financial services technology company',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Providing innovative financial solutions since 2025',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'English',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Français',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Information
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
                    Text(
                      'Contact',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContactItem(Icons.email, 'Email', 'info@stfcapital.com'),
                    _ContactItem(Icons.phone, 'Phone', '+1-234-567-8900'),
                    _ContactItem(Icons.language, 'Language', 'English, Français'),
                    const SizedBox(height: 16),
                    _ContactItem(Icons.public, 'Website', 'www.stfcapital.com'),
                    const SizedBox(height: 24),

                  // Legal Information
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
                    Text(
                      'Legal',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LegalItem('Terms & Conditions', () => _launchUrl(Uri.parse('https://stfcapital.com/terms'))),
                    _LegalItem('Privacy Policy', () => _launchUrl(Uri.parse('https://stfcapital.com/privacy'))),
                    _LegalItem('Licenses', () => _launchUrl(Uri.parse('https://stfcapital.com/licenses'))),
                    const SizedBox(height: 16),
                    Text(
                      'Open source licenses',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                        decorationThickness: 1.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                  // App Information
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
                    Text(
                      'App Information',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AppInfoItem('Package Name', 'stf_capital'),
                    _AppInfoItem('Package Version', '1.0.0'),
                    _AppInfoItem('Build Number', '20250101'),
                    _AppInfoItem('Flutter Version', '3.19.0'),
                    _AppInfoItem('Device Info', () => _showDeviceInfo(context)),
                    const SizedBox(height: 24),

                    // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('Close'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _ContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _LegalItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: Theme.of(context).colorScheme.primary,
            decorationThickness: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _AppInfoItem(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: onTap,
              child: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeviceInfo(BuildContext context) async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final version = await PackageInfo.fromPlatform();
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Device Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeviceInfoRow('Model', deviceInfo.model),
                _DeviceInfoRow('Manufacturer', deviceInfo.manufacturer),
                _DeviceInfoRow('Brand', deviceInfo.brand),
                _DeviceInfoRow('Product', deviceInfo.product),
                _DeviceInfoRow('Board', deviceInfo.board),
                _DeviceInfoRow('Bootloader', deviceInfo.bootloader),
                _DeviceInfoRow('Display', '${deviceInfo.displayMetrics.width}x${deviceInfo.displayMetrics.height}'),
                _DeviceInfoRow('Fingerprint', deviceInfo.fingerprint),
                _DeviceInfoRow('Hardware', deviceInfo.hardware),
                _DeviceInfoRow('Android Version', deviceInfo.version.release),
                _DeviceInfoRow('Security Patch', deviceInfo.version.securityPatch),
                _DeviceInfoRow('Flutter Version', version.version),
                const SizedBox(height: 16),
                Text(
                  'System Version: ${version.version}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing device info: $e');
    }
  }

  Widget _DeviceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}
