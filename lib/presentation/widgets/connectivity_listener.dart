import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_sync_provider.dart';
import 'pending_sync_indicator.dart';

/// Listens to connectivity changes and shows sync feedback
class ConnectivityListener extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends ConsumerState<ConnectivityListener> {
  bool _wasOffline = false;

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityProvider);
    
    // Show sync success when coming back online after being offline
    if (connectivityState.isInitialized) {
      if (_wasOffline && connectivityState.isOnline) {
        // Connection restored - mark pending writes as syncing
        final syncNotifier = ref.read(offlineSyncProvider.notifier);
        syncNotifier.state = syncNotifier.state.copyWith(isSyncing: true);
        
        // Show sync success after a brief delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && context.mounted) {
              // Clear pending writes after sync
              final syncState = ref.read(offlineSyncProvider);
              if (syncState.hasPendingWrites) {
                ref.read(offlineSyncProvider.notifier).state = 
                  const OfflineSyncState();
                showSyncSuccessMessage(context);
              }
            }
          });
        });
      }
      _wasOffline = !connectivityState.isOnline;
    }

    return widget.child;
  }
}

