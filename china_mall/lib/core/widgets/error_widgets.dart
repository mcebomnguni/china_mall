import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Shown when an API call fails
class NetworkErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.wifi_slash,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Could not connect to the server.\nMake sure your backend is running.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown on unknown routes
class NotFoundWidget extends StatelessWidget {
  final VoidCallback? onGoHome;

  const NotFoundWidget({super.key, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '404',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Page not found',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The page you\'re looking for doesn\'t exist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onGoHome,
                icon: const Icon(CupertinoIcons.house_fill, size: 16),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page loading indicator with optional message
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner (non-modal)
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(CupertinoIcons.xmark,
                  color: AppColors.error, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

/// Success banner
class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.checkmark_circle,
              color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog helper
class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
