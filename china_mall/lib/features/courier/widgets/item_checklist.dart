import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pickup_assignment.dart';
import 'missing_item_sheet.dart';

class ItemChecklist extends StatelessWidget {
  final List<PickupOrderItem> items;
  final ValueChanged<int> onToggleItem;
  final void Function(int itemId, String note) onMarkMissing;

  const ItemChecklist({
    super.key,
    required this.items,
    required this.onToggleItem,
    required this.onMarkMissing,
  });

  @override
  Widget build(BuildContext context) {
    final verified = items.where((i) => i.isVerified || i.isMissing).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ITEMS',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              '$verified/${items.length} items verified',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: verified == items.length
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _ItemRow(
              item: item,
              onToggle: () => onToggleItem(item.id),
              onMarkMissing: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MissingItemSheet(
                    itemName: item.productName,
                    onSubmit: (note) => onMarkMissing(item.id, note),
                  ),
                );
              },
            )),
      ],
    );
  }
}

class _ItemRow extends StatefulWidget {
  final PickupOrderItem item;
  final VoidCallback onToggle;
  final VoidCallback onMarkMissing;

  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onMarkMissing,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (!widget.item.isVerified && !widget.item.isMissing) {
      _bounceController.forward(from: 0);
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDone = item.isVerified || item.isMissing;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.isMissing
            ? AppColors.error.withValues(alpha: 0.05)
            : isDone
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isMissing
              ? AppColors.error.withValues(alpha: 0.2)
              : isDone
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: item.isMissing ? null : _handleToggle,
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isMissing
                      ? AppColors.error
                      : item.isVerified
                          ? AppColors.success
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isMissing
                        ? AppColors.error
                        : item.isVerified
                            ? AppColors.success
                            : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? Icon(
                        item.isMissing ? Icons.close : Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDone
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity}${item.sizeOrColor != null ? ' / ${item.sizeOrColor}' : ''} \u2022 ${item.orderRef}',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (item.isMissing && item.missingNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Missing: ${item.missingNote}',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isDone)
            TextButton(
              onPressed: widget.onMarkMissing,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Missing'),
            ),
        ],
      ),
    );
  }
}
