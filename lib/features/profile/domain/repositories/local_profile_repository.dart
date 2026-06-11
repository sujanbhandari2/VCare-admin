import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';

abstract class LocalProfileRepository {
  LocalProfile load();

  Future<void> save(LocalProfile profile);
}
