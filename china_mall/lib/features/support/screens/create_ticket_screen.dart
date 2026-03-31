import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../providers/support_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();

  String? _selectedCategory;
  bool _saving = false;

  static const _categories = {
    'order_issue': 'Order Issue',
    'delivery_problem': 'Delivery Problem',
    'product_complaint': 'Product Complaint',
    'account_issue': 'Account Issue',
    'payment_dispute': 'Payment Dispute',
  };

  bool get _showOrderField =>
      _selectedCategory == 'order_issue' || _selectedCategory == 'payment_dispute';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/support');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final orderId = _showOrderField && _orderIdCtrl.text.trim().isNotEmpty
        ? int.tryParse(_orderIdCtrl.text.trim())
        : null;

    final success = await context.read<SupportProvider>().createTicket(
          category: _selectedCategory!,
          subject: _subjectCtrl.text.trim(),
          message: _descriptionCtrl.text.trim(),
          orderId: orderId,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket created successfully. We\'ll get back to you soon.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safePop();
    } else {
      final errorMsg = context.read<SupportProvider>().error ?? 'Failed to create ticket.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
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
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'New Support Ticket',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: _safePop,
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Help text ───────────────────────────────────────────────
              OsCard(
                color: AppColors.green050,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.info_circle_fill,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Describe your issue in detail and our team will respond within 24 hours.',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Category ────────────────────────────────────────────────
              const SectionLabel(title: 'Category'),
              GestureDetector(
                onTap: () => _showCategoryPicker(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedCategory != null ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory != null
                              ? _categories[_selectedCategory]!
                              : 'Select a category',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedCategory != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_down, size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Subject ─────────────────────────────────────────────────
              const SectionLabel(title: 'Subject'),
              TextFormField(
                controller: _subjectCtrl,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Brief summary of your issue',
                  counterStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Subject is required';
                  if (v.trim().length < 5) return 'Subject must be at least 5 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Description ─────────────────────────────────────────────
              const SectionLabel(title: 'Description'),
              TextFormField(
                controller: _descriptionCtrl,
                maxLength: 500,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue in detail...',
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length < 20) return 'Please provide at least 20 characters';
                  return null;
                },
              ),

              // ── Order ID (conditional) ──────────────────────────────────
              if (_showOrderField) ...[
                const SizedBox(height: 16),
                const SectionLabel(title: 'Order ID (Optional)'),
                TextFormField(
                  controller: _orderIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter the related order ID',
                    prefixIcon: Icon(CupertinoIcons.cube_box, size: 18),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Submit button ───────────────────────────────────────────
              AppButton(
                label: 'SUBMIT TICKET',
                loading: _saving,
                onTap: _submit,
                icon: CupertinoIcons.paperplane_fill,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category picker bottom sheet ────────────────────────────────────────────

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              const Text(
                'Select Category',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'What kind of issue are you experiencing?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              ..._categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = entry.key);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcon(entry.key),
                          size: 18,
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(CupertinoIcons.check_mark, size: 16, color: AppColors.white),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'order_issue':
        return CupertinoIcons.cube_box;
      case 'delivery_problem':
        return CupertinoIcons.car_detailed;
      case 'product_complaint':
        return CupertinoIcons.exclamationmark_triangle;
      case 'account_issue':
        return CupertinoIcons.person_crop_circle;
      case 'payment_dispute':
        return CupertinoIcons.creditcard;
      default:
        return CupertinoIcons.question_circle;
    }
  }
}
