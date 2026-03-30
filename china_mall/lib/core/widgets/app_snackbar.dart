import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

enum SnackType { success, error, info, warning }

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackType.success:
        backgroundColor = AppColors.success;
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case SnackType.error:
        backgroundColor = AppColors.error;
        icon = CupertinoIcons.xmark_circle_fill;
        break;
      case SnackType.warning:
        backgroundColor = AppColors.warning;
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      default:
        backgroundColor = AppColors.textPrimary;
        icon = CupertinoIcons.info_circle_fill;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static void success(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message,
          type: SnackType.success,
          actionLabel: actionLabel,
          onAction: onAction);

  static void error(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message,
          type: SnackType.error,
          actionLabel: actionLabel,
          onAction: onAction);

  static void info(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message,
          type: SnackType.info,
          actionLabel: actionLabel,
          onAction: onAction);

  static void warning(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message,
          type: SnackType.warning,
          actionLabel: actionLabel,
          onAction: onAction);
}
