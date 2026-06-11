import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:vcare_admin/features/notifications/domain/repositories/notification_repository.dart';

part 'notification_repository_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);

  return NotificationRepositoryImpl(apiClient);
}
