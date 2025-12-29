import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../providers/user_management_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/errors/failures.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userManagementState = ref.watch(userManagementProvider);

    // Check admin access
    if (!authState.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Admin access required'),
        ),
      );
    }

    final currentUserId = authState.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userManagementProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: userManagementState.isLoading && userManagementState.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : userManagementState.error != null && userManagementState.users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${userManagementState.error!.message}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(userManagementProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : userManagementState.users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(userManagementProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: userManagementState.users.length,
                        itemBuilder: (context, index) {
                          final user = userManagementState.users[index];
                          final isCurrentUser = user.uid == currentUserId;
                          return _buildUserCard(context, user, isCurrentUser);
                        },
                      ),
                    ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, bool isCurrentUser) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.active ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.active ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: user.active ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Role', user.role?.name.toUpperCase() ?? 'N/A'),
                const SizedBox(width: 8),
                _buildInfoChip('Region', user.region?.name.toUpperCase() ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCurrentUser) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'role':
                          _showRoleDialog(context, user);
                          break;
                        case 'region':
                          _showRegionDialog(context, user);
                          break;
                        case 'deactivate':
                          _showDeactivateDialog(context, user);
                          break;
                        case 'activate':
                          _activateUser(user);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'role',
                        child: Row(
                          children: [
                            Icon(Icons.badge, size: 20),
                            SizedBox(width: 8),
                            Text('Change Role'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'region',
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 20),
                            SizedBox(width: 8),
                            Text('Change Region'),
                          ],
                        ),
                      ),
                      if (user.active)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Deactivate', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (!user.active)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Activate', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ] else
                  Text(
                    'Cannot modify your own account',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showRoleDialog(BuildContext context, User user) async {
    UserRole? selectedRole = user.role;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Role'),
          content: DropdownButtonFormField<UserRole>(
            value: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setDialogState(() {
                selectedRole = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedRole != null && selectedRole != user.role) {
                  Navigator.pop(context);
                  _updateUserRole(user, selectedRole!);
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRegionDialog(BuildContext context, User user) async {
    UserRegion? selectedRegion = user.region;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Region'),
          content: DropdownButtonFormField<UserRegion>(
            value: selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Region',
              border: OutlineInputBorder(),
            ),
            items: UserRegion.values.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setDialogState(() {
                selectedRegion = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedRegion != null && selectedRegion != user.region) {
                  Navigator.pop(context);
                  _updateUserRegion(user, selectedRegion!);
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeactivateDialog(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Are you sure you want to deactivate ${user.name}? They will not be able to login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deactivateUser(user);
    }
  }

  Future<void> _updateUserRole(User user, UserRole role) async {
    final success = await ref.read(userManagementProvider.notifier).updateUserRole(user.uid, role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Role updated successfully' : 'Failed to update role'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserRegion(User user, UserRegion region) async {
    final success = await ref.read(userManagementProvider.notifier).updateUserRegion(user.uid, region);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Region updated successfully' : 'Failed to update region'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateUser(User user) async {
    final success = await ref.read(userManagementProvider.notifier).deactivateUser(user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User deactivated' : 'Failed to deactivate user'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _activateUser(User user) async {
    final success = await ref.read(userManagementProvider.notifier).activateUser(user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User activated' : 'Failed to activate user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

