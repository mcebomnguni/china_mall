import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_constants.dart';
 
class EditProductScreen extends StatefulWidget {
  final int productId;
  const EditProductScreen({super.key, required this.productId});
 
  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}
 
class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _category = 'clothing';
  bool _loading = true;
  bool _saving = false;
 
  @override
  void initState() {
    super.initState();
    _loadProduct();
  }
 
  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _stockCtrl, _imageCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
 
  Future<void> _loadProduct() async {
    final res = await ApiService.getProduct(widget.productId);
    if (!mounted) return;
    if (res.isSuccess) {
      final p = res.data;
      _nameCtrl.text = p['name'] ?? '';
      _descCtrl.text = p['description'] ?? '';
      _priceCtrl.text = (p['price'] ?? 0).toString();
      _stockCtrl.text = (p['stock_quantity'] ?? 0).toString();
      _imageCtrl.text = p['image'] ?? '';
      _category = p['category']?['slug'] ?? 'clothing';
    }
    setState(() => _loading = false);
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
 
    final res = await ApiService.updateProduct(widget.productId, {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
      'category': _category,
      if (_imageCtrl.text.isNotEmpty) 'image_url': _imageCtrl.text.trim(),
    });
 
    setState(() => _saving = false);
    if (!mounted) return;
 
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/vendor/products');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current image preview
                    if (_imageCtrl.text.isNotEmpty)
                      Container(
                        height: 180,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AppNetworkImage(
                            url: _imageCtrl.text,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
 
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Product Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
 
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Description'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
 
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'R ',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null) return 'Invalid price';
                              if (val <= 0) return 'Must be greater than R0';
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
                                labelText: 'Stock Qty'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
 
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: AppConstants.categories
                          .map((c) => DropdownMenuItem(
                                value: c['slug'],
                                child: Text('${c['icon']} ${c['label']}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'clothing'),
                    ),
                    const SizedBox(height: 12),
 
                    TextFormField(
                      controller: _imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        prefixIcon: Icon(CupertinoIcons.photo,
                            color: AppColors.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 32),
 
                    AppButton(
                      label: 'Save Changes',
                      loading: _saving,
                      onTap: _save,
                      icon: CupertinoIcons.checkmark,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
 