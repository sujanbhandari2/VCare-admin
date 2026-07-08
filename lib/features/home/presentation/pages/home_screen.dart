import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_profile_mapper.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/home/data/home_saved_providers_builder.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_stats_state_provider.dart';
import 'package:vcare_admin/features/home/utils/home_stats_utils.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_membership_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_metrics_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_page_header.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_recent_activity_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_providers_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_transaction_receipt_sheet.dart';
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
  late HomeViewData _data;
  bool _previewNoMembership = false;

  @override
  void initState() {
    super.initState();
    _data = _buildViewData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationInboxStateProvider.notifier).fetchInbox();
      if (ref.read(userLoggedInStateProvider)) {
        await Future.wait([
          ref.read(authMeStateProvider.notifier).fetchMe(),
          ref.read(agentStatsStateProvider.notifier).fetchStats(),
          ref.read(savedProvidersStateProvider.notifier).fetchSavedProviders(),
        ]);
      }
      if (mounted) {
        ref.read(networkFetchSessionProvider.notifier).markSessionHydrated();
      }
    });
  }

  HomeViewData _buildViewData() {
    final base = HomeMockData.defaultView();
    final recent = defaultRecentActivity();
    return base.copyWith(recentActivity: recent);
  }

  bool get _hasMembership =>
      !_previewNoMembership && _data.member.memberId.isNotEmpty;

  List<SavedProviderItem> get _savedProviders {
    return buildHomeSavedProviders(
      savedProviders: ref.watch(savedProvidersStateProvider).providers,
    );
  }

  Future<void> _removeFavorite(SavedProviderItem item) async {
    final npi = item.medicareNpi;
    if (npi == null) return;

    final removed = await ref
        .read(savedProvidersStateProvider.notifier)
        .removeByNpi(npi);
    if (!mounted || !removed) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Provider removed: ${item.name}')),
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

  void _handleActivityTap(ActivityItem item) {
    if (item.kind == ActivityKind.transaction && item.transaction != null) {
      showHomeTransactionReceiptSheet(context, item.transaction!);
      return;
    }

    if (item.kind == ActivityKind.request) {
      context.pushNamed(
        AppRouter.requestDetailName,
        pathParameters: {'id': item.id},
      );
      return;
    }

    if (item.kind == ActivityKind.message && item.contactId != null) {
      context.pushNamed(
        AppRouter.careTeamDetailName,
        pathParameters: {'id': item.contactId!},
      );
      return;
    }

    context.pushNamed(AppRouter.messages.toPathName);
  }

  Future<void> _onRefresh() async {
    final futures = <Future<void>>[
      ref.read(notificationInboxStateProvider.notifier).refresh(),
    ];

    if (ref.read(userLoggedInStateProvider)) {
      futures.add(
        ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true),
      );
      futures.add(
        ref
            .read(agentStatsStateProvider.notifier)
            .fetchStats(forceRefresh: true),
      );
      futures.add(
        ref
            .read(savedProvidersStateProvider.notifier)
            .fetchSavedProviders(forceRefresh: true),
      );
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() => _data = _buildViewData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(localProfileStateProvider);
    final authMeState = ref.watch(authMeStateProvider);
    final inboxState = ref.watch(notificationInboxStateProvider);
    final agentStatsState = ref.watch(agentStatsStateProvider);
    final agentStats = agentStatsState.data;
    final hasCommission = agentStats?.hasCommission ?? false;
    final totalClients = agentStats == null
        ? '—'
        : formatAgentStatCount(agentStats.totalClients);
    final totalCommission = agentStats == null
        ? '—'
        : formatAgentStatMoney(agentStats.totalCommission);
    final totalSales = agentStats == null
        ? '—'
        : formatAgentStatMoney(agentStats.totalSales);
    final headerProfile = homeProfileFromLocal(profile);
    final greetingLabel = authMeState.firstName?.trim().isNotEmpty == true
        ? 'Welcome back, ${authMeState.firstName!.trim()}'
        : 'Welcome back';
    final membershipMember = homeMemberFromProfile(profile);
    final carouselSaved = _savedProviders
        .take(homeSavedProvidersCarouselLimit)
        .toList();

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
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                safeTop: safeTop,
                profile: headerProfile,
                greetingLabel: greetingLabel,
                unreadCount: inboxState.unreadCount,
                onProfileTap: () =>
                    context.pushNamed(AppRouter.profile.toPathName),
                onNotificationsTap: () async {
                  await context.pushNamed(AppRouter.notificationsName);
                  if (mounted) {
                    ref.read(notificationInboxStateProvider.notifier).refresh();
                  }
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HomeMembershipSection(
                    member: membershipMember,
                    hasMembership: _hasMembership,
                    previewNoMembership: _previewNoMembership,
                    onTap: () => context.pushNamed(AppRouter.idCardName),
                    onPreviewToggle: kDebugMode
                        ? () => setState(
                            () => _previewNoMembership = !_previewNoMembership,
                          )
                        : null,
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeMetricsSection(
                    hasCommission: hasCommission,
                    totalClients: totalClients,
                    totalCommission: totalCommission,
                    totalSales: totalSales,
                    onTotalClientsTap: () =>
                        context.goNamed(AppRouter.clientsName),
                    onTotalCommissionTap: () =>
                        context.pushNamed(AppRouter.commissionsName),
                    onTotalSalesTap: () =>
                        context.pushNamed(AppRouter.commissionsName),
                  ),
                  const SizedBox(height: _sectionGap),
                  HomeRecentActivitySection(
                    items: _data.recentActivity,
                    onSeeAll: () => context.pushNamed(AppRouter.activityName),
                    onItemTap: _handleActivityTap,
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
                  ),
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
