import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Inline widget that calls /api/analytics/delivery-pricing/ and shows the fee
class DeliveryCalculator extends StatefulWidget {
  final double subtotal;
  final String initialMethod;
  final ValueChanged<String>? onMethodChanged;
  final ValueChanged<double>? onFeeCalculated;

  const DeliveryCalculator({
    super.key,
    required this.subtotal,
    this.initialMethod = 'standard',
    this.onMethodChanged,
    this.onFeeCalculated,
  });

  @override
  State<DeliveryCalculator> createState() => _DeliveryCalculatorState();
}

class _DeliveryCalculatorState extends State<DeliveryCalculator> {
  late String _method;
  double? _fee;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _method = widget.initialMethod;
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    final res = await ApiService.calculateDelivery(widget.subtotal, _method);
    if (!mounted) return;
    setState(() {
      _fee = res.isSuccess
          ? (res.data['delivery_fee'] ?? 0).toDouble()
          : null;
      _loading = false;
    });
    if (_fee != null) widget.onFeeCalculated?.call(_fee!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Method',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...AppConstants.deliveryMethods.entries.map((e) {
            final isSelected = _method == e.key;
            return GestureDetector(
              onTap: () {
                setState(() => _method = e.key);
                widget.onMethodChanged?.call(e.key);
                _calculate();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      _loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              _fee != null
                                  ? _fee == 0
                                      ? 'FREE'
                                      : 'R ${_fee!.toStringAsFixed(2)}'
                                  : '—',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _fee == 0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                  ],
                ),
              ),
            );
          }),
          if (widget.subtotal >= 500)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(CupertinoIcons.gift_fill,
                      size: 13, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Orders over R500 qualify for free standard delivery!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
