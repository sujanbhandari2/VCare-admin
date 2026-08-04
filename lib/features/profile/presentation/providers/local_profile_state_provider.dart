import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_repository_provider.dart';

part 'local_profile_state_provider.g.dart';

@Riverpod(keepAlive: true)
class LocalProfileStateNotifier extends _$LocalProfileStateNotifier {
  @override
  LocalProfile build() {
    return ref.read(localProfileRepositoryProvider).load();
  }

  Future<void> save(LocalProfile profile) async {
    await ref.read(localProfileRepositoryProvider).save(profile);
    state = profile;
  }

  Future<void> updatePersonalInfo({
    required String firstName,
    String middleName = '',
    required String lastName,
    required String email,
    required String phone,
    required String dob,
    String? photoUrl,
  }) async {
    final updated = state.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      dob: dob,
      photoUrl: photoUrl,
    );
    await save(updated);
  }

  Future<void> updateAddress(ProfileAddress? address) async {
    final updated = state.copyWith(
      address: address,
      clearAddress: address == null,
    );
    await save(updated);
  }

  Future<void> updateReferralCode({
    required String agentCode,
    String? referralLink,
  }) async {
    final updated = state.copyWith(
      agentCode: agentCode,
      referralLink: referralLink,
    );
    await save(updated);
  }

  Future<void> updateProfile({
    required String firstName,
    String middleName = '',
    required String lastName,
    required String email,
    required String phone,
    required String dob,
    String? photoUrl,
    ProfileAddress? address,
  }) async {
    final updated = state.copyWith(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      dob: dob,
      photoUrl: photoUrl,
      address: address,
      clearAddress: address == null,
    );
    await save(updated);
  }
}
