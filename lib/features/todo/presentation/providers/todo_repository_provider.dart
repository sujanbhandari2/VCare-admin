import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/todo/data/repositories/todo_repository_impl.dart';
import 'package:vcare_admin/features/todo/domain/repositories/todo_repository.dart';

part 'todo_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TodoRepository todoRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TodoRepositoryImpl(apiClient);
}
