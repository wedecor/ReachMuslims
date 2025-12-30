import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offline_sync_provider.dart';
import '../providers/connectivity_provider.dart';

/// Widget that shows a pending sync indicator when offline writes are queued
class PendingSyncIndicator extends ConsumerWidget {
  const PendingSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncProvider);
    final connectivityState = ref.watch(connectivityProvider);
    
    // Only show when offline and there are pending writes
    if (!syncState.hasPendingWrites || connectivityState.isOnline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            syncState.pendingWriteCount > 1
                ? '${syncState.pendingWriteCount} changes pending sync...'
                : '1 change pending sync...',
            style: TextStyle(
              color: colorScheme.onTertiaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to show sync success message
void showSyncSuccessMessage(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.cloud_done, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          const Text('All changes synced successfully'),
        ],
      ),
      backgroundColor: colorScheme.primaryContainer,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

