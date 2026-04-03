import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

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
    return Pressable(
      onTap: onTap,
      scaleFactor: 0.98,
      child: card,
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
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -8,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w900,
                fontSize: 16, color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w500,
                fontSize: 13, color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(label: buttonLabel!, onTap: onButton)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: 1.02,
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                  ),
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

// ─── Category Picker Field (grouped bottom sheet) ─────────────────────────────
/// A tappable form-field replacement for the category dropdown.
/// Shows categories grouped under Clothes / Household / Electronics.
class CategoryPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CategoryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Map<String, String>? get _current => AppConstants.categories
      .cast<Map<String, String>?>()
      .firstWhere((c) => c?['slug'] == value, orElse: () => null);

  Future<void> _open(BuildContext context) async {
    final String currentValue = value;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Select Category',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: AppConstants.categoryGroups.map((group) {
                  final subs =
                      AppConstants.categoriesForParent(group['slug']!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              AppConstants.categoryIcon(group['slug']!),
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              group['label']!,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subs.map((sub) {
                          final isSelected = sub['slug'] == currentValue;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, sub['slug']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppConstants.categoryIcon(sub['slug']!),
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    sub['label']!,
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cat = _current;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              cat != null
                  ? cat['label']!
                  : 'Select Category',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: cat != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_down,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
