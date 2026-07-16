import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
// import 'package:vcare_admin/features/ava/presentation/providers/ava_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';
// import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';

/// Refreshes tab-scoped data whenever a bottom-nav tab is selected.
Future<void> refreshTabData(WidgetRef ref, NavItem tab) async {
  switch (tab) {
    case NavItem.clients:
      await ref.read(clientsListStateProvider.notifier).refresh();
    case NavItem.provider:
      if (ref.read(userLoggedInStateProvider)) {
        await ref
            .read(savedProvidersStateProvider.notifier)
            .fetchSavedProviders(forceRefresh: true);
      }
    case NavItem.home:
      final futures = <Future<void>>[
        // TODO: Re-enable when notifications API is available.
        // ref.read(notificationInboxStateProvider.notifier).refresh(),
      ];

      if (ref.read(userLoggedInStateProvider)) {
        futures.addAll([
          ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true),
          ref
              .read(agentStatsStateProvider.notifier)
              .fetchStats(forceRefresh: true),
          ref
              .read(savedProvidersStateProvider.notifier)
              .fetchSavedProviders(forceRefresh: true),
        ]);
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    case NavItem.messages:
      break;
    case NavItem.profile:
      if (ref.read(userLoggedInStateProvider)) {
        await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
      }
    // case NavItem.ava:
    //   await ref.read(avaStateProvider.notifier).refreshMessages();
  }
}
