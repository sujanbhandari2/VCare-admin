import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/services/network/http_exception.dart';
import 'package:flutter_template/features/profile/presentation/providers/user_profile_repository_provider.dart';
import 'package:flutter_template/features/profile/presentation/providers/user_profile_state_provider.dart';
import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';

import '../../../../fixtures/repositories/fake_user_profile_repository.dart';

void main() {
  group('UserProfileStateNotifier', () {
    late FakeUserProfileRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeUserProfileRepository();
      container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetch success updates profile data', () async {
      await container
          .read(userProfileStateProvider.notifier)
          .fetchProfile(profileId: 99);

      final state = container.read(userProfileStateProvider);

      expect(state.fetching, isFalse);
      expect(state.profile?.id, 99);
      expect(state.error, isNull);
      expect(repository.lastFetchedProfileId, 99);
    });

    test('fetch failure stores error', () async {
      repository.fetchResult = Failure(
        HttpException(message: 'Unable to fetch profile'),
      );

      await container
          .read(userProfileStateProvider.notifier)
          .fetchProfile(profileId: 100);

      final state = container.read(userProfileStateProvider);

      expect(state.fetching, isFalse);
      expect(state.error, 'Unable to fetch profile');
      expect(repository.lastFetchedProfileId, 100);
    });
  });
}
