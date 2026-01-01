import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/user.dart';
import '../providers/pending_users_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../core/errors/failures.dart';

final userRepositoryForApprovalProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

class PendingAccessRequestsScreen extends ConsumerStatefulWidget {
  const PendingAccessRequestsScreen({super.key});

  @override
  ConsumerState<PendingAccessRequestsScreen> createState() => _PendingAccessRequestsScreenState();
}

class _PendingAccessRequestsScreenState extends ConsumerState<PendingAccessRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final pendingState = ref.watch(pendingUsersProvider);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    // Check admin access
    if (!authState.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Admin access required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Access Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(pendingUsersProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: pendingState.isLoading && pendingState.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : pendingState.error != null && pendingState.users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${pendingState.error!.message}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(pendingUsersProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : pendingState.users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pending requests',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(pendingUsersProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: pendingState.users.length,
                        itemBuilder: (context, index) {
                          final user = pendingState.users[index];
                          return _buildRequestCard(context, user, dateFormat);
                        },
                      ),
                    ),
    );
  }

  Widget _buildRequestCard(BuildContext context, User user, DateFormat dateFormat) {
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
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${user.phone}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (user.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Requested: ${dateFormat.format(user.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _showApproveDialog(context, user),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(BuildContext context, User user) async {
    UserRole? selectedRole;
    UserRegion? selectedRegion;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Approve Access Request'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Approve access for ${user.name}?'),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<UserRole>(
                    decoration: const InputDecoration(
                      labelText: 'Role *',
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRegion>(
                    decoration: const InputDecoration(
                      labelText: 'Region *',
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a region';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate() && selectedRole != null && selectedRegion != null) {
                  Navigator.pop(context);
                  _approveUser(user, selectedRole!, selectedRegion!);
                }
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, User user) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Access Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject access request for ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter rejection reason...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(user, reasonController.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(User user, UserRole role, UserRegion region) async {
    final authState = ref.read(authProvider);
    if (!authState.isAdmin || authState.user == null) {
      final colorScheme = Theme.of(context).colorScheme;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin access required'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    final approvedBy = authState.user!.uid;
    final userRepository = ref.read(userRepositoryForApprovalProvider);
    final notificationRepository = ref.read(notificationRepositoryProvider);

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approving user...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Approve user
      await userRepository.approveUser(
        userId: user.uid,
        role: role,
        region: region,
        approvedBy: approvedBy,
      );

      // Send notification (non-blocking)
      try {
        await notificationRepository.createNotification(
          userId: user.uid,
          title: 'Access Approved',
          body: 'Your Reach Muslim lead portal access has been approved.',
        );
      } catch (e) {
        // Log but don't fail approval
        debugPrint('Failed to send notification: $e');
      }

      // Refresh list
      await ref.read(pendingUsersProvider.notifier).refresh();

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User approved successfully'),
            backgroundColor: colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Failure ? e.message : 'Failed to approve user: ${e.toString()}',
            ),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(User user, String? reason) async {
    final authState = ref.read(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    if (!authState.isAdmin || authState.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin access required'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    final rejectedBy = authState.user!.uid;
    final userRepository = ref.read(userRepositoryForApprovalProvider);

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rejecting user...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Reject user
      await userRepository.rejectUser(
        userId: user.uid,
        rejectedBy: rejectedBy,
        rejectionReason: reason,
      );

      // Refresh list
      await ref.read(pendingUsersProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User rejected'),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Failure ? e.message : 'Failed to reject user: ${e.toString()}',
            ),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }
}

