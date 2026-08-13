import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_other_cases_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_status_chip.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Bottom sheet with client card, other cases, and created-by card.
class CaseInfoSheet extends ConsumerStatefulWidget {
  const CaseInfoSheet({
    super.key,
    required this.caseData,
    required this.caseId,
    this.onClone,
    this.onToggleBookmark,
  });

  final ReferralCase caseData;
  final String caseId;
  final Future<void> Function()? onClone;
  final Future<void> Function()? onToggleBookmark;

  static Future<void> show(
    BuildContext context, {
    required ReferralCase caseData,
    required String caseId,
    Future<void> Function()? onClone,
    Future<void> Function()? onToggleBookmark,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CaseInfoSheet(
        caseData: caseData,
        caseId: caseId,
        onClone: onClone,
        onToggleBookmark: onToggleBookmark,
      ),
    );
  }

  @override
  ConsumerState<CaseInfoSheet> createState() => _CaseInfoSheetState();
}

class _CaseInfoSheetState extends ConsumerState<CaseInfoSheet> {
  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;
  bool _requestedClientHydration = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(caseOtherCasesStateProvider(widget.caseId).notifier)
          .loadInitial();
      _ensureClientHydrated();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ReferralCase get _caseData {
    return ref.watch(caseDetailStateProvider(widget.caseId)).data ??
        widget.caseData;
  }

  void _ensureClientHydrated() {
    if (_requestedClientHydration) return;
    final detail = ref.read(caseDetailStateProvider(widget.caseId)).data;
    final current = detail ?? widget.caseData;
    final needsHydration =
        !current.client.hasIdentity ||
        isMissingCreatedByLabel(current.createdBy);
    if (!needsHydration) return;

    _requestedClientHydration = true;
    ref
        .read(caseDetailStateProvider(widget.caseId).notifier)
        .fetchDetail(forceRefresh: true);
  }

  void _onScroll() {
    final state = ref.read(caseOtherCasesStateProvider(widget.caseId));
    final shouldLoadMore =
        state.hasMore &&
        state.items.isNotEmpty &&
        !state.isLoadingMore &&
        state.loadMoreErrorMessage == null &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= 240;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref
          .read(caseOtherCasesStateProvider(widget.caseId).notifier)
          .loadMore()
          .whenComplete(() {
            if (mounted) _isLoadMoreRequested = false;
          });
    }
  }

  Future<void> _openCase(ReferralCase other) async {
    if (!mounted) return;
    context.pop();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    context.pushNamed(
      AppRouter.caseDetailName,
      pathParameters: {'id': other.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final caseData = _caseData;
    final client = caseData.client;
    final otherState = ref.watch(caseOtherCasesStateProvider(widget.caseId));
    final detailState = ref.watch(caseDetailStateProvider(widget.caseId));
    final isBookmarked =
        detailState.data?.isBookmarked ?? widget.caseData.isBookmarked;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hydratingClient =
        detailState.fetching && !client.hasIdentity;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Case info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onClone != null)
                    IconButton(
                      onPressed: detailState.cloning
                          ? null
                          : () async {
                              context.pop();
                              await widget.onClone!();
                            },
                      icon: const Icon(LucideIcons.copyPlus, size: 18),
                      tooltip: 'Clone case',
                      style: IconButton.styleFrom(
                        foregroundColor: vcare.mutedForeground,
                      ),
                    ),
                  if (widget.onToggleBookmark != null)
                    IconButton(
                      onPressed: detailState.bookmarking
                          ? null
                          : () => widget.onToggleBookmark!(),
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : LucideIcons.bookmark,
                        size: 18,
                      ),
                      tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                      style: IconButton.styleFrom(
                        foregroundColor: isBookmarked
                            ? context.vcare.primary
                            : vcare.mutedForeground,
                      ),
                    ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: VcareRefreshScrollView.physics,
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 16),
                children: [
                  _ClientCard(client: client, isLoading: hydratingClient),
                  const SizedBox(height: 12),
                  _OtherCasesCard(
                    state: otherState,
                    onRetry: () => ref
                        .read(
                          caseOtherCasesStateProvider(widget.caseId).notifier,
                        )
                        .loadInitial(),
                    onOpenCase: _openCase,
                  ),
                  const SizedBox(height: 12),
                  _CreatedByCard(
                    name: caseData.createdBy,
                    createdAt: caseData.createdAt,
                    isLoading:
                        detailState.fetching &&
                        isMissingCreatedByLabel(caseData.createdBy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSurfaceCard extends StatelessWidget {
  const _InfoSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, this.isLoading = false});

  final ReferralCaseClient client;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final avatar = client.avatarUrl?.trim() ?? '';
    final phone = client.phone.trim();
    final email = client.email.trim();
    final dob = formatDisplayDateString(client.dateOfBirth);
    final address = client.address?.trim() ?? '';
    final plan = client.membershipPlan?.trim() ?? '';
    final dependentOf = client.dependentOf?.trim() ?? '';
    final displayName = client.displayName;

    return _InfoSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleInitialsAvatar(
                initials: client.initials,
                imageUrl: avatar.isUrl ? avatar : null,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading && !client.hasIdentity)
                      const SizedBox(
                        height: 16,
                        width: 140,
                        child: LinearProgressIndicator(minHeight: 4),
                      )
                    else
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (plan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                    if (dependentOf.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: vcare.muted,
                          borderRadius: VCareRadius.fullAll,
                          border: Border.all(color: vcare.border),
                        ),
                        child: Text(
                          'Dependent of $dependentOf',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: vcare.border),
          ),
          _InfoRow(
            icon: LucideIcons.phone,
            label: phone.isEmpty ? '—' : phone,
            onTap: phone.isEmpty ? null : () => launchUrlString('tel:$phone'),
          ),
          _InfoRow(
            icon: LucideIcons.mail,
            label: email.isEmpty ? '—' : email,
            onTap: email.isEmpty
                ? null
                : () => launchUrlString('mailto:$email'),
          ),
          _InfoRow(
            icon: LucideIcons.calendar,
            label: dob.isEmpty ? '—' : dob,
          ),
          if (address.isNotEmpty)
            _InfoRow(icon: LucideIcons.mapPin, label: address),
        ],
      ),
    );
  }
}

