import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/sales_home_screen.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.error != null && !authState.isAuthenticated) {
      return LoginScreen();
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final user = authState.user;
    if (user == null) {
      return const LoginScreen();
    }

    // Check if user is approved (should already be checked in repository, but double-check)
    if (!user.isApproved) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pending_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your access request is pending admin approval.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is active (should already be checked in repository, but double-check)
    if (!user.active) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Inactive',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been deactivated.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Route based on role
    if (user.isAdmin) {
      return const AdminHomeScreen();
    } else if (user.isSales) {
      return const SalesHomeScreen();
    }

    // Fallback to login if role is unknown
    return const LoginScreen();
  }
}

