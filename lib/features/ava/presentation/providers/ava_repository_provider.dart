import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/ava_repository_impl.dart';
import '../../domain/repositories/ava_repository.dart';

part 'ava_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AvaRepository avaRepository(Ref ref) {
  return AvaRepositoryImpl();
}
