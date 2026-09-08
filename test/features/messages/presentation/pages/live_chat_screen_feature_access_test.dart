import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/widgets/feature_access_gate.dart';
import 'package:vcare_admin/features/messages/presentation/pages/live_chat_screen.dart';
import 'package:vcare_admin/features/messages/presentation/widgets/health_messenger_chat_body.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

import '../../../../fixtures/repositories/fake_feature_access_repository.dart';

Widget _wrap({
  required FeatureAccess access,
  bool openNewChat = false,
  String? peerUserId,
}) {
  return ProviderScope(
    overrides: [fakeFeatureAccessRepositoryOverride(access)],
    child: MaterialApp(
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LiveChatScreen(
        openNewChat: openNewChat,
        peerUserId: peerUserId,
      ),
    ),
  );
}

Future<void> _loadFeatureAccess(WidgetTester tester) async {
  final element = tester.element(find.byType(LiveChatScreen));
  final container = ProviderScope.containerOf(element);
  await container
      .read(featureAccessStateProvider.notifier)
      .refreshFromApi();
}

void main() {
  group('Live chat feature access', () {
    testWidgets('shows permission edge case when health chat is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          access: const FeatureAccess(
            caseManagement: true,
            healthChat: false,
            membership: true,
          ),
          openNewChat: true,
          peerUserId: 'peer-1',
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FeatureAccessDeniedPanel), findsOneWidget);
      expect(
        find.text('You do not have permission to manage messages.'),
        findsOneWidget,
      );
      expect(find.byType(HealthMessengerChatBody), findsNothing);
    });

    testWidgets('shows retry when settings fail to load', (tester) async {
      final repository = FakeFeatureAccessRepository(
        FeatureAccess.disabled,
      )..nextResult = Failure(
          HttpException(message: 'Settings unavailable'),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featureAccessRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [VCareThemeExtension.light]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LiveChatScreen(),
          ),
        ),
      );
      await _loadFeatureAccess(tester);
      await tester.pumpAndSettle();

      expect(find.byType(VcareErrorStatePanel), findsOneWidget);
      expect(find.byType(HealthMessengerChatBody), findsNothing);
    });
  });
}
