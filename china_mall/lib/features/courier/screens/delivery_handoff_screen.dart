import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  int _retryCount = 0;
  static const int _maxRetries = 3;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _task = CourierMockData.deliveryTasks
        .firstWhere((t) => t.id == widget.deliveryId);
  }

  void _verifyCode(String code) {
    if (_retryCount >= _maxRetries) return;

    setState(() {
      _isVerifying = true;
      _codeHasError = false;
      _errorMessage = '';
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
          _retryCount++;
          if (_retryCount >= _maxRetries) {
            _errorMessage = 'Too many attempts. Please contact support.';
          } else {
            _errorMessage =
                'Invalid code. Please try again. (${_maxRetries - _retryCount} attempts remaining)';
          }
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
        onRetryLater: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Timer set -- retry in 30 minutes',
                style: TextStyle(fontFamily: 'Satoshi'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onReschedule: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Rescheduled for next batch',
                style: TextStyle(fontFamily: 'Satoshi'),
              ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
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
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Info Card ──────────────────────────────────
                _buildCustomerCard(),
                const SizedBox(height: 24),

                // ── Items for Delivery ─────────────────────────────────
                _buildItemsSection(),
                const SizedBox(height: 28),

                const Divider(color: AppColors.border),
                const SizedBox(height: 24),

                // ── Delivery Code Section ──────────────────────────────
                _buildCodeSection(),
                const SizedBox(height: 20),

                // ── Customer Unavailable ───────────────────────────────
                _buildUnavailableButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── Success Overlay with Confetti ──────────────────────────
          if (_showSuccess)
            DeliveryConfirmedAnimation(
              orderRef: _task.orderRef,
              onComplete: () {
                if (mounted) context.pop();
              },
            ),
        ],
      ),
    );
  }

  // ── Customer Info Card ───────────────────────────────────────────────────
  Widget _buildCustomerCard() {
    return Container(
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
          // Name row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.user,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _task.customerFullName,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.mapPin,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _task.fullAddress,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Phone row (tappable)
          GestureDetector(
            onTap: _callCustomer,
            child: Row(
              children: [
                const Icon(LucideIcons.phone,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  _task.customerPhone,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          // ETA info if sent
          if (_task.etaAgoText != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(LucideIcons.clock,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _task.etaAgoText!,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Items for Delivery ───────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(LucideIcons.package,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
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
          ],
        ),
        const SizedBox(height: 8),

        // Info text
        const Text(
          'Please hand the package to the customer and ask them to verify the contents',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Item list
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
                  const Icon(LucideIcons.shoppingBag,
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
                        const SizedBox(height: 2),
                        Text(
                          [
                            'Qty: ${item.quantity}',
                            if (item.size != null) 'Size: ${item.size}',
                          ].join(' \u2022 '),
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
      ],
    );
  }

  // ── Delivery Code Section ────────────────────────────────────────────────
  Widget _buildCodeSection() {
    final lockedOut = _retryCount >= _maxRetries;

    return Column(
      children: [
        // Title
        const Text(
          'Confirm Delivery',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ask the customer for their delivery code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Key icon
        Icon(
          LucideIcons.keyRound,
          size: 48,
          color: lockedOut
              ? AppColors.textTertiary
              : AppColors.primary,
        ),
        const SizedBox(height: 20),

        // Code input or locked out message
        if (lockedOut)
          _buildLockedOutMessage()
        else ...[
          VerificationCodeInput(
            onCodeComplete: _verifyCode,
            hasError: _codeHasError,
            isLoading: _isVerifying,
          ),

          // Error message
          if (_codeHasError && _errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : null, // Code auto-submits
                icon: _isVerifying
                    ? const SizedBox.shrink()
                    : const Icon(LucideIcons.checkCircle, size: 20),
                label: _isVerifying
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLockedOutMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.headphones,
                size: 26, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          const Text(
            'Too many attempts',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please contact support for assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer Unavailable Button ──────────────────────────────────────────
  Widget _buildUnavailableButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showUnavailableSheet,
        icon: const Icon(LucideIcons.userX, size: 18),
        label: const Text(
          'Customer Unavailable',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── Customer Unavailable Bottom Sheet ────────────────────────────────────────
class _CustomerUnavailableSheet extends StatefulWidget {
  final VoidCallback onRetryLater;
  final VoidCallback onReschedule;
  final VoidCallback onReturnToStore;

  const _CustomerUnavailableSheet({
    required this.onRetryLater,
    required this.onReschedule,
    required this.onReturnToStore,
  });

  @override
  State<_CustomerUnavailableSheet> createState() =>
      _CustomerUnavailableSheetState();
}

class _CustomerUnavailableSheetState extends State<_CustomerUnavailableSheet> {
  final _notesController = TextEditingController();
  String? _selectedOption;
  bool _showAfter3pmWarning = false;

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    _showAfter3pmWarning = hour >= 15;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedOption == null) return;
    switch (_selectedOption) {
      case 'retry':
        widget.onRetryLater();
        break;
      case 'reschedule':
        widget.onReschedule();
        break;
      case 'return':
        widget.onReturnToStore();
        break;
    }
  }

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
          // Drag handle
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

          // Options
          _UnavailableOptionTile(
            icon: LucideIcons.clock,
            label: 'Try again in 30 minutes',
            subtitle: 'Sets a timer, keeps delivery active',
            color: AppColors.info,
            selected: _selectedOption == 'retry',
            onTap: () => setState(() => _selectedOption = 'retry'),
          ),
          const SizedBox(height: 10),
          _UnavailableOptionTile(
            icon: LucideIcons.calendarClock,
            label: 'Reschedule to next batch',
            subtitle: 'Move delivery to next batch window',
            color: AppColors.warning,
            selected: _selectedOption == 'reschedule',
            onTap: () => setState(() => _selectedOption = 'reschedule'),
          ),
          const SizedBox(height: 10),
          _UnavailableOptionTile(
            icon: LucideIcons.undo2,
            label: 'Return to store',
            subtitle: 'Mark items as returned',
            color: AppColors.error,
            selected: _selectedOption == 'return',
            onTap: () => setState(() => _selectedOption = 'return'),
          ),

          // After 3pm warning
          if (_showAfter3pmWarning) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle,
                      size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'It is after 3 PM. Rescheduling may push to tomorrow.',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Notes field
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _selectedOption != null
                    ? AppColors.primaryGradient
                    : null,
                color: _selectedOption == null
                    ? AppColors.textTertiary.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _selectedOption != null ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.white54,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }
}

class _UnavailableOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _UnavailableOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
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
                    style: const TextStyle(
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
            if (selected)
              Icon(LucideIcons.checkCircle2, size: 20, color: color)
            else
              const Icon(LucideIcons.chevronRight,
                  size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
