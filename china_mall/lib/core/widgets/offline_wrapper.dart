import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Wraps any screen and shows an offline banner at the top when disconnected.
class OfflineWrapper extends StatelessWidget {
  final Widget child;
  const OfflineWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: online ? 0 : 36,
          color: AppColors.error,
          child: online
              ? const SizedBox.shrink()
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.wifi_slash, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
