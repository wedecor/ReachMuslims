import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification.dart' as domain;
import '../../domain/models/lead.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_list_provider.dart';
import 'lead_detail_screen.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated || authState.user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    final userId = authState.user!.uid;
    final notificationState = ref.watch(notificationListProvider(userId));
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationState.notifications.any((n) => !n.read))
            TextButton(
              onPressed: () {
                ref.read(notificationListProvider(userId).notifier).markAllAsRead();
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: _buildBody(notificationState, dateFormat, ref, userId, context),
    );
  }

  Widget _buildBody(
    NotificationListState state,
    DateFormat dateFormat,
    WidgetRef ref,
    String userId,
    BuildContext context,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error!.message}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Retry by refreshing
                ref.invalidate(notificationListProvider(userId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll see notifications here when leads are assigned or updated',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _buildNotificationItem(
          notification,
          dateFormat,
          ref,
          userId,
          context,
        );
      },
    );
  }

  Widget _buildNotificationItem(
    domain.Notification notification,
    DateFormat dateFormat,
    WidgetRef ref,
    String userId,
    BuildContext context,
  ) {
    final isUnread = !notification.read;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isUnread ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread ? Colors.blue : Colors.grey[300],
          child: Icon(
            _getNotificationIcon(notification.type),
            color: isUnread ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            color: isUnread ? Colors.blue[900] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                color: isUnread ? Colors.blue[800] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.circle, size: 8, color: Colors.blue)
            : null,
        onTap: () async {
          // Mark as read if unread
          if (isUnread) {
            await ref.read(notificationListProvider(userId).notifier).markAsRead(notification.id);
          }

          // Navigate to LeadDetailScreen
          if (context.mounted) {
            await _navigateToLead(context, ref, notification.leadId);
          }
        },
      ),
    );
  }

  Future<void> _navigateToLead(
    BuildContext context,
    WidgetRef ref,
    String leadId,
  ) async {
    // Try to get lead from the lead list
    final leadListState = ref.read(leadListProvider);
    Lead? lead;
    
    try {
      lead = leadListState.leads.firstWhere(
        (l) => l.id == leadId,
      );
    } catch (e) {
      // Lead not in list, fetch it directly
      final leadRepository = ref.read(leadRepositoryProvider);
      lead = await leadRepository.getLeadById(leadId);
    }

    if (lead != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadDetailScreen(lead: lead!),
        ),
      );
    } else if (context.mounted) {
      // Show error if lead not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getNotificationIcon(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.leadAssigned:
      case domain.NotificationType.leadReassigned:
        return Icons.person_add;
      case domain.NotificationType.leadStatusChanged:
        return Icons.update;
      case domain.NotificationType.followUpAdded:
        return Icons.note_add;
    }
  }
}

