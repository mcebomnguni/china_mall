// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/product_first_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ProductFirstScreen extends StatefulWidget {
  const ProductFirstScreen({super.key});

  @override
  State<ProductFirstScreen> createState() => _ProductFirstScreenState();
}

class _ProductFirstScreenState extends State<ProductFirstScreen> {
  ProductCategory? _selectedCategory;
  ProductItem?     _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text('Select Product',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: Text('Cancel',
              style: GoogleFonts.montserrat(
                fontSize: 12, color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1 indicator
                  _StepIndicator1(current: 1),
                  const SizedBox(height: 28),

                  SectionHeader(
                    title:    'Select a Product First',
                    subtitle: 'Choose the product category and specific service you require before uploading documents.',
                  ),
                  const SizedBox(height: 28),

                  // Categories
                  Text('Product Category',
                    style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ProductCatalogue.categories.map((cat) => _CategoryChip(
                      category: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _selectedItem = null;
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Items
                  if (_selectedCategory != null) ...[
                    Text('Specific Service',
                      style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _selectedCategory!.items.map((item) => _ItemChip(
                        item: item,
                        isSelected: _selectedItem == item,
                        onTap: () => setState(() => _selectedItem = item),
                      )).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      label: 'Continue to Documents',
                      onPressed: _selectedItem != null
                          ? () => context.push('/onboarding/documents', extra: {
                                'category': _selectedCategory!,
                                'item': _selectedItem!,
                              })
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected ? AppTheme.goldGradientSimple : null,
        color: isSelected ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.goldLight : AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Text(category.displayName,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ── Item Chip ───────────────────────────────────────────────────────────────────
class _ItemChip extends StatelessWidget {
  final ProductItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ItemChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected ? AppTheme.goldGradientSimple : null,
        color: isSelected ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.goldLight : AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Text(item.name,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ── Step indicator ──────────────────────────────────────────────────────────────
class _StepIndicator1 extends StatelessWidget {
  final int current;
  const _StepIndicator1({required this.current});

  @override
  Widget build(BuildContext context) => Row(
    children: [1, 2].asMap().entries.map((e) {
      final i      = e.key;
      final step   = e.value;
      final active = step == current;
      final done   = step < current;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: active || done ? AppTheme.goldGradientSimple : null,
                      color:    active || done ? null : AppTheme.darkSurface2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(i == 0 ? 'Select Product' : 'Upload Documents',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: active ? AppTheme.goldLight : AppTheme.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (i < 1) const SizedBox(width: 12),
          ],
        ),
      );
    }).toList(),
  );
}
