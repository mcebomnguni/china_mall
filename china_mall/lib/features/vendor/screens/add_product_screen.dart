import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/supabase_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _productRefCtrl = TextEditingController();
  final _fabricCtrl = TextEditingController();
  final _colourInputCtrl = TextEditingController();
  final _dimLCtrl = TextEditingController();
  final _dimWCtrl = TextEditingController();
  final _dimHCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  String _category = 'clothing';
  bool _saving = false;
  List<XFile> _images = [];
  final Set<String> _selectedSizes = {};
  final List<String> _colours = [];
  bool _isOnSale = false;

  static const _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
  static const _shoeSizes = ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'];

  bool get _isClothing => ['clothing', 'sportswear', 'accessories'].contains(_category);
  bool get _isShoes => _category == 'shoes';
  bool get _hasSize => _isClothing || _isShoes;
  bool get _hasDimensions => ['furniture', 'blankets', 'carpets', 'kitchen'].contains(_category);
  bool get _hasFabric => _isClothing || _isShoes || ['blankets', 'carpets'].contains(_category);

  double? get _vendorPrice => double.tryParse(_priceCtrl.text.trim());
  double? get _customerPrice => _vendorPrice != null ? _vendorPrice! * 1.20 : null;
  double? get _salePriceCalc {
    if (!_isOnSale || _customerPrice == null) return null;
    final disc = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    if (disc <= 0 || disc >= 100) return null;
    return _customerPrice! * (1 - disc / 100);
  }

  @override
  void initState() {
    super.initState();
    _priceCtrl.addListener(() => setState(() {}));
    _discountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _stockCtrl, _productRefCtrl,
        _fabricCtrl, _colourInputCtrl, _dimLCtrl, _dimWCtrl, _dimHCtrl, _discountCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked);
      if (_images.length > 10) _images = _images.sublist(0, 10);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (!SupabaseService.isReady) return [];
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];
    final urls = <String>[];
    for (int i = 0; i < _images.length; i++) {
      try {
        final Uint8List bytes = await _images[i].readAsBytes();
        final ext = _images[i].name.split('.').last.toLowerCase();
        final filename = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final url = await ApiService.uploadProductImage(bytes, user.id, filename);
        if (url != null) urls.add(url);
      } catch (_) {}
    }
    return urls;
  }

  void _addColour() {
    final c = _colourInputCtrl.text.trim();
    if (c.isEmpty || _colours.contains(c)) return;
    setState(() { _colours.add(c); _colourInputCtrl.clear(); });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least 3 product photos.'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final imageUrls = await _uploadImages();
    final vendorPrice = _vendorPrice ?? 0;
    final res = await ApiService.createProduct({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'vendor_price': vendorPrice,
      'price': vendorPrice * 1.20,
      'stock_quantity': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'category': _category,
      'product_ref_id': _productRefCtrl.text.trim().isEmpty ? null : _productRefCtrl.text.trim(),
      'fabric_material': _hasFabric && _fabricCtrl.text.trim().isNotEmpty ? _fabricCtrl.text.trim() : null,
      'sizes': _hasSize ? _selectedSizes.toList() : [],
      'colours': _colours,
      'dimensions': _hasDimensions ? {'length': double.tryParse(_dimLCtrl.text) ?? 0, 'width': double.tryParse(_dimWCtrl.text) ?? 0, 'height': double.tryParse(_dimHCtrl.text) ?? 0} : {},
      'is_on_sale': _isOnSale,
      'discount_percent': _isOnSale ? (double.tryParse(_discountCtrl.text.trim()) ?? 0) : 0,
      'sale_price': _isOnSale ? _salePriceCalc : null,
      'image_urls': imageUrls,
    });
    setState(() => _saving = false);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product submitted for review!'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.errorMessage),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/vendor/products'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Review notice ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(CupertinoIcons.info_circle, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Products are reviewed before going live. Min. 3 photos required.',
                        style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.accent),
                      )),
                    ]),
                  ),

                  // ── Photos ─────────────────────────────────────
                  _header('PRODUCT PHOTOS'),
                  _photoGrid(),
                  if (_images.length < 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${_images.length}/3 minimum photos', style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.error)),
                    ),

                  // ── Basic info ─────────────────────────────────
                  _header('BASIC INFORMATION'),
                  _field(_nameCtrl, 'Product Name *', validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _field(_productRefCtrl, 'Product Reference / SKU (optional)'),
                  const SizedBox(height: 12),
                  _categoryPicker(),

                  // ── Pricing ────────────────────────────────────
                  _header('PRICING & STOCK'),
                  Row(children: [
                    Expanded(child: _field(_priceCtrl, 'Your Price (R) *',
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                        prefix: 'R ',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        })),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_stockCtrl, 'Stock Qty *',
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid';
                          return null;
                        })),
                  ]),
                  if (_customerPrice != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(CupertinoIcons.tag_fill, size: 14, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text('Customer pays: R${_customerPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent)),
                        const Spacer(),
                        const Text('incl. 20% fee', style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.textTertiary)),
                      ]),
                    ),
                  ],

                  // ── Description ────────────────────────────────
                  _header('DESCRIPTION'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                    decoration: const InputDecoration(labelText: 'Product Description *'),
                    validator: (v) => v == null || v.trim().length < 10 ? 'Min. 10 characters' : null,
                  ),

                  // ── Attributes ─────────────────────────────────
                  _header('ATTRIBUTES'),
                  if (_hasSize) ...[
                    const Text('Available Sizes', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (_isShoes ? _shoeSizes : _clothingSizes).map((s) {
                        final on = _selectedSizes.contains(s);
                        return FilterChip(
                          label: Text(s, style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : AppColors.textPrimary)),
                          selected: on,
                          onSelected: (v) => setState(() => v ? _selectedSizes.add(s) : _selectedSizes.remove(s)),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceVariant,
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: on ? AppColors.primary : AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Available Colours', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _colourInputCtrl,
                      style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                      decoration: const InputDecoration(hintText: 'e.g. Red, Navy Blue'),
                      onFieldSubmitted: (_) => _addColour(),
                    )),
                    const SizedBox(width: 10),
                    SizedBox(height: 48, child: ElevatedButton(
                      onPressed: _addColour,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Add', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700)),
                    )),
                  ]),
                  if (_colours.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 6, children: _colours.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _colours.remove(c)),
                      backgroundColor: AppColors.surfaceVariant,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList()),
                  ],
                  const SizedBox(height: 16),

                  if (_hasFabric) ...[
                    _field(_fabricCtrl, 'Fabric / Material'),
                    const SizedBox(height: 16),
                  ],
                  if (_hasDimensions) ...[
                    const Text('Dimensions (cm)', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _field(_dimLCtrl, 'Length', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_dimWCtrl, 'Width', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_dimHCtrl, 'Height', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // ── Promotions ─────────────────────────────────
                  _header('PROMOTIONS'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('On Sale', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(_isOnSale ? 'Sale badge shown to buyers' : 'Highlight this product as a deal',
                              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.textTertiary)),
                        ])),
                        Switch(value: _isOnSale, onChanged: (v) => setState(() => _isOnSale = v), activeTrackColor: AppColors.primary),
                      ]),
                      if (_isOnSale) ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _field(_discountCtrl, 'Discount %',
                              keyboard: const TextInputType.numberWithOptions(decimal: true),
                              suffix: '%',
                              validator: (v) {
                                if (!_isOnSale) return null;
                                final d = double.tryParse(v ?? '');
                                if (d == null || d <= 0 || d >= 100) return '1–99%';
                                return null;
                              })),
                          if (_salePriceCalc != null) ...[
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('R${_customerPrice!.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.lineThrough)),
                              Text('R${_salePriceCalc!.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.error)),
                            ]),
                          ],
                        ]),
                      ],
                    ]),
                  ),

                  // ── Submit ─────────────────────────────────────
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(CupertinoIcons.checkmark_circle),
                      label: Text(_saving ? 'SUBMITTING...' : 'SUBMIT FOR REVIEW',
                          style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textTertiary)),
  );

  Widget _field(TextEditingController ctrl, String label, {
    TextInputType? keyboard, String? prefix, String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix),
      validator: validator,
    );
  }

  Widget _categoryPicker() {
    const cats = <String, String>{
      'clothing': 'Clothing', 'shoes': 'Shoes', 'accessories': 'Accessories',
      'sportswear': 'Sportswear', 'bags': 'Bags', 'blankets': 'Blankets',
      'furniture': 'Furniture', 'carpets': 'Carpets', 'kitchen': 'Kitchen',
      'toys': 'Toys', 'electronics': 'Electronics',
    };
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(labelText: 'Category'),
      style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, color: AppColors.textPrimary),
      items: cats.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) { if (v != null) setState(() { _category = v; _selectedSizes.clear(); }); },
    );
  }

  Widget _photoGrid() {
    final count = _images.length + (_images.length < 10 ? 1 : 0);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        if (i < _images.length) return _photoTile(i);
        return _addPhotoTile();
      },
    );
  }

  Widget _photoTile(int i) {
    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(_images[i].path, fit: BoxFit.cover)
            : Image.file(File(_images[i].path), fit: BoxFit.cover),
      ),
      if (i == 0)
        Positioned(bottom: 6, left: 6, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
          child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Satoshi')),
        )),
      Positioned(top: 4, right: 4, child: GestureDetector(
        onTap: () => setState(() => _images.removeAt(i)),
        child: Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 13, color: Colors.white),
        ),
      )),
    ]);
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.camera_fill, color: AppColors.textTertiary, size: 24),
          SizedBox(height: 4),
          Text('Add\nPhotos', textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Satoshi', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
        ]),
      ),
    );
  }
}
