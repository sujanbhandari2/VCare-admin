import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';
import 'package:flutter_template/shared/widgets/vcare_sticky_tab_header.dart';

class FindCareScreen extends StatefulWidget {
  const FindCareScreen({super.key});

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController(text: 'San Francisco, CA');

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              hasSubtitle: true,
              title: vcareTabPageTitle(
                title: 'Find Care',
                subtitle: 'Browse by category.',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _LocationBar(
                  controller: _locationController,
                  vcare: vcare,
                  searchController: _searchController,
                  onSearch: () =>
                      context.pushNamed(AppRouter.findCareSearchName),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Searches the live '),
                      TextSpan(
                        text: 'Medicare Physician & Other Practitioners',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: VCareColors.foreground,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' public dataset (CMS). Use Provider name, NPI, Service name; your "Searching near" state narrows results when set. For first + last fields, use ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => context.pushNamed(
                            AppRouter.medicareProviderLookupName,
                          ),
                          child: Text(
                            'Medicare provider lookup',
                            style: TextStyle(
                              color: VCareColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: VCareColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
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
                const SizedBox(height: 8),
                _LinkCard(
                  icon: LucideIcons.landmark,
                  iconBg: VCareColors.primary.withValues(alpha: 0.1),
                  iconColor: VCareColors.primary,
                  title: 'Medicare provider lookup',
                  subtitle:
                      'Search CMS Medicare physician & practitioner directory.',
                  vcare: vcare,
                  onTap: () =>
                      context.pushNamed(AppRouter.medicareProviderLookupName),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.pushNamed(AppRouter.costLookupName),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: vcare.gradientCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                LucideIcons.dollarSign,
                                color: VCareColors.primaryForeground,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Procedure cost lookup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: VCareColors.primaryForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Estimate what you'll pay before you go.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: VCareColors.primaryForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.controller,
    required this.vcare,
    required this.searchController,
    this.onSearch,
  });

  final TextEditingController controller;
  final VCareThemeExtension vcare;
  final TextEditingController searchController;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: vcare.accent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.accent.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: vcare.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Searching near',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'City, State',
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: vcare.muted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {},
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(LucideIcons.locateFixed, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: vcare.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 16,
                  color: vcare.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 14),
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
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: searchController,
          builder: (context, _) {
            return SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: searchController.text.trim().isEmpty
                    ? null
                    : onSearch,
                style: FilledButton.styleFrom(
                  backgroundColor: VCareColors.primary,
                  foregroundColor: VCareColors.primaryForeground,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Search providers'),
              ),
            );
          },
        ),
      ],
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

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.vcare,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
        ),
      ),
    );
  }
}

const _cardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
];
