import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_sync_provider.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../data/repositories/lead_repository_impl.dart';
import '../../core/errors/failures.dart';
import '../../core/services/activity_logger.dart';

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepositoryImpl();
});

/// Widget that displays a star icon to toggle lead priority
/// Shows filled star (⭐) when priority is true, outline star (☆) when false
class PriorityStarToggle extends ConsumerStatefulWidget {
  final Lead lead;

  const PriorityStarToggle({
    super.key,
    required this.lead,
  });

  @override
  ConsumerState<PriorityStarToggle> createState() => _PriorityStarToggleState();
}

class _PriorityStarToggleState extends ConsumerState<PriorityStarToggle> {
  bool _isUpdating = false;
  bool _optimisticPriority = false;

  @override
  void initState() {
    super.initState();
    _optimisticPriority = widget.lead.isPriority;
  }

  @override
  void didUpdateWidget(PriorityStarToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lead.id != widget.lead.id || oldWidget.lead.isPriority != widget.lead.isPriority) {
      _optimisticPriority = widget.lead.isPriority;
    }
  }

  Future<void> _togglePriority() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _showError('User not authenticated');
      return;
    }

    final user = authState.user!;
    final isAdmin = user.isAdmin;
    final isSales = user.isSales;

    // Check permissions
    if (!isAdmin && !isSales) {
      _showError('You do not have permission to change priority');
      return;
    }

    // Sales can only toggle priority for assigned leads
    if (isSales && widget.lead.assignedTo != user.uid) {
      _showError('You can only change priority for your assigned leads');
      return;
    }

    // Optimistic update
    setState(() {
      _isUpdating = true;
      _optimisticPriority = !_optimisticPriority;
    });

    try {
      // Mark write as pending if offline
      final connectivityState = ref.read(connectivityProvider);
      if (!connectivityState.isOnline) {
        ref.read(offlineSyncProvider.notifier).markWritePending();
      }

      final leadRepository = ref.read(leadRepositoryProvider);
      await leadRepository.updatePriority(widget.lead.id, _optimisticPriority);

      // Log activity
      try {
        final logger = ref.read(activityLoggerProvider);
        await logger.logPriorityChanged(
          leadId: widget.lead.id,
          performedBy: user.uid,
          performedByName: user.name,
          isPriority: _optimisticPriority,
        );
      } catch (e) {
        // Don't fail the priority update if activity logging fails
        debugPrint('Failed to log priority change activity: $e');
      }

      // Mark as synced if online
      if (connectivityState.isOnline) {
        ref.read(offlineSyncProvider.notifier).markWriteSynced();
      }

      // Refresh lead list to get updated data
      ref.read(leadListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _optimisticPriority
                  ? 'Lead marked as priority'
                  : 'Lead priority removed',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Rollback optimistic update
      setState(() {
        _optimisticPriority = widget.lead.isPriority;
      });

      final errorMessage = e is Failure
          ? e.message
          : 'Failed to update priority: ${e.toString()}';
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isUpdating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _optimisticPriority ? Icons.star : Icons.star_border,
              color: _optimisticPriority 
                  ? Theme.of(context).colorScheme.secondary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
      tooltip: _optimisticPriority ? 'Remove priority' : 'Mark as priority',
      onPressed: _isUpdating ? null : _togglePriority,
    );
  }
}

