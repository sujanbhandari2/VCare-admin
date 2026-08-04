import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_category_search_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/utils/find_care_current_location_flow.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/find_care_location_bar.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/medicare_provider_result_card.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_category_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class FindCareCategoryScreen extends ConsumerStatefulWidget {
  const FindCareCategoryScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<FindCareCategoryScreen> createState() =>
      _FindCareCategoryScreenState();
}

class _FindCareCategoryScreenState
    extends ConsumerState<FindCareCategoryScreen> {
  final _queryController = TextEditingController();
  late final TextEditingController _locationController;

  ProviderCategoryItem? get _category => findCareCategoryBySlug(widget.slug);

  @override
  void initState() {
    super.initState();
    final location = ref.read(findCareSearchLocationProvider);
    _locationController = TextEditingController(text: location.displayLabel);
  }

  @override
  void didUpdateWidget(FindCareCategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      ref.read(findCareCategorySearchStateProvider.notifier).reset();
      _queryController.clear();
    }
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

  Future<void> _runSearch() async {
    final category = _category;
    if (category == null) return;
    await ref
        .read(findCareSearchLocationProvider.notifier)
        .setFromDisplayText(_locationController.text);
    await ref
        .read(findCareCategorySearchStateProvider.notifier)
        .search(slug: widget.slug, keyword: _queryController.text);
  }

  Future<void> _loadMore() async {
    await ref
        .read(findCareCategorySearchStateProvider.notifier)
        .loadMore(slug: widget.slug, keyword: _queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    final vcare = context.vcare;
    final searchState = ref.watch(findCareCategorySearchStateProvider);
    final location = ref.watch(findCareSearchLocationProvider);
    final detecting = ref.watch(
      findCareCurrentLocationStateProvider.select((s) => s.detecting),
    );
    final stateLabel = location.state.trim().isEmpty ? null : location.state;

    if (_locationController.text != location.displayLabel) {
      _locationController.text = location.displayLabel;
    }

    if (category == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: VcarePageHeader(title: 'Category', showBack: true),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Category not found.',
                  style: TextStyle(color: vcare.mutedForeground),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: category.label,
              subtitle: category.blurb,
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
                      _MedicareNameSearchField(
                        controller: _queryController,
                        categoryLabel: category.label,
                        onSubmitted: _runSearch,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: searchState.loading ? null : _runSearch,
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
                const SizedBox(height: 16),
                if (!searchState.hasSearched)
                  Text(
                    'Tap Search providers to load ${category.label} from the '
                    'CMS Medicare Physician directory (filtered by Medicare '
                    'provider type). Add an optional name to narrow results; '
                    'use Searching near to limit by state.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: vcare.mutedForeground,
                    ),
                  ),
                if (searchState.error != null) ...[
                  const SizedBox(height: 8),
                  VcareInlineErrorCard(message: searchState.error),
                ],
                if (searchState.hasSearched &&
                    !searchState.loading &&
                    searchState.items.isEmpty) ...[
                  const SizedBox(height: 8),
                  _SearchEmptyState(
                    categoryLabel: category.label,
                    stateLabel: stateLabel,
                    keyword: searchState.submittedKeyword,
                  ),
                ],
                if (searchState.hasSearched &&
                    searchState.loading &&
                    searchState.items.isEmpty) ...[
                  const SizedBox(height: 8),
                  const _ResultsSkeleton(),
                ],
                if (searchState.items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final item in searchState.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedicareProviderResultCardWithFavorite(item: item),
                    ),
                ],
                if (searchState.hasSearched && searchState.hasMore) ...[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: searchState.loadingMore ? null : _loadMore,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      searchState.loadingMore ? 'Loading…' : 'Load more',
                    ),
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

class _MedicareNameSearchField extends StatelessWidget {
  const _MedicareNameSearchField({
    required this.controller,
    required this.categoryLabel,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String categoryLabel;
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
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText:
                      'Optional: Search by provider name, NPI, Service name',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: vcare.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.categoryLabel,
    this.stateLabel,
    this.keyword,
  });

  final String categoryLabel;
  final String? stateLabel;
  final String? keyword;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final locationPart = stateLabel != null ? ' in $stateLabel' : '';
    final keywordPart = keyword != null && keyword!.isNotEmpty
        ? ' matching “$keyword”'
        : '';

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
          Icon(LucideIcons.search, size: 32, color: vcare.mutedForeground),
          const SizedBox(height: 8),
          const Text(
            'No providers found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'We couldn\'t find $categoryLabel providers$locationPart$keywordPart. '
            'Try a different name or location.',
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
