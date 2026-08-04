import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_team_empty_state.dart';
import 'package:vcare_admin/features/care_team/presentation/widgets/care_team_list_panel.dart';
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
    final listedTeam = careTeamState.listedTeam;
    final agentTeam = careTeamState.agentTeam;
    final isEmpty = listedTeam.isEmpty && agentTeam.isEmpty;
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
                action: !isEmpty
                    ? VcareHeaderActionButton(
                        label: 'Add contact',
                        onPressed: () =>
                            context.pushNamed(AppRouter.careTeamNewName),
                      )
                    : null,
              ),
            ),
          ),
          if (careTeamState.fetching && isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (careTeamState.hasError && isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load care team',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        careTeamState.error ?? 'Unable to load care team.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(careTeamStateProvider.notifier)
                            .refresh(),
                        style: FilledButton.styleFrom(
                          backgroundColor: VCareColors.primary,
                        ),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: context.mobileShellScrollPadding,
                child: const Center(child: CareTeamEmptyState()),
              ),
            )
          else
            SliverPadding(
              padding: context.mobileShellScrollPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (listedTeam.isNotEmpty)
                    CareTeamListPanel(
                      team: listedTeam,
                      title: 'Care team',
                    ),
                  if (agentTeam.isNotEmpty) ...[
                    if (listedTeam.isNotEmpty) const SizedBox(height: 24),
                    CareTeamListPanel(
                      team: agentTeam,
                      title: 'My team',
                      showManage: true,
                    ),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
