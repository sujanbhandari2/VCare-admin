import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/my_tasks/data/repositories/my_task_repository_impl.dart';
import 'package:vcare_admin/features/my_tasks/domain/repositories/my_task_repository.dart';

part 'my_task_repository_provider.g.dart';

@Riverpod(keepAlive: true)
MyTaskRepository myTaskRepository(Ref ref) {
  return MyTaskRepositoryImpl(ref.read(apiClientProvider));
}
