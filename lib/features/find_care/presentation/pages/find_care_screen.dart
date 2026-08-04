import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/utils/find_care_current_location_flow.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/find_care_location_bar.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

class FindCareScreen extends ConsumerStatefulWidget {
  const FindCareScreen({super.key});

  @override
  ConsumerState<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends ConsumerState<FindCareScreen> {
  final _searchController = TextEditingController();
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final location = ref.read(findCareSearchLocationProvider);
    _locationController = TextEditingController(text: location.displayLabel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(userLoggedInStateProvider)) {
        ref
            .read(savedProvidersStateProvider.notifier)
            .ensureSavedProvidersLoaded();
      }
    });
  }

  Future<void> _clearCurrentLocation() async {
    await ref
        .read(findCareSearchLocationProvider.notifier)
        .useProfileLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _openSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    ref
        .read(findCareSearchLocationProvider.notifier)
        .setFromDisplayText(_locationController.text);
    context.pushNamed(
      AppRouter.findCareSearchName,
      queryParameters: {'q': query},
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);
    final location = ref.watch(findCareSearchLocationProvider);
    final detecting = ref.watch(
      findCareCurrentLocationStateProvider.select((s) => s.detecting),
    );

    if (_locationController.text != location.displayLabel) {
      _locationController.text = location.displayLabel;
    }

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        padForMobileBottomNav: true,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: true,
              title: vcareTabPageTitle(
                title: 'Find Providers',
                subtitle: 'Browse by category.',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      _NameSearchField(controller: _searchController),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: _searchController,
                        builder: (context, _) {
                          return FilledButton(
                            onPressed: _searchController.text.trim().isEmpty
                                ? null
                                : _openSearch,
                            style: FilledButton.styleFrom(
                              backgroundColor: VCareColors.primary,
                              foregroundColor: VCareColors.primaryForeground,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Search providers'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Browse Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  primary: false,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.22,
                  ),
                  itemCount: ShellMockData.providerCategories.length,
                  itemBuilder: (context, index) {
                    final c = ShellMockData.providerCategories[index];
                    return _CategoryCard(
                      category: c,
                      vcare: vcare,
                      onTap: () => context.pushNamed(
                        AppRouter.findCareCategoryName,
                        pathParameters: {'slug': c.slug},
                      ),
                    );
                  },
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
  const _NameSearchField({required this.controller});

  final TextEditingController controller;

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
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.vcare,
    this.onTap,
  });

  final ProviderCategoryItem category;
  final VCareThemeExtension vcare;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      shadowColor: Colors.black12,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.iconColor, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    category.blurb,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: vcare.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
