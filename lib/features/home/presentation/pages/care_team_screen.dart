import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/home/presentation/widgets/care_team_empty_state.dart';
import 'package:vcare_admin/features/home/presentation/widgets/care_team_member_card.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

class CareTeamScreen extends ConsumerStatefulWidget {
  const CareTeamScreen({super.key});

  @override
  ConsumerState<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends ConsumerState<CareTeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(userLoggedInStateProvider)) return;
      if (ref.read(careTeamStateProvider).members.isNotEmpty) return;
      ref.read(careTeamStateProvider.notifier).fetchCareTeam();
    });
  }

  @override
  Widget build(BuildContext context) {
    final careTeamState = ref.watch(careTeamStateProvider);
    final team = careTeamState.members;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: () => ref.read(careTeamStateProvider.notifier).refresh(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: true,
              title: vcareTabPageTitle(
                title: 'Care Team',
                subtitle: 'Your people, one tap away.',
                showBack: true,
                action: VcareHeaderActionButton(
                  label: 'Add contact',
                  onPressed: () =>
                      context.pushNamed(AppRouter.careTeamNewName),
                ),
              ),
            ),
          ),
          if (careTeamState.fetching && team.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (careTeamState.hasError && team.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    careTeamState.error ?? 'Unable to load care team.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: context.mobileShellScrollPadding,
              sliver: team.isEmpty
                  ? const SliverToBoxAdapter(child: CareTeamEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CareTeamMemberCard(member: team[index]),
                        ),
                        childCount: team.length,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
