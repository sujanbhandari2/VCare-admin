import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:flutter_template/features/find_care/presentation/widgets/find_care_location_bar.dart';
import 'package:flutter_template/features/find_care/presentation/widgets/medicare_provider_result_card.dart';
import 'package:flutter_template/features/find_care/utils/find_care_category_utils.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class FindCareCategoryScreen extends ConsumerStatefulWidget {
  const FindCareCategoryScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<FindCareCategoryScreen> createState() =>
      _FindCareCategoryScreenState();
}

class _FindCareCategoryScreenState
    extends ConsumerState<FindCareCategoryScreen> {
  final _locationController = TextEditingController(text: 'San Francisco, CA');
  final _queryController = TextEditingController();

  String? _submittedKeyword;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<MedicareProviderListItem> _allItems = [];
  int _visibleCount = 0;

  ProviderCategoryItem? get _category => findCareCategoryBySlug(widget.slug);

  List<MedicareProviderListItem> get _visibleItems =>
      _allItems.take(_visibleCount).toList();

  bool get _hasMore => _visibleCount < _allItems.length;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(FindCareCategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _resetSearch();
    }
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _locationController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  void _resetSearch() {
    setState(() {
      _submittedKeyword = null;
      _isLoading = false;
      _isLoadingMore = false;
      _allItems = [];
      _visibleCount = 0;
      _queryController.clear();
    });
  }

  Future<void> _runSearch() async {
    final category = _category;
    if (category == null) return;

    setState(() {
      _submittedKeyword = _queryController.text.trim();
      _isLoading = true;
      _allItems = [];
      _visibleCount = 0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    final results = searchCategoryProviders(
      slug: widget.slug,
      keyword: _submittedKeyword ?? '',
      stateFilter: parseSearchState(_locationController.text),
    );

    setState(() {
      _allItems = results;
      _visibleCount = results.length.clamp(0, findCareCategoryPageSize);
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + findCareCategoryPageSize).clamp(
        0,
        _allItems.length,
      );
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    final vcare = context.vcare;

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

    final stateLabel = parseSearchState(_locationController.text);
    final hasSearched = _submittedKeyword != null;

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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FindCareLocationBar(
                  locationController: _locationController,
                  onDetectLocation: () {
                    _locationController.text = 'San Francisco, CA';
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Search area updated: San Francisco, CA'),
                      ),
                    );
                  },
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
                        onPressed: _isLoading ? null : _runSearch,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: _isLoading && !_isLoadingMore
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
                if (!hasSearched)
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
                if (hasSearched && !_isLoading && _visibleItems.isEmpty) ...[
                  const SizedBox(height: 8),
                  _SearchEmptyState(
                    categoryLabel: category.label,
                    stateLabel: stateLabel,
                    keyword: _submittedKeyword,
                  ),
                ],
                if (hasSearched && _isLoading && _visibleItems.isEmpty) ...[
                  const SizedBox(height: 8),
                  const _ResultsSkeleton(),
                ],
                if (_visibleItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final item in _visibleItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedicareProviderResultCardWithFavorite(item: item),
                    ),
                ],
                if (hasSearched && _hasMore) ...[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(_isLoadingMore ? 'Loading…' : 'Load more'),
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
