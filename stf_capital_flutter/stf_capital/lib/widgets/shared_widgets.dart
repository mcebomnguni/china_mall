// ─────────────────────────────────────────────────────────────────────────────
//  widgets/shared_widgets.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';

// ─── AppTextField ─────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ─── Gold Divider ─────────────────────────────────────────────────────────────
class GoldDivider extends StatelessWidget {
  final double width;
  const GoldDivider({super.key, this.width = 60});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: 2,
    decoration: BoxDecoration(
      gradient: AppTheme.goldGradientSimple,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

// ─── STF Logo / Wordmark ──────────────────────────────────────────────────────
class StfLogo extends StatelessWidget {
  final double size;
  const StfLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.goldGradient,
        ),
        child: Center(
          child: Text('STF',
            style: GoogleFonts.cormorantGaramond(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBg,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      ShaderMask(
        shaderCallback: (r) => AppTheme.goldGradient.createShader(r),
        child: Text('STF Capital',
          style: GoogleFonts.cormorantGaramond(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ],
  );
}

// ─── Gold Text Field ──────────────────────────────────────────────────────────
class GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const GoldTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:          controller,
    obscureText:         obscureText,
    keyboardType:        keyboardType,
    validator:           validator,
    textCapitalization:  textCapitalization,
    maxLines:            obscureText ? 1 : maxLines,
    readOnly:            readOnly,
    onTap:               onTap,
    style: GoogleFonts.montserrat(
      fontSize: 14, color: AppTheme.textPrimary,
    ),
    decoration: InputDecoration(
      labelText:   label,
      hintText:    hint,
      prefixIcon:  prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      suffix:      suffix,
    ),
  );
}

// ─── Primary Gold Button ──────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final double? width;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.darkBg,
            ),
          )
        : Text(label.toUpperCase());

    if (outlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(onPressed: isLoading ? null : onPressed, child: child),
      );
    }
    return SizedBox(
      width: width,
      child: ElevatedButton(onPressed: isLoading ? null : onPressed, child: child),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const GoldDivider(),
      if (subtitle != null) ...[
        const SizedBox(height: 12),
        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ],
  );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status.label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Replaced withAlpha(38) with opacity
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)), // Replaced withAlpha(76) with opacity
      ),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Dismissible Error Banner ─────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        AppTheme.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: AppTheme.error.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
            style: GoogleFonts.montserrat(
              fontSize: 12, color: AppTheme.error,
            ),
          ),
        ),
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppTheme.error, size: 16),
          ),
      ],
    ),
  );
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class InfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const InfoCard({
    super.key, required this.message, required this.icon, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.goldLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
              style: GoogleFonts.montserrat(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading)
        Container(
          color: Colors.black45,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.goldLight),
          ),
        ),
    ],
  );
}

// ─── Product Category Card ────────────────────────────────────────────────────
class ProductCategoryCard extends StatelessWidget {
  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const ProductCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  static const _icons = [
    Icons.shield_outlined,
    Icons.trending_up_rounded,
    Icons.security_outlined,
  ];

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.gold.withOpacity(0.12) : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.goldLight : AppTheme.darkBorder,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.gold.withOpacity(0.2)
                      : AppTheme.darkSurface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.goldLight.withOpacity(0.5)
                        : AppTheme.darkBorder,
                  ),
                ),
                child: Icon(
                  _icons[index % _icons.length],
                  color: isSelected ? AppTheme.goldLight : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.goldLight : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.goldLight, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            category.description,
            style: GoogleFonts.montserrat(
              fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${category.items.length} products available',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: isSelected ? AppTheme.goldLight : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Application List Tile ────────────────────────────────────────────────────
class ApplicationTile extends StatelessWidget {
  final ServiceApplication app;
  final VoidCallback onTap;
  final bool isAdmin;

  const ApplicationTile({
    super.key,
    required this.app,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.selectedProductName,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.productCategoryName,
                      style: GoogleFonts.montserrat(
                        fontSize: 11, color: AppTheme.textGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: app.status),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              app.clientName,
              style: GoogleFonts.montserrat(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              app.companyName,
              style: GoogleFonts.montserrat(
                fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${app.documents.length} document${app.documents.length == 1 ? '' : 's'}',
                style: GoogleFonts.montserrat(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(app.createdAt),
                style: GoogleFonts.montserrat(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (app.returnReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.statusReturned.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.statusReturned.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppTheme.statusReturned, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      app.returnReason!,
                      style: GoogleFonts.montserrat(
                        fontSize: 11, color: AppTheme.statusReturned,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Page Scaffold ────────────────────────────────────────────────────────────
class StfScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBack;
  final Color? backgroundColor;

  const StfScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBack = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor ?? AppTheme.darkBg,
    appBar: title != null
        ? AppBar(
            title: ShaderMask(
              shaderCallback: (r) => AppTheme.goldGradient.createShader(r),
              child: Text(title!,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
            automaticallyImplyLeading: showBack,
            actions: actions,
          )
        : null,
    body: body,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
  );
}
