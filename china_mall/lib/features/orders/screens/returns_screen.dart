import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_constants.dart';
 
class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});
 
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}
 
class _ReturnsScreenState extends State<ReturnsScreen> {
  List _returns = [];
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getReturns();
    if (!mounted) return;
    setState(() {
      _returns = res.isSuccess ? (res.data as List? ?? []) : [];
      _loading = false;
    });
  }
 
  void _showCreateReturn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateReturnSheet(onCreated: _load),
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
          'Returns',
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
            onPressed: _showCreateReturn,
            icon: const Icon(CupertinoIcons.plus, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _returns.isEmpty
              ? EmptyState(
                  icon: CupertinoIcons.arrow_uturn_left_circle,
                  title: 'No returns',
                  subtitle:
                      'You haven\'t raised any return requests yet.\nReturns must be within 3 days of delivery.',
                  buttonLabel: 'Request a Return',
                  onButton: _showCreateReturn,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _returns.length,
                    itemBuilder: (_, i) {
                      final ret = _returns[i];
                      final reason = AppConstants.returnReasons[ret['reason']] ??
                          ret['reason'] ?? '';
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
                                Text(
                                  'Return #${ret['id']}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                _ReturnStatusChip(
                                    status: ret['status'] ?? 'pending'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Order: ${ret['order_number'] ?? '#${ret['order']}'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.tag_fill,
                                    size: 13, color: AppColors.textTertiary),
                                const SizedBox(width: 5),
                                Text(reason,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                              ],
                            ),
                            if (ret['description'] != null &&
                                (ret['description'] as String).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                ret['description'],
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
 
class _ReturnStatusChip extends StatelessWidget {
  final String status;
  const _ReturnStatusChip({required this.status});
 
  Color get _color {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'processing':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
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
 
class _CreateReturnSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateReturnSheet({required this.onCreated});
 
  @override
  State<_CreateReturnSheet> createState() => _CreateReturnSheetState();
}
 
class _CreateReturnSheetState extends State<_CreateReturnSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orderCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _reason = 'damaged';
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
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid order ID'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    setState(() => _saving = true);
    final res = await ApiService.createReturn({
      'order': orderId,
      'reason': _reason,
      'description': _descCtrl.text.trim(),
    });
    setState(() => _saving = false);
 
    if (!mounted) return;
    if (res.isSuccess) {
      widget.onCreated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted'),
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
            Text('Request a Return',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Returns accepted within 3 days of delivery.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
 
            TextFormField(
              controller: _orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Order ID'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your order ID' : null,
            ),
            const SizedBox(height: 12),
 
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: InputDecoration(
                labelText: 'Reason',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: AppConstants.returnReasons.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'damaged'),
            ),
            const SizedBox(height: 12),
 
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue...'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please describe the issue' : null,
            ),
            const SizedBox(height: 20),
 
            AppButton(
              label: 'Submit Return',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}