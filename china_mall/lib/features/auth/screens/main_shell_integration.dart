// ─────────────────────────────────────────────────────────────────────────────
// HOW TO INTEGRATE SessionManager INTO YOUR main_shell.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Your main_shell.dart is your root authenticated widget.
// Wrap it with SessionActivityDetector and init SessionManager.
//
// Example (add to your existing main_shell.dart):

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/session_manager.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Init session manager — redirects to login after 4 min inactivity
    SessionManager.init(
      onSessionExpired: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please sign in again.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.go('/login');
        }
      },
    );
  }

  @override
  void dispose() {
    SessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap your entire shell with SessionActivityDetector
    return SessionActivityDetector(
      child: Scaffold(
        // ... your existing bottom nav, body, etc.
      ),
    );
  }
}