class _OtherCasesCard extends StatelessWidget {
  const _OtherCasesCard({
    required this.state,
    required this.onRetry,
    required this.onOpenCase,
  });

  final LoadableListState<ReferralCase> state;
  final VoidCallback onRetry;
  final Future<void> Function(ReferralCase other) onOpenCase;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return _InfoSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Other Cases',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (state.isInitialLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.isInitialError)
            VcareInlineErrorCard(
              message: state.operation.errorMessage,
              onRetry: onRetry,
            )
          else if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No other cases',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: vcare.mutedForeground,
                ),
              ),
            )
          else ...[
            for (var i = 0; i < state.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _OtherCaseRow(
                caseData: state.items[i],
                onTap: () => onOpenCase(state.items[i]),
              ),
            ],
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ],
      ),
    );
  }
}

class _CreatedByCard extends StatelessWidget {
  const _CreatedByCard({
    required this.name,
    required this.createdAt,
    this.isLoading = false,
  });

  final String name;
  final String createdAt;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayName = isMissingCreatedByLabel(name) ? 'Unknown' : name.trim();
    final dateLabel = createdAt.trim().isEmpty
        ? ''
        : formatDisplayDateString(createdAt);

    return _InfoSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Created By',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              height: 16,
              width: 160,
              child: LinearProgressIndicator(minHeight: 4),
            )
          else
            Row(
              children: [
                _CircleInitialsAvatar(
                  initials: initialsFromDisplayName(displayName),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CircleInitialsAvatar extends StatelessWidget {
  const _CircleInitialsAvatar({
    required this.initials,
    this.imageUrl,
    this.size = 40,
  });

  final String initials;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isUrl
            ? VCareCachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: _InitialsFill(initials: initials, size: size),
              )
            : _InitialsFill(initials: initials, size: size),
      ),
    );
  }
}

class _InitialsFill extends StatelessWidget {
  const _InitialsFill({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.vcare.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size >= 40 ? 16 : 10,
            fontWeight: FontWeight.w700,
            color: context.vcare.primary,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: context.vcare.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

class _OtherCaseRow extends StatelessWidget {
  const _OtherCaseRow({required this.caseData, required this.onTap});

  final ReferralCase caseData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final short = formatCaseIdShort(
      caseData.id.isNotEmpty ? caseData.id : caseData.caseNumber,
    );

    return Material(
      color: vcare.muted.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#$short',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: vcare.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  CaseStatusChip(status: caseData.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                caseData.title.trim().isEmpty
                    ? resolveCaseTypeLabel(caseData.caseType)
                    : caseData.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
