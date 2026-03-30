import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(); // vendor price
  final _stockCtrl = TextEditingController();
  final _productRefCtrl = TextEditingController();
  final _fabricCtrl = TextEditingController();
  final _colourInputCtrl = TextEditingController();
  final _dimLCtrl = TextEditingController();
  final _dimWCtrl = TextEditingController();
  final _dimHCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  // State
  String _category = 'clothing';
  bool _saving = false;
  List<XFile> _images = [];
  final Set<String> _selectedSizes = {};
  final List<String> _colours = [];
  bool _isOnSale = false;

  static const _clothingSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'
  ];
  static const _shoeSizes = [
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'
  ];

  // Category type helpers
  bool get _isClothing =>
      ['clothing', 'sportswear', 'accessories'].contains(_category);
  bool get _isShoes => _category == 'shoes';
  bool get _isBags => _category == 'bags';
  bool get _hasSize => _isClothing || _isShoes;
  bool get _hasDimensions =>
      ['furniture', 'blankets', 'carpets', 'kitchen'].contains(_category);
  bool get _hasFabric =>
      _isClothing || _isShoes || ['blankets', 'carpets'].contains(_category);

  // Computed prices
  double? get _vendorPrice => double.tryParse(_priceCtrl.text.trim());
  double? get _customerPrice =>
      _vendorPrice != null ? _vendorPrice! * 1.20 : null;
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
    for (final c in [
      _nameCtrl, _descCtrl, _priceCtrl, _stockCtrl, _productRefCtrl,
      _fabricCtrl, _colourInputCtrl, _dimLCtrl, _dimWCtrl, _dimHCtrl,
      _discountCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
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
        final url =
            await ApiService.uploadProductImage(bytes, user.id, filename);
        if (url != null) urls.add(url);
      } catch (_) {
        // skip failed uploads; product still saves with remaining images
      }
    }
    return urls;
  }

  void _addColour() {
    final c = _colourInputCtrl.text.trim();
    if (c.isEmpty || _colours.contains(c)) return;
    setState(() {
      _colours.add(c);
      _colourInputCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least 3 product photos.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _saving = true);

    // Upload images first
    final imageUrls = await _uploadImages();

    final vendorPrice = _vendorPrice ?? 0;
    final customerPrice = vendorPrice * 1.20;
    final salePrice = _salePriceCalc;
    final discountPct = double.tryParse(_discountCtrl.text.trim()) ?? 0;

    final res = await ApiService.createProduct({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'vendor_price': vendorPrice,
      'price': customerPrice,
      'stock_quantity': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'category': _category,
      'product_ref_id': _productRefCtrl.text.trim().isEmpty
          ? null
          : _productRefCtrl.text.trim(),
      'fabric_material':
          _hasFabric && _fabricCtrl.text.trim().isNotEmpty
              ? _fabricCtrl.text.trim()
              : null,
      'sizes': _hasSize ? _selectedSizes.toList() : [],
      'colours': _colours,
      'dimensions': _hasDimensions
          ? {
              'length': double.tryParse(_dimLCtrl.text) ?? 0,
              'width': double.tryParse(_dimWCtrl.text) ?? 0,
              'height': double.tryParse(_dimHCtrl.text) ?? 0,
            }
          : {},
      'is_on_sale': _isOnSale,
      'discount_percent': _isOnSale ? discountPct : 0,
      'sale_price': _isOnSale ? salePrice : null,
      'image_urls': imageUrls,
    });

    setState(() => _saving = false);
    if (!mounted) return;

    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product submitted for review!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go('/vendor/products');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.errorMessage),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
      );

  Widget _imageTile(int index, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_images[index].path),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Cover',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Satoshi')),
              ),
            ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addImageTile(double size) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.camera_fill,
                color: AppColors.textTertiary, size: 24),
            SizedBox(height: 4),
            Text('Add\nPhotos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 10,
                    color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final totalGaps = 2 * 10.0; // 3 cols → 2 gaps
      final tileSize = (constraints.maxWidth - totalGaps) / 3;
      final tiles = <Widget>[];
      for (int i = 0; i < _images.length; i++) {
        tiles.add(_imageTile(i, tileSize));
      }
      if (_images.length < 10) tiles.add(_addImageTile(tileSize));
      return Wrap(spacing: 10, runSpacing: 10, children: tiles);
    });
  }

  Widget _sizeChips() {
    final sizes = _isShoes ? _shoeSizes : _clothingSizes;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        final selected = _selectedSizes.contains(size);
        return FilterChip(
          label: Text(size,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              )),
          selected: selected,
          onSelected: (val) => setState(() {
            if (val) {
              _selectedSizes.add(size);
            } else {
              _selectedSizes.remove(size);
            }
          }),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceVariant,
          checkmarkColor: Colors.white,
          side: BorderSide(
              color:
                  selected ? AppColors.primary : AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  Widget _colourInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _colourInputCtrl,
              style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g. Red, Navy Blue, Black',
              ),
              onFieldSubmitted: (_) => _addColour(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _addColour,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Add',
                style: TextStyle(
                    fontFamily: 'Satoshi', fontWeight: FontWeight.w700)),
          ),
        ]),
        if (_colours.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _colours
                .map((c) => Chip(
                      label: Text(c,
                          style: const TextStyle(
                              fontFamily: 'Satoshi', fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _colours.remove(c)),
                      backgroundColor: AppColors.surfaceVariant,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _dimensionFields() {
    return Row(children: [
      Expanded(
        child: TextFormField(
          controller: _dimLCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Length (cm)',
            hintText: '0',
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: _dimWCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Width (cm)',
            hintText: '0',
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: _dimHCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            hintText: '0',
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Product',
            style: TextStyle(
                fontFamily: 'Satoshi', fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/vendor/products'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(CupertinoIcons.info_circle,
                      size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Products are reviewed by our team before going live. Min. 3 photos required.',
                      style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          color: AppColors.accent),
                    ),
                  ),
                ]),
              ),

              // ── Photos ──────────────────────────────────────────────────
              _sectionHeader('PRODUCT PHOTOS'),
              _imageGrid(),
              if (_images.length < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_images.length}/3 minimum photos added',
                    style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 11,
                        color: AppColors.error),
                  ),
                ),

              // ── Basic Info ───────────────────────────────────────────────
              _sectionHeader('BASIC INFORMATION'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                decoration:
                    const InputDecoration(labelText: 'Product Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _productRefCtrl,
                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Your Product Reference / SKU (optional)',
                  hintText: 'e.g. SKU-001',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border)),
                ),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(
                          value: c['slug'],
                          child: Text('${c['icon']} ${c['label']}',
                              style: const TextStyle(
                                  fontFamily: 'Satoshi', fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _category = v ?? 'clothing';
                  _selectedSizes.clear();
                }),
              ),

              // ── Pricing & Stock ──────────────────────────────────────────
              _sectionHeader('PRICING & STOCK'),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Your Price (R) *',
                      prefixText: 'R ',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    decoration: const InputDecoration(labelText: 'Stock Qty *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ]),
              if (_customerPrice != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(CupertinoIcons.tag_fill,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Customer pays: R${_customerPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.accent),
                    ),
                    const Spacer(),
                    const Text('incl. 20% fee',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                  ]),
                ),
              ],

              // ── Description ──────────────────────────────────────────────
              _sectionHeader('DESCRIPTION'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                decoration:
                    const InputDecoration(labelText: 'Product Description *'),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Please provide a description (min. 10 characters)';
                  }
                  return null;
                },
              ),

              // ── Attributes ───────────────────────────────────────────────
              _sectionHeader('ATTRIBUTES'),

              if (_hasSize) ...[
                const Text('Available Sizes',
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _sizeChips(),
                const SizedBox(height: 16),
              ],

              const Text('Available Colours',
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _colourInput(),
              const SizedBox(height: 16),

              if (_hasFabric) ...[
                TextFormField(
                  controller: _fabricCtrl,
                  style:
                      const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                  decoration:
                      const InputDecoration(labelText: 'Fabric / Material'),
                ),
                const SizedBox(height: 16),
              ],

              if (_hasDimensions) ...[
                const Text('Dimensions (cm)',
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _dimensionFields(),
                const SizedBox(height: 16),
              ],

              // ── Promotions ───────────────────────────────────────────────
              _sectionHeader('PROMOTIONS'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('On Sale',
                                style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              _isOnSale
                                  ? 'Sale badge shown to buyers'
                                  : 'Highlight this product as a deal',
                              style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOnSale,
                        onChanged: (v) => setState(() => _isOnSale = v),
                        activeColor: AppColors.primary,
                      ),
                    ]),
                    if (_isOnSale) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              suffixText: '%',
                            ),
                            validator: (v) {
                              if (!_isOnSale) return null;
                              final d = double.tryParse(v ?? '');
                              if (d == null || d <= 0 || d >= 100) {
                                return '1–99%';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_salePriceCalc != null) ...[
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R${_customerPrice!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.lineThrough),
                              ),
                              Text(
                                'R${_salePriceCalc!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'SUBMIT FOR REVIEW',
                loading: _saving,
                onTap: _save,
                icon: CupertinoIcons.checkmark_circle,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
