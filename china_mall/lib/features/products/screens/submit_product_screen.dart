import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/store_product_service.dart';
 
class SubmitProductScreen extends StatefulWidget {
  const SubmitProductScreen({super.key});
 
  @override
  State<SubmitProductScreen> createState() => _SubmitProductScreenState();
}
 
class _SubmitProductScreenState extends State<SubmitProductScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _priceCtrl      = TextEditingController();
  final _stockCtrl      = TextEditingController();
 
  List<File> _images         = [];  // ignore: prefer_final_fields
  List<dynamic> _categories  = [];
  int? _selectedCategoryId;
  bool _loading              = false;
  bool _submitting           = false;
 
  final _picker = ImagePicker();
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }
 
  // ── Navigation ─────────────────────────────────────────────────────────────
 
  void _safePop({bool result = false}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/vendor/products');
    }
  }
 
  // ── Categories ─────────────────────────────────────────────────────────────
 
  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final cats = await StoreProductService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load categories. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ── Image picker ───────────────────────────────────────────────────────────
 
  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    // Offer camera or gallery — same pattern as edit_profile_screen.
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Add Product Image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickFrom(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickFrom(ImageSource.gallery);
            },
            child: const Text('Choose from Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
 
  Future<void> _pickFrom(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null && mounted) {
        setState(() => _images.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
 
  void _removeImage(int index) =>
      setState(() => _images.removeAt(index));
 
  // ── Submit ─────────────────────────────────────────────────────────────────
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 product image.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    setState(() => _submitting = true);
    try {
      final res = await StoreProductService.submitProduct(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price:       double.parse(_priceCtrl.text.trim()),
        stock:       int.parse(_stockCtrl.text.trim()),
        categoryId:  _selectedCategoryId!,
        images:      _images,
      );
 
      if (!mounted) return;
 
      if (res['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product submitted for review!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _safePop(result: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']?.toString() ?? 'Submission failed.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Submit Product',
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
          onPressed: () => _safePop(),
          tooltip: 'Back',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
 
                    // ── Images ─────────────────────────────────────────
                    _SectionLabel('Product Images'),
                    const SizedBox(height: 4),
                    Text(
                      '${_images.length}/5 images • tap to add',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
 
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.asMap().entries.map(
                                (e) => _ImageThumb(
                                    file: e.value,
                                    onRemove: () => _removeImage(e.key)),
                              ),
                          if (_images.length < 5)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                      color: AppColors.border),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(CupertinoIcons.camera,
                                        size: 28,
                                        color: AppColors.textTertiary),
                                    SizedBox(height: 4),
                                    Text('Add',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
 
                    // ── Product name ───────────────────────────────────
                    _SectionLabel('Details'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon:
                            Icon(CupertinoIcons.tag, size: 18),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 16),
 
                    // ── Description ────────────────────────────────────
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 56),
                          child: Icon(CupertinoIcons.doc_text, size: 18),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 16),
 
                    // ── Price + Stock ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price (R)',
                              prefixIcon: Icon(
                                  CupertinoIcons.money_dollar_circle,
                                  size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null) return 'Invalid number';
                              if (val <= 0) return 'Must be > R0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Qty',
                              prefixIcon: Icon(
                                  CupertinoIcons.cube_box, size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final val = int.tryParse(v.trim());
                              if (val == null) return 'Invalid number';
                              if (val < 0) return 'Cannot be negative';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
 
                    // ── Category ───────────────────────────────────────
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                            CupertinoIcons.list_bullet, size: 18),
                      ),
                      items: _categories
                          .map<DropdownMenuItem<int>>(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(
                                c['name'].toString(),
                                style: const TextStyle(
                                    fontFamily: 'Satoshi'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                      validator: (v) =>
                          v == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 32),
 
                    // ── Info banner ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(CupertinoIcons.info_circle,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your product will be reviewed by our team before going live. This usually takes 1–3 business days.',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
 
                    // ── Submit button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit for Review',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────
 
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
 
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w900,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }
}
 
class _ImageThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _ImageThumb({required this.file, required this.onRemove});
 
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
                image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}