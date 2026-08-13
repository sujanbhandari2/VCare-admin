import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_failed_payments_card.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_stat_cards.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_todo_card.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_profile_mapper.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_page_header.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

/// Section spacing from admin web `Dashboard.tsx` (`space-y-6`).
const _sectionGap = 24.0;
const _pageHorizontalPadding = 20.0;

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
      if (!mounted) return;

      final isAuthenticated =
          ref.read(adminAuthSessionProvider).isAuthenticated;
      if (isAuthenticated) {
        await Future.wait([
          ref.read(authMeStateProvider.notifier).fetchMe(),
          ref.read(adminDashboardStateProvider.notifier).load(),
        ]);
      }

      if (mounted) {
        ref.read(networkFetchSessionProvider.notifier).markSessionHydrated();
      }
    });
  }

  Future<void> _onRefresh() async {
    final isAuthenticated =
        ref.read(adminAuthSessionProvider).isAuthenticated;
    if (!isAuthenticated) return;

    await Future.wait([
      ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true),
      ref.read(adminDashboardStateProvider.notifier).load(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authMeState = ref.watch(authMeStateProvider);
    final inboxState = ref.watch(notificationInboxStateProvider);
    final dashboardState = ref.watch(adminDashboardStateProvider);

    final headerProfile = homeProfileFromLocal(
      ref.watch(localProfileStateProvider),
      authMe: authMeState.data,
    );

    const greetingLabel = 'Welcome back';

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
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _pageHorizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    "Here's what's happening with your clients today.",
                    style: TextStyle(
                      fontSize: 14,
                      color: context.vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: _sectionGap),
                  AdminDashboardStatCards(state: dashboardState),
                  const SizedBox(height: _sectionGap),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide =
                          constraints.maxWidth >=
                          VCareLayout.mobileBreakpoint;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AdminDashboardFailedPaymentsCard(
                                state: dashboardState,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AdminDashboardTodoCard(
                                state: dashboardState,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          AdminDashboardFailedPaymentsCard(
                            state: dashboardState,
                          ),
                          const SizedBox(height: 20),
                          AdminDashboardTodoCard(state: dashboardState),
                        ],
                      );
                    },
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
