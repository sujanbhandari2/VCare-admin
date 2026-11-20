import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/presentation/providers/admin_forgot_password_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';

void main() {
  group('AdminForgotPasswordStateNotifier', () {
    late FakeAuthRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('requestReset sends normalized email to repository', () async {
      bool? completed;

      await container
          .read(adminForgotPasswordStateProvider.notifier)
          .requestReset(
            email: ' User@Example.com ',
            onCompleted: (success) => completed = success,
          );

      expect(repository.lastAdminForgotPasswordEmail, 'user@example.com');
      expect(completed, isTrue);
    });
  });
}
