// ─────────────────────────────────────────────────────────────────────────────
//  screens/client/product_selection_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ProductSelectionScreen extends StatefulWidget {
  final List<UploadedDocument> documents;
  const ProductSelectionScreen({super.key, required this.documents});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  ProductCategory? _selectedCategory;
  ProductItem?     _selectedItem;
  bool             _showPreview = false;
  String?           _error;

  void _showPreviewPage() {
    setState(() => _showPreview = true);
  }

  void _hidePreviewPage() {
    setState(() => _showPreview = false);
  }

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
        leading: _showPreview
            ? BackButton(onPressed: () => setState(() => _showPreview = false))
            : null,
        automaticallyImplyLeading: _showPreview,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _showPreview
                  ? _PreviewPage(
                      selectedCategory: _selectedCategory!,
                      selectedItem:   _selectedItem!,
                      documents: widget.documents,
                      onEdit:    () => setState(() => _showPreview = false),
                    )
                  : _SelectionPage(
                      selectedCategory: _selectedCategory,
                      selectedItem:     _selectedItem,
                      onCategoryChanged: (c) => setState(() {
                        _selectedCategory = c;
                        _selectedItem     = null;
                      }),
                      onItemChanged: (i) => setState(() => _selectedItem = i),
                      onPreview: () => setState(() => _showPreview = true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step Indicator Widget ──────────────────────────────────────────────
Widget _StepIndicator2(BuildContext context, {required int current}) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        "$current",
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    ),
  );
}

// ── Selection Page ────────────────────────────────────────────────────────────
class _SelectionPage extends StatelessWidget {
  final ProductCategory? selectedCategory;
  final ProductItem?     selectedItem;
  final ValueChanged<ProductCategory> onCategoryChanged;
  final ValueChanged<ProductItem>     onItemChanged;
  final VoidCallback                  onPreview;

  const _SelectionPage({
    required this.selectedCategory,
    required this.selectedItem,
    required this.onCategoryChanged,
    required this.onItemChanged,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Step 2 indicator
      _StepIndicator2(context, current: 2),
      const SizedBox(height: 28),

      SectionHeader(
        title:    'Select a Product',
        subtitle: 'Choose the product category and specific service you require.',
      ),
      const SizedBox(height: 28),

      // ── Step 1: Category
      Text('STEP 1 - SELECT CATEGORY',
        style: GoogleFonts.montserrat(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppTheme.goldLight, letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 14),

      ...ProductCatalogue.categories.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ProductCategoryCard(
          category:   e.value,
          isSelected: selectedCategory?.id == e.value.id,
          onTap:      () => onCategoryChanged(e.value),
          index:      e.key,
        ),
      )),

      // ── Step 2: Product from category
      if (selectedCategory != null) ...[
        const SizedBox(height: 28),
        Text('STEP 2 - SELECT PRODUCT FROM ${selectedCategory!.name.toUpperCase()}',
          style: GoogleFonts.montserrat(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppTheme.goldLight, letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),

        ...selectedCategory!.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ProductItemTile(
            item:       item,
            isSelected: selectedItem?.id == item.id,
            onTap:      () => onItemChanged(item),
          ),
        )),
      ],

      const SizedBox(height: 28),

      GoldButton(
        label:     'Review and Submit',
        onPressed: (selectedCategory != null && selectedItem != null)
            ? onPreview
            : null,
      ),
      const SizedBox(height: 40),
    ],
  );
}

class _ProductItemTile extends StatelessWidget {
  final ProductItem item;
  final bool        isSelected;
  final VoidCallback onTap;

  const _ProductItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.gold.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppTheme.goldLight : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.goldLight : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, size: 13, color: Theme.of(context).colorScheme.onPrimary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 11, color: AppTheme.textSecondary, height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Preview Page ──────────────────────────────────────────────────────────────
class _PreviewPage extends StatefulWidget {
  final ProductCategory selectedCategory;
  final ProductItem selectedItem;
  final List<UploadedDocument> documents;
  final VoidCallback onEdit;

  const _PreviewPage({
    required this.selectedCategory,
    required this.selectedItem,
    required this.documents,
    required this.onEdit,
  });

  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Review Your Application',
          subtitle: 'Please review all details before submitting.',
        ),
        const SizedBox(height: 28),

        if (_error != null)
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),

        _PreviewSection(
          title: 'Applicant',
          children: [
            _PreviewRow('Full Name', user.fullName),
            _PreviewRow('Company', user.companyName),
            _PreviewRow('Email', user.email),
            _PreviewRow('Phone', user.phone),
          ],
        ),

        const SizedBox(height: 20),

        _PreviewSection(
          title: 'Selected Product',
          children: [
            _PreviewRow('Category', widget.selectedCategory.displayName),
            _PreviewRow('Product', widget.selectedItem.name),
          ],
        ),

        const SizedBox(height: 30),

        GoldButton(
          label: _submitting ? 'Submitting...' : 'Submit Application',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    final svc = context.read<ApplicationService>();

    final err = await svc.submitApplication(
      client: auth.currentUser!,
      productCategoryId: widget.selectedCategory.name,
      productCategoryName: widget.selectedCategory.displayName,
      selectedProductId: widget.selectedItem.id,
      selectedProductName: widget.selectedItem.name,
      documents: widget.documents,
    );

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });

    if (err != null) {
      setState(() {
        _error = err;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application submitted successfully!'),
          backgroundColor: AppTheme.goldLight,
        ),
      );
      context.go('/dashboard');
    }
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreviewSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
