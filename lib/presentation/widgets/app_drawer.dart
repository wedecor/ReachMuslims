import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/drawer_menu_item.dart';
import '../screens/notification_inbox_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/pending_access_requests_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/users_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/my_tasks_screen.dart';
import '../../domain/models/user.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Drawer(child: SizedBox.shrink());
    }

    final isAdmin = user.isAdmin;
    final userId = user.uid;
    final unreadCount = ref.watch(unreadCountProvider(userId));
    final menuItems = DrawerMenuItem.getMenuItems(isAdmin: isAdmin);

    return Drawer(
      child: Column(
        children: [
          // User Header Section
          _buildUserHeader(context, user),

          // User Info Section
          _buildUserInfo(context, user),

          const Divider(height: 1),

          // Menu Items Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItemsList(
                menuItems,
                currentRoute,
                unreadCount,
                ref,
                context,
              ),
            ),
          ),

          const Divider(height: 1),

          // Logout Section
          _buildLogoutItem(context, ref),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // User Name
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // User Email
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.badge_outlined,
            'Role',
            user.role?.name.toUpperCase() ?? 'PENDING',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            'Region',
            user.region?.name.toUpperCase() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuItemsList(
    List<DrawerMenuItem> menuItems,
    String currentRoute,
    int unreadCount,
    WidgetRef ref,
    BuildContext context,
  ) {
    final primaryItems = [
      DrawerMenuItemType.leads,
      DrawerMenuItemType.notifications,
      DrawerMenuItemType.dashboard,
    ];
    
    final items = menuItems.where((item) => item.type != DrawerMenuItemType.logout).toList();
    final widgets = <Widget>[];
    
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isPrimary = primaryItems.contains(item.type);
      final isNextSecondary = i < items.length - 1 && 
          !primaryItems.contains(items[i + 1].type);
      
      widgets.add(_buildMenuItem(
        context,
        item,
        currentRoute,
        unreadCount,
        ref,
      ));
      
      // Add divider before first secondary item (Settings)
      if (isPrimary && isNextSecondary) {
        widgets.add(const Divider(height: 1));
      }
    }
    
    return widgets;
  }

  Widget _buildMenuItem(
    BuildContext context,
    DrawerMenuItem item,
    String currentRoute,
    int unreadCount,
    WidgetRef ref,
  ) {
    final isSelected = item.route == currentRoute;
    final badgeCount = item.showBadge ? unreadCount : null;

    return ListTile(
      leading: Icon(
        isSelected ? item.selectedIcon : item.icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: (badgeCount != null && badgeCount > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      onTap: () => _handleMenuItemTap(context, item, ref),
    );
  }

  void _handleMenuItemTap(BuildContext context, DrawerMenuItem item, WidgetRef ref) {
    Navigator.pop(context);

    // Navigate to the appropriate screen
    Widget? screen;
    switch (item.type) {
      case DrawerMenuItemType.leads:
        // Already on leads screen, no navigation needed
        return;
      case DrawerMenuItemType.notifications:
        screen = const NotificationInboxScreen();
        break;
      case DrawerMenuItemType.myTasks:
        screen = const MyTasksScreen();
        break;
      case DrawerMenuItemType.dashboard:
        screen = const DashboardScreen();
        break;
      case DrawerMenuItemType.pendingRequests:
        screen = const PendingAccessRequestsScreen();
        break;
      case DrawerMenuItemType.userManagement:
        screen = const UserManagementScreen();
        break;
      case DrawerMenuItemType.users:
        screen = const UsersScreen();
        break;
      case DrawerMenuItemType.reports:
        screen = const ReportsScreen();
        break;
      case DrawerMenuItemType.settings:
        screen = const SettingsScreen();
        break;
      case DrawerMenuItemType.about:
        screen = const AboutScreen();
        break;
      case DrawerMenuItemType.logout:
        // Handled separately
        return;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.logout,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        'Logout',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        Navigator.pop(context);
        try {
          await ref.read(authProvider.notifier).logout();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logout failed: ${e.toString()}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
    );
  }
}

