import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_detail_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/medicare_provider_detail_services_section.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/provider_favorite_button.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class MedicareProviderDetailScreen extends ConsumerStatefulWidget {
  const MedicareProviderDetailScreen({
    super.key,
    required this.npi,
    this.passedRow,
    this.passedRaw,
  });

  final String npi;
  final MedicareProviderLookupRow? passedRow;
  final Map<String, String>? passedRaw;

  @override
  ConsumerState<MedicareProviderDetailScreen> createState() =>
      _MedicareProviderDetailScreenState();
}

class _MedicareProviderDetailScreenState
    extends ConsumerState<MedicareProviderDetailScreen> {
  var _loaded = false;

  @override
  Widget build(BuildContext context) {
    final digits = normalizeNpi(widget.npi);
    final detailState = ref.watch(medicareProviderDetailStateProvider(digits));

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(medicareProviderDetailStateProvider(digits).notifier)
            .load(passedRow: widget.passedRow, passedRaw: widget.passedRaw);
      });
    }

    if (!detailState.isValidNpi) {
      return const Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: VcarePageHeader(
                title: 'Medicare directory',
                showBack: true,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Invalid NPI — use a 10-digit number.')),
            ),
          ],
        ),
      );
    }

    if (detailState.lookupLoading && detailState.row == null) {
      return const Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: VcarePageHeader(
                title: 'Medicare directory',
                showBack: true,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    final row = detailState.row;
    if (row == null && !detailState.lookupLoading) {
      return const Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: VcarePageHeader(
                title: 'Medicare directory',
                showBack: true,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Provider not found in CMS directory.')),
            ),
          ],
        ),
      );
    }

    if (row == null) {
      return const SizedBox.shrink();
    }

    final savedProvidersState = ref.watch(savedProvidersStateProvider);
    final isFavorite = savedProvidersState.isSaved(row.npi);
    final isToggling = savedProvidersState.isToggling(row.npi);
    final name = formatMedicareProviderName(row);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'Medicare directory',
              showBack: true,
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HeroCard(
                  row: row,
                  name: name,
                  isFavorite: isFavorite,
                  isToggling: isToggling,
                  onToggleFavorite: () async {
                    final saved = await ref
                        .read(savedProvidersStateProvider.notifier)
                        .toggleSave(
                          MedicareProviderListItem(
                            row: row,
                            raw: detailState.raw,
                          ),
                        );
                    if (!context.mounted || saved == null) return;
                    context.showVcareToast(
                      title: saved ? 'Provider saved' : 'Provider removed',
                      description: name,
                      variant: saved
                          ? VcareToastVariant.success
                          : VcareToastVariant.info,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ContactActions(row: row, name: name),
                const SizedBox(height: 12),
                _LocationCard(row: row),
                const SizedBox(height: 12),
                MedicareProviderDetailServicesSection(
                  npiDigits: digits,
                  state: detailState,
                  onLoadMore: () => ref
                      .read(medicareProviderDetailStateProvider(digits).notifier)
                      .loadMoreServices(),
                ),
                if (detailState.raw.isNotEmpty &&
                    detailState.fieldOrder.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FieldsPanel(
                    raw: detailState.raw,
                    fieldOrder: detailState.fieldOrder,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'CMS public data is informational only. Confirm participation, network status, and availability directly with the provider or your plan before receiving care.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: context.vcare.mutedForeground,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.row,
    required this.name,
    required this.isFavorite,
    required this.isToggling,
    required this.onToggleFavorite,
  });

  final MedicareProviderLookupRow row;
  final String name;
  final bool isFavorite;
  final bool isToggling;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: vcare.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CMS PUBLIC DATA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: VCareColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                row.providerType.isNotEmpty
                    ? row.providerType
                    : 'Provider type not listed',
                style: TextStyle(color: vcare.mutedForeground),
              ),
              const SizedBox(height: 8),
              Text(
                'NPI ${row.npi}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: vcare.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: ProviderFavoriteButton(
            isFavorite: isFavorite,
            isToggling: isToggling,
            onPressed: onToggleFavorite,
            iconSize: 20,
            minimumSize: const Size(40, 40),
          ),
        ),
      ],
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.row, required this.name});

  final MedicareProviderLookupRow row;
  final String name;

  @override
  Widget build(BuildContext context) {
    final locale = [row.city, row.state].where((part) => part.isNotEmpty).join(', ');
    final baseQuery = [name, locale].where((part) => part.isNotEmpty).join(' ');
    final callHref =
        'https://www.google.com/search?q=${Uri.encodeComponent('$baseQuery phone number')}';
    final emailHref =
        'https://www.google.com/search?q=${Uri.encodeComponent('$baseQuery email contact')}';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => launchUrlString(
              callHref,
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(LucideIcons.phone, size: 16),
            label: const Text('Call'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => launchUrlString(
              emailHref,
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(LucideIcons.mail, size: 16),
            label: const Text('Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.row});

  final MedicareProviderLookupRow row;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.mapPin, size: 18, color: vcare.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(formatMedicareProviderLocation(row)),
          ),
        ],
      ),
    );
  }
}

class _FieldsPanel extends StatelessWidget {
  const _FieldsPanel({required this.raw, required this.fieldOrder});

  final Map<String, String> raw;
  final List<String> fieldOrder;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All CMS fields',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Full row returned by the data-viewer API (no column filter).',
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
          const SizedBox(height: 12),
          for (final key in fieldOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: vcare.mutedForeground,
                    ),
                  ),
                  Text(raw[key]?.isNotEmpty == true ? raw[key]! : '—'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
