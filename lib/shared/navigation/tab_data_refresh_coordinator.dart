import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
// import 'package:vcare_admin/features/ava/presentation/providers/ava_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/cases_list_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
// Sales tab refresh — restore with NavItem.sales.
// import 'package:vcare_admin/features/commission/presentation/providers/commission_history_state_provider.dart';
// import 'package:vcare_admin/features/commission/presentation/providers/commission_sales_history_state_provider.dart';
// import 'package:vcare_admin/features/commission/presentation/providers/commission_summary_state_provider.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';
// import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';

/// Refreshes tab-scoped data whenever a bottom-nav tab is selected.
Future<void> refreshTabData(WidgetRef ref, NavItem tab) async {
  switch (tab) {
    case NavItem.clients:
      await ref.read(clientsListStateProvider.notifier).refresh();
    case NavItem.cases:
      await ref.read(casesListStateProvider.notifier).refresh();
    // Providers tab replaced by Cases.
    // case NavItem.provider:
    //   if (ref.read(userLoggedInStateProvider)) {
    //     await ref
    //         .read(savedProvidersStateProvider.notifier)
    //         .fetchSavedProviders(forceRefresh: true);
    //   }
    // case NavItem.sales:
    //   final agencyGroupId = ref
    //       .read(localProfileStateProvider)
    //       .agencyGroupId
    //       ?.trim();
    //   final usesSalesHistory =
    //       agencyGroupId != null && agencyGroupId.isNotEmpty;
    //   await Future.wait([
    //     ref.read(commissionSummaryStateProvider.notifier).fetchSummary(),
    //     if (usesSalesHistory)
    //       ref.read(commissionSalesHistoryStateProvider.notifier).refresh()
    //     else
    //       ref.read(commissionHistoryStateProvider.notifier).refresh(),
    //   ]);
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
          ref.read(todoListStateProvider.notifier).refresh(),
        ]);
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    case NavItem.messages:
      break;
    case NavItem.profile:
      if (ref.read(userLoggedInStateProvider)) {
        await ref
            .read(authMeStateProvider.notifier)
            .fetchMe(forceRefresh: true);
      }
    // case NavItem.ava:
    //   await ref.read(avaStateProvider.notifier).refreshMessages();
  }
}
