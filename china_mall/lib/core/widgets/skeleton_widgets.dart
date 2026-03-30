import 'package:flutter/material.dart';
import './shared_widgets.dart';
import '../theme/app_theme.dart';

/// Skeleton loader for product detail screen
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ShimmerBox(
              width: double.infinity, height: 320, radius: 0),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 80, height: 28, radius: 20),
                const SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 28, radius: 8),
                const SizedBox(height: 6),
                ShimmerBox(width: 200, height: 28, radius: 8),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ShimmerBox(width: 80, height: 32, radius: 8),
                    const Spacer(),
                    ShimmerBox(width: 100, height: 20, radius: 8),
                  ],
                ),
                const SizedBox(height: 20),
                ShimmerBox(width: double.infinity, height: 72, radius: 12),
                const SizedBox(height: 24),
                ShimmerBox(width: 120, height: 22, radius: 8),
                const SizedBox(height: 10),
                ShimmerBox(width: double.infinity, height: 16, radius: 6),
                const SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 16, radius: 6),
                const SizedBox(height: 6),
                ShimmerBox(width: 240, height: 16, radius: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for a product card
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 140,
            radius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 14, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 120, height: 14, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 18, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for an order card
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const ShimmerBox(width: 160, height: 18, radius: 6),
              const Spacer(),
              ShimmerBox(width: 80, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 90, height: 20, radius: 6),
              ShimmerBox(width: 60, height: 14, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a store card
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ShimmerBox(width: 60, height: 60, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 16, radius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 180, height: 12, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 14, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
