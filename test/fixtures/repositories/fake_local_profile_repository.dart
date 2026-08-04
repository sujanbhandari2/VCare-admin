import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/repositories/local_profile_repository.dart';

class FakeLocalProfileRepository implements LocalProfileRepository {
  FakeLocalProfileRepository([LocalProfile? initial])
    : _profile =
          initial ??
          const LocalProfile(
            firstName: 'Agent',
            lastName: 'User',
            email: 'agent@gmail.com',
            phone: '+15551234567',
            dob: '01/15/1990',
            referralLink: 'https://vcare.app/refer/old-code',
            agentCode: 'old-code',
          );

  LocalProfile _profile;
  int saveCallCount = 0;

  @override
  LocalProfile load() => _profile;

  @override
  Future<void> save(LocalProfile profile) async {
    saveCallCount++;
    _profile = profile;
  }
}
