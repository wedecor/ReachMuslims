import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../core/errors/failures.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

class NotificationListState {
  final List<Notification> notifications;
  final bool isLoading;
  final Failure? error;
  final int unreadCount;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = true,
    this.error,
    this.unreadCount = 0,
  });

  NotificationListState copyWith({
    List<Notification>? notifications,
    bool? isLoading,
    Failure? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? (notifications?.where((n) => !n.read).length ?? this.unreadCount),
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _notificationRepository;
  final String _userId;
  StreamSubscription<List<Notification>>? _subscription;

  NotificationListNotifier(this._notificationRepository, this._userId)
      : super(const NotificationListState()) {
    _init();
  }

  void _init() {
    _subscription = _notificationRepository.streamNotifications(_userId).listen(
      (notifications) {
        state = state.copyWith(
          notifications: notifications,
          isLoading: false,
          clearError: true,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error is Failure ? error : FirestoreFailure('Failed to load notifications: ${error.toString()}'),
        );
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to mark as read: ${e.toString()}'),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead(_userId);
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to mark all as read: ${e.toString()}'),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final notificationListProvider = StateNotifierProvider.family<NotificationListNotifier, NotificationListState, String>((ref, userId) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return NotificationListNotifier(notificationRepository, userId);
});

// Derived provider for unread count
final unreadCountProvider = Provider.family<int, String>((ref, userId) {
  final notificationState = ref.watch(notificationListProvider(userId));
  return notificationState.notifications.where((n) => !n.read).length;
});

