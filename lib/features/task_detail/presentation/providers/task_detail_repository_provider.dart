import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/task_detail/data/repositories/task_detail_repository_impl.dart';
import 'package:vcare_admin/features/task_detail/domain/repositories/task_detail_repository.dart';

part 'task_detail_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TaskDetailRepository taskDetailRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return TaskDetailRepositoryImpl(apiClient);
}
