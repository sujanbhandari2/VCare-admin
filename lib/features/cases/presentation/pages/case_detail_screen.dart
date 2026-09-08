import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_files_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_other_cases_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_tasks_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_clone_sheet.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_detail_header.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_detail_tab_bar.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_files_tab.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_info_sheet.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_notes_live_sync.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_notes_tab.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_tasks_tab.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Case detail — NestedScrollView + Notes / Files / Tasks tabs.
class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRefresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final caseId = widget.caseId;
    await Future.wait([
      ref.read(caseDetailStateProvider(caseId).notifier).fetchDetail(),
      ref.read(caseNotesStateProvider(caseId).notifier).fetchNotes(),
      ref.read(caseFilesStateProvider(caseId).notifier).fetchFiles(),
      ref.read(caseTasksStateProvider(caseId).notifier).fetchTasks(),
      ref.read(caseOtherCasesStateProvider(caseId).notifier).refresh(),
    ]);
  }

  Future<void> _toggleBookmark() async {
    await ref
        .read(caseDetailStateProvider(widget.caseId).notifier)
        .toggleBookmark(
          onCompleted: (success, error) {
            if (!mounted) return;
            if (!success) {
              context.showVcareToast(
                title: error ?? 'Unable to update bookmark',
                variant: VcareToastVariant.destructive,
              );
            }
          },
        );
  }

  Future<void> _cloneCase() async {
    await CaseCloneSheet.show(
      context,
      onConfirm: () async {
        ReferralCase? cloned;
        String? error;
        await ref
            .read(caseDetailStateProvider(widget.caseId).notifier)
            .cloneCase(
              onCompleted: (result, err) {
                cloned = result;
                error = err;
              },
            );
        if (!mounted) return;

        if (error != null || cloned == null) {
          context.showVcareToast(
            title: error ?? 'Clone failed',
            variant: VcareToastVariant.destructive,
          );
          throw StateError(error ?? 'Clone failed');
        }

        context.showVcareToast(
          title: 'Case cloned',
          variant: VcareToastVariant.success,
        );
        context.pushReplacementNamed(
          AppRouter.caseDetailName,
          pathParameters: {'id': cloned!.id},
        );
      },
    );
  }

  Widget _buildActions(ReferralCase detail) {
    final vcare = context.vcare;

    return IconButton(
      onPressed: () => CaseInfoSheet.show(
        context,
        caseData: detail,
        caseId: widget.caseId,
        onClone: _cloneCase,
        onToggleBookmark: _toggleBookmark,
      ),
      icon: const Icon(LucideIcons.info, size: 16),
      tooltip: 'Case info',
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        maximumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        foregroundColor: vcare.mutedForeground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CaseNotesLiveSync(caseId: widget.caseId, child: _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    final caseId = widget.caseId;
    final detailState = ref.watch(caseDetailStateProvider(caseId));
    final notesState = ref.watch(caseNotesStateProvider(caseId));
    final filesState = ref.watch(caseFilesStateProvider(caseId));
    final tasksState = ref.watch(caseTasksStateProvider(caseId));
    final detail = detailState.data;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    if (detailState.isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (detail == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: VcarePinnedPageTitleDelegate(
                safeTop: safeTop,
                textScaleFactor: textScaleFactor,
                hasSubtitle: false,
                title: vcareTabPageTitle(
                  title: 'Case not found',
                  showBack: true,
                  onBack: () => context.go(AppRouter.cases),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: VcareErrorStatePanel(
                title: 'Case not found',
                message: detailState.error,
                actionLabel: 'Back to cases',
                onAction: () => context.go(AppRouter.cases),
              ),
            ),
          ],
        ),
      );
    }

    final titleLabel = resolveCaseTypeLabel(detail.caseType);
    final title = titleLabel.isEmpty ? 'Case' : titleLabel;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: NestedScrollView(
          physics: VcareRefreshScrollView.physics,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverPersistentHeader(
              pinned: true,
              delegate: VcarePinnedPageTitleDelegate(
                safeTop: safeTop,
                textScaleFactor: textScaleFactor,
                hasSubtitle: false,
                title: vcareTabPageTitle(
                  title: title,
                  showBack: true,
                  onBack: () => context.go(AppRouter.cases),
                  action: _buildActions(detail),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CaseDetailHeader(caseId: caseId, caseData: detail),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: CaseDetailTabBarHeader(
                tabBar: CaseDetailTabBar(
                  controller: _tabController,
                  notesCount: notesState.notes.length,
                  filesCount: filesState.files.length,
                  tasksCount: tasksState.tasks.length,
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              CaseNotesTab(
                caseId: caseId,
                clonedFromCaseId: detail.clonedFromCaseId,
              ),
              CaseFilesTab(caseId: caseId, clientId: detail.clientId),
              CaseTasksTab(caseId: caseId, clientId: detail.clientId),
            ],
          ),
        ),
      ),
    );
  }
}
