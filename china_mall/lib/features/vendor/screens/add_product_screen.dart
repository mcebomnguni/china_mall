import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_constants.dart';
 
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
  final _imageCtrl = TextEditingController();
  String _category = 'clothing';
  bool _saving = false;
 
  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _stockCtrl, _imageCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
 
    final res = await ApiService.createProduct({
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
          content: Text('Product submitted for review!'),
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
        title: const Text('Add Product'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('ℹ️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Products are reviewed by our team before going live.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
 
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
 
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (R)',
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
                      decoration:
                          const InputDecoration(labelText: 'Stock Qty'),
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
 
              // Category
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
                          child: Text(
                              '${c['icon']} ${c['label']}'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? 'clothing'),
              ),
              const SizedBox(height: 12),
 
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(CupertinoIcons.photo,
                      color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 32),
 
              AppButton(
                label: 'Submit for Review',
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
