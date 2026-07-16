import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/notification_item.dart';
import '../state/notification_inbox_state.dart';
import 'notification_repository_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'notification_inbox_state_provider.g.dart';

@Riverpod(keepAlive: true)
class NotificationInboxStateNotifier extends _$NotificationInboxStateNotifier {
  @override
  NotificationInboxState build() => const NotificationInboxState();

  Future<void> fetchInbox({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(List<NotificationItem>?)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final repository = ref.read(notificationRepositoryProvider);
    final response = await repository.fetchNotifications(
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (items) async {
        final unreadCount = await _resolveUnreadCount(
          items: items,
          cancelToken: cancelToken,
        );

        if (ref.mounted) {
          state = state.success(items: items, unreadCount: unreadCount);
        }
        onCompleted?.call(items);
      },
    );
  }

  Future<void> refresh({CancelToken? cancelToken}) {
    return fetchInbox(forceRefresh: true, cancelToken: cancelToken);
  }

  Future<void> markAsRead({
    required String id,
    CancelToken? cancelToken,
    void Function()? onCompleted,
  }) async {
    final response = await ref
        .read(notificationRepositoryProvider)
        .markNotificationRead(id: id, cancelToken: cancelToken);

    response.when(
      failure: (_) {},
      success: (_) {
        if (!ref.mounted) return;

        final updatedItems = state.items
            .map(
              (item) => item.id == id ? item.copyWith(read: true) : item,
            )
            .toList();
        final unreadCount = updatedItems.where((item) => !item.read).length;

        state = state.withItems(
          items: updatedItems,
          unreadCount: unreadCount,
        );
        onCompleted?.call();
      },
    );
  }

  Future<int> _resolveUnreadCount({
    required List<NotificationItem> items,
    CancelToken? cancelToken,
  }) async {
    final countResponse = await ref
        .read(notificationRepositoryProvider)
        .fetchUnreadCount(cancelToken: cancelToken);

    return countResponse.when(
      failure: (_) => items.where((item) => !item.read).length,
      success: (count) => count,
    );
  }
}
