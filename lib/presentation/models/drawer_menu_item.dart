import 'package:flutter/material.dart';

enum DrawerMenuItemType {
  leads,
  notifications,
  myTasks,
  dashboard,
  pendingRequests,
  userManagement,
  users,
  reports,
  expenses,
  settings,
  about,
  logout,
}

class DrawerMenuItem {
  final DrawerMenuItemType type;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final bool requiresAdmin;
  final bool showBadge;
  final String? route;

  const DrawerMenuItem({
    required this.type,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.requiresAdmin = false,
    this.showBadge = false,
    this.route,
  });

  static List<DrawerMenuItem> getMenuItems({required bool isAdmin}) {
    return [
      const DrawerMenuItem(
        type: DrawerMenuItemType.leads,
        title: 'Leads',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: '/leads',
      ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.notifications,
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        showBadge: true,
        route: '/notifications',
      ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.myTasks,
        title: 'My Tasks',
        icon: Icons.task_outlined,
        selectedIcon: Icons.task,
        route: '/my-tasks',
      ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.dashboard,
        title: 'Dashboard',
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        route: '/dashboard',
      ),
      // Admin only items
      if (isAdmin)
        const DrawerMenuItem(
          type: DrawerMenuItemType.pendingRequests,
          title: 'Pending Requests',
          icon: Icons.pending_outlined,
          selectedIcon: Icons.pending,
          requiresAdmin: true,
          route: '/pending-requests',
        ),
      if (isAdmin)
        const DrawerMenuItem(
          type: DrawerMenuItemType.userManagement,
          title: 'User Management',
          icon: Icons.people_outlined,
          selectedIcon: Icons.people,
          requiresAdmin: true,
          route: '/user-management',
        ),
      if (isAdmin)
        const DrawerMenuItem(
          type: DrawerMenuItemType.users,
          title: 'Users / Team',
          icon: Icons.group_outlined,
          selectedIcon: Icons.group,
          requiresAdmin: true,
          route: '/users',
        ),
      if (isAdmin)
        const DrawerMenuItem(
          type: DrawerMenuItemType.reports,
          title: 'Reports',
          icon: Icons.assessment_outlined,
          selectedIcon: Icons.assessment,
          requiresAdmin: true,
          route: '/reports',
        ),
      if (isAdmin)
        const DrawerMenuItem(
          type: DrawerMenuItemType.expenses,
          title: 'Expenses',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          requiresAdmin: true,
          route: '/expenses',
        ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.settings,
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        route: '/settings',
      ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.about,
        title: 'About',
        icon: Icons.info_outlined,
        selectedIcon: Icons.info,
        route: '/about',
      ),
      const DrawerMenuItem(
        type: DrawerMenuItemType.logout,
        title: 'Logout',
        icon: Icons.logout,
        selectedIcon: Icons.logout,
        route: null,
      ),
    ];
  }
}

