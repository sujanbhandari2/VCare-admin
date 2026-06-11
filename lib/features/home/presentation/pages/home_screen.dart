import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/cms_provider_favorites_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/provider_favorites_provider.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_profile_mapper.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/home/data/home_saved_providers_builder.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_membership_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_metrics_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_page_header.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_recent_activity_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_providers_section.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_transaction_receipt_sheet.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_inbox_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
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
  bool _previewEmptySaved = false;
  bool _previewNoMembership = false;

  @override
  void initState() {
    super.initState();
    _data = _buildViewData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationInboxStateProvider.notifier).fetchInbox();
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
    if (_previewEmptySaved) return [];
    return buildHomeSavedProviders(
      mockFavoriteIds: ref.watch(providerFavoritesProvider),
      cmsFavorites: ref.watch(cmsProviderFavoritesProvider),
    );
  }

  void _removeFavorite(SavedProviderItem item) {
    if (item.kind == HomeSavedProviderKind.cms) {
      final npi = item.medicareNpi;
      if (npi == null) return;
      ref.read(cmsProviderFavoritesProvider.notifier).remove(npi);
    } else {
      final id = item.providerId ?? item.key.replaceFirst('m-', '');
      ref.read(providerFavoritesProvider.notifier).toggle(id);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Provider removed: ${item.name}'),
          action: item.kind == HomeSavedProviderKind.mock
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    final id =
                        item.providerId ?? item.key.replaceFirst('m-', '');
                    ref.read(providerFavoritesProvider.notifier).toggle(id);
                  },
                )
              : null,
        ),
      );
  }

  void _openSavedProvider(SavedProviderItem item) {
    if (item.kind == HomeSavedProviderKind.cms) {
      final npi = item.medicareNpi;
      if (npi == null) return;
      context.pushNamed(
        AppRouter.medicareProviderDetailName,
        pathParameters: {'npi': npi},
      );
      return;
    }

    final id = item.providerId ?? item.key.replaceFirst('m-', '');
    context.pushNamed(AppRouter.providerDetailName, pathParameters: {'id': id});
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(localProfileStateProvider);
    final inboxState = ref.watch(notificationInboxStateProvider);
    final headerProfile = homeProfileFromLocal(profile);
    final membershipMember = homeMemberFromProfile(profile);
    final carouselSaved = _savedProviders
        .take(homeSavedProvidersCarouselLimit)
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                profile: headerProfile,
                unreadCount: inboxState.unreadCount,
                onProfileTap: () =>
                    context.pushNamed(AppRouter.profile.toPathName),
                onNotificationsTap: () async {
                  await context.pushNamed(AppRouter.notificationsName);
                  if (mounted) {
                    ref
                        .read(notificationInboxStateProvider.notifier)
                        .refresh();
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
                    onTotalClientsTap: () =>
                        context.goNamed(AppRouter.clientsName),
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
                    previewEmpty: _previewEmptySaved,
                    onPreviewToggle: kDebugMode
                        ? () => setState(
                            () => _previewEmptySaved = !_previewEmptySaved,
                          )
                        : null,
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
    required this.profile,
    required this.unreadCount,
    this.onProfileTap,
    this.onNotificationsTap,
  });

  final HomeProfile profile;
  final int unreadCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 88;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return HomePageHeader(
      profile: profile,
      unreadCount: unreadCount,
      compact: shrinkOffset > 12,
      onProfileTap: onProfileTap,
      onNotificationsTap: onNotificationsTap,
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return profile != oldDelegate.profile ||
        unreadCount != oldDelegate.unreadCount ||
        onProfileTap != oldDelegate.onProfileTap ||
        onNotificationsTap != oldDelegate.onNotificationsTap;
  }
}
