import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

enum ReviewType { product, store }

class WriteReviewSheet extends StatefulWidget {
  final int targetId;
  final ReviewType type;
  final String targetName;
  final VoidCallback? onSubmitted;

  const WriteReviewSheet({
    super.key,
    required this.targetId,
    required this.type,
    required this.targetName,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required int targetId,
    required ReviewType type,
    required String targetName,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewSheet(
        targetId: targetId,
        type: type,
        targetName: targetName,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _commentCtrl = TextEditingController();
  double _rating = 5.0;
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final body = {
      'rating': _rating.toInt(),
      'comment': _commentCtrl.text.trim(),
    };

    ApiResponse res;
    if (widget.type == ReviewType.product) {
      res = await ApiService.postProductReview(widget.targetId, body);
    } else {
      res = await ApiService.postStoreReview(widget.targetId, body);
    }

    setState(() => _saving = false);
    if (!mounted) return;

    if (res.isSuccess) {
      widget.onSubmitted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted — thank you!'),
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

  String get _ratingLabel {
    if (_rating >= 5) return 'Excellent!';
    if (_rating >= 4) return 'Very Good';
    if (_rating >= 3) return 'Good';
    if (_rating >= 2) return 'Fair';
    return 'Poor';
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
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          Text(
            widget.type == ReviewType.product
                ? 'Review this Product'
                : 'Review this Store',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.targetName,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Star rating
          Center(
            child: Column(
              children: [
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 44,
                  itemBuilder: (_, __) => const Icon(
                    CupertinoIcons.star_fill,
                    color: AppColors.accent,
                  ),
                  onRatingUpdate: (r) => setState(() => _rating = r),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _ratingLabel,
                    key: ValueKey(_ratingLabel),
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Comment field
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Share your experience — what did you love or dislike?',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            label: 'Submit Review',
            loading: _saving,
            onTap: _submit,
            icon: CupertinoIcons.star_fill,
          ),
        ],
      ),
    );
  }
}
