import '../../../../shared/state/operation_state.dart';
import '../../domain/entities/notification_item.dart';

class NotificationInboxState {
  const NotificationInboxState({
    this.operation = const OperationState<List<NotificationItem>>.idle(),
    this.unreadCount = 0,
  });

  final OperationState<List<NotificationItem>> operation;
  final int unreadCount;

  bool get fetching => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  List<NotificationItem> get items => operation.data ?? const [];

  NotificationInboxState loading() => NotificationInboxState(
    operation: OperationState.loading(data: items),
    unreadCount: unreadCount,
  );

  NotificationInboxState success({
    required List<NotificationItem> items,
    required int unreadCount,
  }) => NotificationInboxState(
    operation: OperationState.success(items),
    unreadCount: unreadCount,
  );

  NotificationInboxState failure(String? message) => NotificationInboxState(
    operation: OperationState.failure(message, data: items),
    unreadCount: unreadCount,
  );

  NotificationInboxState withItems({
    required List<NotificationItem> items,
    int? unreadCount,
  }) => NotificationInboxState(
    operation: OperationState.success(items),
    unreadCount: unreadCount ?? this.unreadCount,
  );
}
