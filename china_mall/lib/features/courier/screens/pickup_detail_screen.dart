import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pickup_assignment.dart';
import '../services/courier_mock_data.dart';
import '../widgets/item_checklist.dart';
import '../widgets/verification_code_input.dart';

class PickupDetailScreen extends StatefulWidget {
  final int assignmentId;

  const PickupDetailScreen({super.key, required this.assignmentId});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  late PickupAssignment _assignment;
  bool _codeHasError = false;
  bool _isVerifying = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _assignment = CourierMockData.pickupAssignments
        .firstWhere((a) => a.id == widget.assignmentId);
  }

  void _toggleItem(int itemId) {
    setState(() {
      final item = _assignment.items.firstWhere((i) => i.id == itemId);
      if (!item.isMissing) {
        item.isVerified = !item.isVerified;
      }
    });
  }

  void _markMissing(int itemId, String note) {
    setState(() {
      final item = _assignment.items.firstWhere((i) => i.id == itemId);
      item.isMissing = true;
      item.missingNote = note;
      item.isVerified = false;
    });
  }

  void _verifyCode(String code) {
    setState(() {
      _isVerifying = true;
      _codeHasError = false;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (code == CourierMockData.pickupCode) {
        setState(() {
          _isVerifying = false;
          _showSuccess = true;
          _assignment.status = PickupStatus.pickedUp;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      } else {
        setState(() {
          _isVerifying = false;
          _codeHasError = true;
        });
      }
    });
  }

  Future<void> _callStore() async {
    final uri = Uri.parse('tel:${_assignment.storePhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _assignment.storeName,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone, color: AppColors.primary),
            onPressed: _callStore,
          ),
        ],
      ),
      body: _showSuccess
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.checkCircle2,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pickup Confirmed!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.store,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _assignment.storeLocation,
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _assignment.storePhone,
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
                          onTap: _callStore,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.phone,
                                color: AppColors.success, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item checklist
                  ItemChecklist(
                    items: _assignment.items,
                    onToggleItem: _toggleItem,
                    onMarkMissing: _markMissing,
                  ),

                  // Handoff code section (appears after all items verified)
                  if (_assignment.allVerified) ...[
                    const SizedBox(height: 28),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 20),
                    const Text(
                      'ENTER HANDOFF CODE',
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
                      'Ask the store owner for the handoff code',
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
                                'Confirm Pickup',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
