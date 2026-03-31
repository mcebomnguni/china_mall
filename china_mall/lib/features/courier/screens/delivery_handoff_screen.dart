import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_task.dart';
import '../services/courier_mock_data.dart';
import '../widgets/verification_code_input.dart';
import '../widgets/delivery_confirmed_animation.dart';

class DeliveryHandoffScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryHandoffScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryHandoffScreen> createState() => _DeliveryHandoffScreenState();
}

class _DeliveryHandoffScreenState extends State<DeliveryHandoffScreen> {
  late DeliveryTask _task;
  bool _codeHasError = false;
  bool _isVerifying = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _task = CourierMockData.deliveryTasks
        .firstWhere((t) => t.id == widget.deliveryId);
  }

  void _verifyCode(String code) {
    setState(() {
      _isVerifying = true;
      _codeHasError = false;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (code == CourierMockData.deliveryCode) {
        setState(() {
          _isVerifying = false;
          _showSuccess = true;
          _task.status = DeliveryStatus.delivered;
        });
      } else {
        setState(() {
          _isVerifying = false;
          _codeHasError = true;
        });
      }
    });
  }

  Future<void> _callCustomer() async {
    final uri = Uri.parse('tel:${_task.customerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showUnavailableSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerUnavailableSheet(
        onRetry: () {
          Navigator.of(context).pop();
        },
        onReschedule: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rescheduled for next batch'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onReturnToStore: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: DeliveryConfirmedAnimation(
          onComplete: () {
            if (mounted) context.pop();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Delivery Confirmation',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _task.customerName,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _task.deliveryAddress,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _callCustomer,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone,
                              color: AppColors.success, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Items for verification
            const Text(
              'ITEMS FOR DELIVERY',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            ..._task.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Qty: ${item.quantity} \u2022 ${item.storeName}',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 28),
            const Divider(color: AppColors.border),
            const SizedBox(height: 20),

            // Delivery code section
            const Text(
              'ENTER DELIVERY CODE',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask the customer for their delivery code',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            VerificationCodeInput(
              onCodeComplete: _verifyCode,
              hasError: _codeHasError,
              isLoading: _isVerifying,
            ),
            if (_codeHasError) ...[
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Invalid code. Please try again.',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : null, // Code auto-submits
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirm Delivery',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showUnavailableSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Customer Unavailable',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CustomerUnavailableSheet extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onReschedule;
  final VoidCallback onReturnToStore;

  const _CustomerUnavailableSheet({
    required this.onRetry,
    required this.onReschedule,
    required this.onReturnToStore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          const Text(
            'Customer Unavailable',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'What would you like to do?',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.refresh,
            label: 'Retry Delivery',
            subtitle: 'Try reaching the customer again',
            color: AppColors.info,
            onTap: onRetry,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.schedule,
            label: 'Reschedule',
            subtitle: 'Move to next batch window',
            color: AppColors.warning,
            onTap: onReschedule,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.store_outlined,
            label: 'Return to Store',
            subtitle: 'Return items back to the store',
            color: AppColors.error,
            onTap: onReturnToStore,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
