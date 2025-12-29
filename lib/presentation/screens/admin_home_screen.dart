import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/notification_badge.dart';
import '../widgets/app_drawer.dart';
import 'lead_list_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: const [
          NotificationBadge(),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/leads'),
      body: const LeadListScreen(),
    );
  }
}

