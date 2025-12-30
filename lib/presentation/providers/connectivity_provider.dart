import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity state
class ConnectivityState {
  final bool isOnline;
  final bool isInitialized;

  const ConnectivityState({
    required this.isOnline,
    this.isInitialized = false,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    bool? isInitialized,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Connectivity notifier that monitors network state
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(const ConnectivityState(isOnline: true, isInitialized: false)) {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    final isOnline = _isOnline(result);
    
    state = ConnectivityState(
      isOnline: isOnline,
      isInitialized: true,
    );

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _isOnline(results);
      state = state.copyWith(isOnline: isOnline);
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    // Consider online if any connection type is available
    return results.any((result) => 
      result != ConnectivityResult.none
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

