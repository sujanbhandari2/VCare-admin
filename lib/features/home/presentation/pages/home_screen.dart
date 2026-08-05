import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_profile_mapper.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/home/data/home_saved_providers_builder.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/home/utils/home_stats_utils.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_care_team_carousel.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_guides_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_membership_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_metrics_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_page_header.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_recent_activity_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_providers_section.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_w9_form_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:go_router/go_router.dart';

/// Section spacing from vcareapp `HomeDashboardBody` (`space-y-6`).
const _sectionGap = 24.0;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // TODO: Re-enable when notifications API is available.
      // await ref.read(notificationInboxStateProvider.notifier).fetchInbox();
      if (!mounted) return;
      if (ref.read(userLoggedInStateProvider)) {
        await Future.wait([
          ref.read(authMeStateProvider.notifier).fetchMe(),
          ref.read(agentStatsStateProvider.notifier).fetchStats(),
          ref.read(savedProvidersStateProvider.notifier).fetchSavedProviders(),
          ref.read(careTeamStateProvider.notifier).fetchCareTeam(),
          ref.read(todoListStateProvider.notifier).loadInitial(),
        ]);
      }
      if (mounted) {
        ref.read(networkFetchSessionProvider.notifier).markSessionHydrated();
      }
    });
  }

  bool _hasReferral(LocalProfile profile) =>
      profile.fullName.isNotEmpty && profile.email.isNotEmpty;

  Future<void> _removeFavorite(SavedProviderItem item) async {
    final npi = item.medicareNpi;
    if (npi == null) return;

    final removed = await ref
        .read(savedProvidersStateProvider.notifier)
        .removeByNpi(npi);
    if (!mounted || !removed) return;

    context.showVcareToast(
      title: 'Provider removed',
      description: item.name,
      variant: VcareToastVariant.info,
    );
  }

  void _openSavedProvider(SavedProviderItem item) {
    final npi = item.medicareNpi;
    if (npi == null) return;
    context.pushNamed(
      AppRouter.medicareProviderDetailName,
      pathParameters: {'npi': npi},
    );
  }

  Future<void> _handleTodoTap(TodoItem item) async {
    if (item.type == TodoType.paymentFailed) {
      await TodoTransactionDetailSheet.show(context, item: item);
      return;
    }
    if (item.type == TodoType.w9FormMissing) {
      await TodoW9FormSheet.show(context, item: item);
      return;
    }
    if (item.type == TodoType.completeProfile) {
      await context.pushNamed(
        AppRouter.profileEditName,
        queryParameters: const {'tab': 'story'},
      );
      if (!mounted) {
        return;
      }
      await ref.read(todoListStateProvider.notifier).refresh();
    }
  }

  Future<void> _onRefresh() async {
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
        ref.read(careTeamStateProvider.notifier).refresh(),
        ref.read(todoListStateProvider.notifier).refresh(),
      ]);
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(localProfileStateProvider);
    final authMeState = ref.watch(authMeStateProvider);
    final inboxState = ref.watch(notificationInboxStateProvider);
    final agentStatsState = ref.watch(agentStatsStateProvider);
    final agentStats = agentStatsState.data;
    // Match web HomeMetricsSection: stats.isAgencyAssociated || profile.agencyGroup.
    final isAgencyTied =
        (agentStats?.isAgencyAssociated ?? false) || profile.hasAgencyGroup;
    final totalClients = agentStats == null
        ? '—'
        : formatAgentStatCount(agentStats.totalClients);
    final totalCommission = agentStats == null
        ? '—'
        : formatAgentStatMoney(agentStats.totalCommission);
    final totalSales = agentStats == null
        ? '—'
        : formatAgentStatMoney(agentStats.totalSales);
    final headerProfile = homeProfileFromLocal(
      profile,
      authMe: authMeState.data,
    );
    final greetingLabel = authMeState.firstName?.trim().isNotEmpty == true
        ? 'Welcome back, ${authMeState.firstName!.trim()}'
        : 'Welcome back';
    final membershipMember = homeMemberFromProfile(profile);
    final careTeam = ref.watch(careTeamStateProvider).members;
    final savedProvidersState = ref.watch(savedProvidersStateProvider);
    final carouselSaved = buildHomeSavedProviders(
      savedProviders: savedProvidersState.providers,
    ).take(homeSavedProvidersCarouselLimit).toList();
    final todoListState = ref.watch(todoListStateProvider);

    final safeTop = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: VcareRefreshScrollView(
          onRefresh: _onRefresh,
          padForMobileBottomNav: true,
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                safeTop: safeTop,
                profile: headerProfile,
                greetingLabel: greetingLabel,
                unreadCount: inboxState.unreadCount,
                onProfileTap: () => context.go(AppRouter.profile),
                onNotificationsTap: () async {
                  await context.pushNamed(AppRouter.notificationsName);
                  // TODO: Re-enable when notifications API is available.
                  // if (mounted) {
                  //   ref.read(notificationInboxStateProvider.notifier).refresh();
                  // }
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HomeMembershipSection(
                    member: membershipMember,
                    hasMembership: _hasReferral(profile),
                    onTap: () => context.pushNamed(AppRouter.idCardName),
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeMetricsSection(
                    isAgencyTied: isAgencyTied,
                    totalClients: totalClients,
                    totalCommission: totalCommission,
                    totalSales: totalSales,
                    onTotalClientsTap: () =>
                        context.goNamed(AppRouter.clientsName),
                    onSalesOrCommissionTap: () =>
                        context.pushNamed(AppRouter.homeSalesName),
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeRecentActivitySection(
                    items: todoListState.items,
                    isLoading: todoListState.isInitialLoading,
                    isError: todoListState.isInitialError,
                    errorMessage: todoListState.operation.errorMessage,
                    onRetry: () =>
                        ref.read(todoListStateProvider.notifier).loadInitial(),
                    onSeeAll: () => context.pushNamed(AppRouter.activityName),
                    onItemTap: _handleTodoTap,
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeCareTeamCarousel(
                    careTeam: careTeam,
                    onSeeAll: () => context.pushNamed(AppRouter.careTeamName),
                    onAdd: () => context.pushNamed(AppRouter.careTeamNewName),
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeSavedProvidersSection(
                    providers: carouselSaved,
                    onSeeAll: () =>
                        context.pushNamed(AppRouter.savedProvidersName),
                    onFindCare: () =>
                        context.pushNamed(AppRouter.findCare.toPathName),
                    onProviderTap: _openSavedProvider,
                    onRemove: _removeFavorite,
                    isRemoving: (item) {
                      final npi = item.medicareNpi;
                      if (npi == null) return false;
                      return savedProvidersState.isToggling(npi);
                    },
                  ),
                  const SizedBox(height: _sectionGap),
                  const HomeGuidesSection(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.safeTop,
    required this.profile,
    required this.greetingLabel,
    required this.unreadCount,
    this.onProfileTap,
    this.onNotificationsTap,
  });

  static const double _compactHeight = 56;
  static const double _expandedHeight = 88;

  final double safeTop;
  final HomeProfile profile;
  final String greetingLabel;
  final int unreadCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;

  @override
  double get minExtent => safeTop + _compactHeight;

  @override
  double get maxExtent => safeTop + _expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final compact = shrinkOffset > 12;
    final extent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final contentHeight = extent - safeTop;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      child: SizedBox(
        height: extent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: safeTop),
            SizedBox(
              height: contentHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: HomePageHeader(
                    profile: profile,
                    greetingLabel: greetingLabel,
                    unreadCount: unreadCount,
                    compact: compact,
                    onProfileTap: onProfileTap,
                    onNotificationsTap: onNotificationsTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return safeTop != oldDelegate.safeTop ||
        profile != oldDelegate.profile ||
        greetingLabel != oldDelegate.greetingLabel ||
        unreadCount != oldDelegate.unreadCount ||
        onProfileTap != oldDelegate.onProfileTap ||
        onNotificationsTap != oldDelegate.onNotificationsTap;
  }
}
