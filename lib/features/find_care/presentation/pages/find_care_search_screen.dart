import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/utils/find_care_current_location_flow.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/find_care_location_bar.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/medicare_provider_result_card.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class FindCareSearchScreen extends ConsumerStatefulWidget {
  const FindCareSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<FindCareSearchScreen> createState() =>
      _FindCareSearchScreenState();
}

class _FindCareSearchScreenState extends ConsumerState<FindCareSearchScreen> {
  late final TextEditingController _queryController;
  late final TextEditingController _locationController;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery ?? '');
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _clearCurrentLocation() async {
    await ref
        .read(findCareSearchLocationProvider.notifier)
        .useProfileLocation();
  }

  Future<void> _runSearch({bool loadMore = false}) async {
    if (!loadMore) {
      await ref
          .read(findCareSearchLocationProvider.notifier)
          .setFromDisplayText(_locationController.text);
    }
    final notifier = ref.read(findCareSearchStateProvider.notifier);
    notifier.setProviderQuery(_queryController.text);
    final success = await notifier.runSearch(loadMore: loadMore);
    if (!mounted || loadMore) return;
    if (!success && _queryController.text.trim().isEmpty) {
      context.showVcareToast(
        title: 'Enter a name',
        description: 'Last name or full name, e.g. Jane Doe.',
        variant: VcareToastVariant.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final location = ref.watch(findCareSearchLocationProvider);
    final detecting = ref.watch(
      findCareCurrentLocationStateProvider.select((s) => s.detecting),
    );
    final searchState = ref.watch(findCareSearchStateProvider);

    if (!_initialized) {
      _initialized = true;
      _locationController.text = location.displayLabel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(findCareSearchStateProvider.notifier)
            .initializeFromQuery(widget.initialQuery);
        if (widget.initialQuery != null &&
            widget.initialQuery!.trim().isNotEmpty) {
          _runSearch();
        }
      });
    } else if (_locationController.text != location.displayLabel) {
      _locationController.text = location.displayLabel;
    }

    final stateLabel = location.state.trim();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'Search Providers',
              subtitle: searchState.submitted.isEmpty
                  ? 'CMS Medicare directory'
                  : 'Results for "${searchState.submitted}"',
              showBack: true,
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FindCareLocationBar(
                  locationController: _locationController,
                  isDetecting: detecting,
                  isUsingCurrentLocation: location.fromCurrentLocation,
                  onDetectLocation: () {
                    runFindCareCurrentLocationFlow(
                      context,
                      ref,
                      userInitiated: true,
                    );
                  },
                  onClearCurrentLocation: _clearCurrentLocation,
                  actions: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NameSearchField(
                        controller: _queryController,
                        onSubmitted: () => _runSearch(),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: searchState.loading
                            ? null
                            : () => _runSearch(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: searchState.loading && !searchState.loadingMore
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VCareColors.primaryForeground,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Searching…'),
                                ],
                              )
                            : const Text('Search providers'),
                      ),
                    ],
                  ),
                ),
                if (searchState.error != null && !searchState.loading) ...[
                  const SizedBox(height: 12),
                  VcareInlineErrorCard(message: searchState.error),
                ],
                if (searchState.loading &&
                    searchState.items.isEmpty &&
                    searchState.submitted.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _ResultsSkeleton(),
                ],
                if (!searchState.loading &&
                    searchState.error == null &&
                    searchState.submitted.isNotEmpty &&
                    searchState.items.isEmpty) ...[
                  const SizedBox(height: 12),
                  _EmptyResults(
                    submitted: searchState.submitted,
                    stateLabel: stateLabel,
                  ),
                ],
                if (searchState.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final item in searchState.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedicareProviderResultCardWithFavorite(item: item),
                    ),
                ],
                if (searchState.hasMore && searchState.items.isNotEmpty) ...[
                  OutlinedButton(
                    onPressed: searchState.loadingMore
                        ? null
                        : () => _runSearch(loadMore: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      searchState.loadingMore ? 'Loading…' : 'Load more',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.goNamed(AppRouter.findCare.toPathName),
                  child: Text(
                    '← Back to Find Care',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameSearchField extends StatelessWidget {
  const _NameSearchField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 16, color: vcare.mutedForeground),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmitted(),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search by provider name, NPI, Service name',
                  hintStyle: TextStyle(color: vcare.mutedForeground),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.submitted, required this.stateLabel});

  final String submitted;
  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final locationPart = stateLabel.isNotEmpty ? ' in $stateLabel' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 32, color: vcare.mutedForeground),
          const SizedBox(height: 8),
          const Text(
            'No providers found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'We couldn\'t find any providers in the CMS Medicare directory for '
            '"$submitted"$locationPart. Try a different name, NPI, or service.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: vcare.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
