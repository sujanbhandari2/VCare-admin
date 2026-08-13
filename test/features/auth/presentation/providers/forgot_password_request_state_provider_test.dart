import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/forgot_password_request_state_provider.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../fixtures/repository_fixtures.dart';

void main() {
  group('ForgotPasswordRequestStateNotifier', () {
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

    test('forgotPassword sends identifier to repository', () async {
      ForgotPasswordResult? completed;

      await container
          .read(forgotPasswordRequestStateProvider.notifier)
          .forgotPassword(
            identifier: 'user@example.com',
            onCompleted: (result) => completed = result,
          );

      expect(repository.lastForgotPasswordIdentifier, 'user@example.com');
      expect(completed?.requiresDisambiguation, isFalse);
    });

    test('forgotPassword disambiguation passes accountId', () async {
      repository.forgotPasswordResult = Success(
        const ForgotPasswordResult(
          accounts: [
            ForgotPasswordAccount(
              accountId: 'acc-1',
              displayName: 'Jane Doe',
            ),
          ],
        ),
      );

      ForgotPasswordResult? completed;

      await container
          .read(forgotPasswordRequestStateProvider.notifier)
          .forgotPassword(
            identifier: 'user@example.com',
            accountId: 'acc-1',
            onCompleted: (result) => completed = result,
          );

      expect(repository.lastForgotPasswordAccountId, 'acc-1');
      expect(completed?.requiresDisambiguation, isTrue);
    });

    test('forgotPassword dob path passes dob and zipCode', () async {
      await container
          .read(forgotPasswordRequestStateProvider.notifier)
          .forgotPassword(
            identifier: '5551234567',
            dob: '1990-01-15',
            zipCode: '12345',
          );

      expect(repository.lastForgotPasswordDob, '1990-01-15');
      expect(repository.lastForgotPasswordZipCode, '12345');
    });
  });
}
