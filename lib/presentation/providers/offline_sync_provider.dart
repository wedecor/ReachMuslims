import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks offline writes and sync status
class OfflineSyncState {
  final bool hasPendingWrites;
  final int pendingWriteCount;
  final bool isSyncing;

  const OfflineSyncState({
    this.hasPendingWrites = false,
    this.pendingWriteCount = 0,
    this.isSyncing = false,
  });

  OfflineSyncState copyWith({
    bool? hasPendingWrites,
    int? pendingWriteCount,
    bool? isSyncing,
  }) {
    return OfflineSyncState(
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
      pendingWriteCount: pendingWriteCount ?? this.pendingWriteCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// Provider that tracks Firestore pending writes
class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  StreamSubscription<void>? _pendingWritesSubscription;
  Timer? _checkTimer;

  OfflineSyncNotifier() : super(const OfflineSyncState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check for pending writes periodically
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPendingWrites();
    });
  }

  Future<void> _checkPendingWrites() async {
    try {
      // Firestore doesn't expose pending writes directly
      // We can check by attempting a small operation and seeing if it queues
      // For now, we'll use a simpler approach: check connectivity and assume
      // writes are pending if offline and we've made recent writes
      
      // This is a simplified implementation
      // In production, you might want to track writes manually
      final hasPending = false; // Placeholder - would need custom tracking
      
      if (state.hasPendingWrites != hasPending) {
        state = state.copyWith(hasPendingWrites: hasPending);
      }
    } catch (e) {
      // Ignore errors in monitoring
    }
  }

  void markWritePending() {
    state = state.copyWith(
      hasPendingWrites: true,
      pendingWriteCount: state.pendingWriteCount + 1,
    );
  }

  void markWriteSynced() {
    final newCount = (state.pendingWriteCount - 1).clamp(0, double.infinity).toInt();
    state = state.copyWith(
      hasPendingWrites: newCount > 0,
      pendingWriteCount: newCount,
      isSyncing: false,
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _pendingWritesSubscription?.cancel();
    super.dispose();
  }
}

final offlineSyncProvider = StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  return OfflineSyncNotifier();
});

