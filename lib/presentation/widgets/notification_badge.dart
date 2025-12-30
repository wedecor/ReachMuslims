import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notification_inbox_screen.dart';
import '../../domain/models/notification.dart' as domain;

class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated || authState.user == null) {
      return const SizedBox.shrink();
    }

    final userId = authState.user!.uid;
    final unreadCount = ref.watch(unreadCountProvider(userId));

    if (unreadCount == 0) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _navigateToInbox(context),
        tooltip: 'Notifications',
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _navigateToInbox(context),
          tooltip: 'Notifications',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToInbox(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationInboxScreen(),
      ),
    );
  }
}

class NotificationSheet extends ConsumerWidget {
  final String userId;

  const NotificationSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationListProvider(userId));
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (notificationState.notifications.any((n) => !n.read))
                    TextButton(
                      onPressed: () {
                        ref.read(notificationListProvider(userId).notifier).markAllAsRead();
                      },
                      child: const Text('Mark all as read'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Notifications list
            Expanded(
              child: _buildNotificationsList(notificationState, dateFormat, ref, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsList(
    NotificationListState state,
    DateFormat dateFormat,
    WidgetRef ref,
    ScrollController scrollController,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error!.message}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
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
            Icon(Icons.notifications_none, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _buildNotificationItem(notification, dateFormat, ref);
      },
    );
  }

  Widget _buildNotificationItem(
    domain.Notification notification,
    DateFormat dateFormat,
    WidgetRef ref,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read 
            ? Theme.of(context).colorScheme.surfaceContainerHighest 
            : Theme.of(context).colorScheme.primary,
        child: Icon(
          _getNotificationIcon(notification.type),
          color: notification.read 
              ? Theme.of(context).colorScheme.onSurfaceVariant 
              : Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: notification.read
          ? null
          : Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
      onTap: () {
        if (!notification.read) {
          ref.read(notificationListProvider(userId).notifier).markAsRead(notification.id);
        }
      },
    );
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

