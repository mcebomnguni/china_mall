import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
 
class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});
 
  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}
 
class _DisputesScreenState extends State<DisputesScreen> {
  List _disputes = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getDisputes();
    if (!mounted) return;
    setState(() {
      _disputes = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  void _showRaiseDispute() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RaiseDisputeSheet(onCreated: _load),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Disputes',
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          TextButton.icon(
            onPressed: _showRaiseDispute,
            icon: const Icon(CupertinoIcons.plus, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _disputes.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.exclamationmark_bubble,
                  title: 'No disputes',
                  subtitle:
                      'If you have an issue with an order, raise a dispute here.',
                  buttonLabel: 'Raise a Dispute',
                  onButton: _showRaiseDispute,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _disputes.length,
                    itemBuilder: (_, i) {
                      final d = _disputes[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Dispute #${d['id']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Spacer(),
                                _DisputeStatusChip(
                                    status: d['status'] ?? 'open'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Order: ${d['order_number'] ?? '#${d['order']}'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d['description'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
 
class _DisputeStatusChip extends StatelessWidget {
  final String status;
  const _DisputeStatusChip({required this.status});
 
  Color get _color {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'in_review':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
 
class _RaiseDisputeSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _RaiseDisputeSheet({required this.onCreated});
 
  @override
  State<_RaiseDisputeSheet> createState() => _RaiseDisputeSheetState();
}
 
class _RaiseDisputeSheetState extends State<_RaiseDisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orderCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
 
  @override
  void dispose() {
    _orderCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final orderId = int.tryParse(_orderCtrl.text);
    if (orderId == null) return;
 
    setState(() => _saving = true);
    final res = await ApiService.createDispute({
      'order': orderId,
      'description': _descCtrl.text.trim(),
    });
    setState(() => _saving = false);
 
    if (!mounted) return;
    if (res.isSuccess) {
      widget.onCreated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute raised — our team will review it.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Raise a Dispute',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Our team will investigate and respond within 48 hours.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
 
            TextFormField(
              controller: _orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Order ID'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter the order ID' : null,
            ),
            const SizedBox(height: 12),
 
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText:
                    'What went wrong? Be as specific as possible...',
              ),
              validator: (v) =>
                  v == null || v.length < 20
                      ? 'Please provide at least 20 characters'
                      : null,
            ),
            const SizedBox(height: 20),
 
            AppButton(
              label: 'Submit Dispute',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}