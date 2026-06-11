import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_repository_provider.dart';

import '../../../../fixtures/repositories/fake_notification_repository.dart';

void main() {
  group('NotificationInboxStateNotifier', () {
    late FakeNotificationRepository repository;
    late ProviderContainer container;

    final sampleItems = [
      NotificationItem(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: 'message',
        read: false,
        createdAt: DateTime.utc(2026, 5, 2),
      ),
      NotificationItem(
        id: 'n2',
        title: 'Read item',
        body: 'Body',
        type: 'tip',
        read: true,
        createdAt: DateTime.utc(2026, 5, 1),
      ),
    ];

    setUp(() {
      repository = FakeNotificationRepository();
      container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchInbox loads items and unread count', () async {
      repository.fetchResult = Success(sampleItems);
      repository.unreadCountResult = Success(1);

      await container
          .read(notificationInboxStateProvider.notifier)
          .fetchInbox();

      final state = container.read(notificationInboxStateProvider);
      expect(state.items, hasLength(2));
      expect(state.unreadCount, 1);
    });

    test('fetchInbox falls back to local unread count when count endpoint fails',
        () async {
      repository.fetchResult = Success(sampleItems);
      repository.unreadCountResult = Failure(
        HttpException(title: 'Error', message: 'Count failed'),
      );

      await container
          .read(notificationInboxStateProvider.notifier)
          .fetchInbox();

      final state = container.read(notificationInboxStateProvider);
      expect(state.unreadCount, 1);
    });

    test('markAsRead updates item and unread count', () async {
      repository.fetchResult = Success(sampleItems);
      repository.unreadCountResult = Success(1);

      await container
          .read(notificationInboxStateProvider.notifier)
          .fetchInbox();

      await container
          .read(notificationInboxStateProvider.notifier)
          .markAsRead(id: 'n1');

      final state = container.read(notificationInboxStateProvider);
      expect(repository.lastMarkedReadId, 'n1');
      expect(state.items.first.read, isTrue);
      expect(state.unreadCount, 0);
    });
  });
}
