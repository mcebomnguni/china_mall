import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

// ─── Shimmer skeleton ────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFFAFAFA),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ─── Network image ────────────────────────────────────────────────────────────
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  const AppNetworkImage({super.key, this.url, this.width, this.height, this.fit = BoxFit.cover, this.radius = 0});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url != null && url!.isNotEmpty ? url! : AppConstants.placeholderProduct;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl, width: width, height: height, fit: fit,
        placeholder: (_, __) => Container(
          width: width, height: height,
          color: const Color(0xFFF5F5F5),
          child: const Center(child: Icon(CupertinoIcons.photo, color: Color(0xFFCCCCCC))),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width, height: height,
          color: const Color(0xFFF5F5F5),
          child: const Center(child: Icon(CupertinoIcons.photo, color: Color(0xFFCCCCCC))),
        ),
      ),
    );
  }
}

// ─── Price text ───────────────────────────────────────────────────────────────
class PriceText extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final bool large;
  const PriceText({super.key, required this.price, this.style, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      'R ${price.toStringAsFixed(2)}',
      style: style ?? TextStyle(
        fontFamily: 'Satoshi',
        fontSize: large ? 28 : 15,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ─── Star rating ──────────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  const StarRating({super.key, required this.rating, this.reviewCount, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.star_fill, size: size, color: AppColors.warning),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Satoshi', fontSize: size,
            fontWeight: FontWeight.w900, color: AppColors.textPrimary,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontFamily: 'Satoshi', fontSize: size - 1,
              fontWeight: FontWeight.w600, color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── OS-style section label (matches React "ACTIVITY LOG" uppercase labels) ───
class SectionLabel extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionLabel({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: const Text(
                'See all',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Keep SectionHeader as alias
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SectionLabel(title: title, actionLabel: actionLabel, onAction: onAction),
    );
  }
}

// ─── OS card (white, heavy rounded, black/5 border — React style) ────────────
class OsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const OsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: card,
      ),
    );
  }
}

// ─── Status chip ─────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'delivered': case 'approved': case 'paid': return AppColors.success;
      case 'cancelled': case 'rejected': case 'banned': return AppColors.error;
      case 'in_transit': case 'out_for_delivery': case 'picked_up': return AppColors.info;
      case 'payment_confirmed': case 'processing': return AppColors.warning;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.orderStatusLabels[status] ?? status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Satoshi', fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: _color,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 28, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w900,
                fontSize: 16, color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w500,
                fontSize: 13, color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(label: buttonLabel!, onTap: onButton),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── App button (green, heavy, OS style) ─────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    if (outline) {
      return OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: color ?? AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _child,
      );
    }
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: _child,
    );
  }

  Widget get _child {
    if (loading) {
      return const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)],
      );
    }
    return Text(label);
  }
}

// ─── Quantity stepper ────────────────────────────────────────────────────────
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 99});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: CupertinoIcons.minus, onTap: value > min ? () => onChanged(value - 1) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$value',
              style: const TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w900, fontSize: 15,
              ),
            ),
          ),
          _Btn(icon: CupertinoIcons.plus, onTap: value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 14, color: onTap != null ? AppColors.textPrimary : AppColors.textTertiary),
      ),
    );
  }
}
