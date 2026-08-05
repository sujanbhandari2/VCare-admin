import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_saved_providers_builder.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_provider_card.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_providers_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class SavedProvidersScreen extends ConsumerStatefulWidget {
  const SavedProvidersScreen({super.key});

  @override
  ConsumerState<SavedProvidersScreen> createState() =>
      _SavedProvidersScreenState();
}

class _SavedProvidersScreenState extends ConsumerState<SavedProvidersScreen> {
  var _loaded = false;

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(savedProvidersStateProvider.notifier).fetchSavedProviders();
      });
    }

    final savedProvidersState = ref.watch(savedProvidersStateProvider);
    final providers = buildHomeSavedProviders(
      savedProviders: savedProvidersState.providers,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverVcarePageHeader(title: 'Saved Providers', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (savedProvidersState.fetching && providers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (providers.isEmpty)
                  _SavedProvidersEmptyState(
                    onFindCare: () =>
                        context.pushNamed(AppRouter.findCare.toPathName),
                  )
                else
                  ...providers.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SavedProviderListCard(
                        item: item,
                        onTap: () => _openProvider(context, item),
                        onRemove: () => _removeProvider(context, item),
                        isRemoving:
                            item.medicareNpi != null &&
                            savedProvidersState.isToggling(item.medicareNpi!),
                        onCall: item.phone == null
                            ? null
                            : () => _launchTel(context, item.phone!),
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

  void _openProvider(BuildContext context, SavedProviderItem item) {
    final npi = item.medicareNpi;
    if (npi == null) return;
    context.pushNamed(
      AppRouter.medicareProviderDetailName,
      pathParameters: {'npi': npi},
    );
  }

  Future<void> _removeProvider(
    BuildContext context,
    SavedProviderItem item,
  ) async {
    final npi = item.medicareNpi;
    if (npi == null) return;

    final removed = await ref
        .read(savedProvidersStateProvider.notifier)
        .removeByNpi(npi);
    if (!context.mounted || !removed) return;

    context.showVcareToast(
      title: 'Provider removed',
      description: item.name,
      variant: VcareToastVariant.info,
    );
  }

  Future<void> _launchTel(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final launched = await launchUrlString('tel:$digits');
    if (!launched && context.mounted) {
      context.showVcareToast(
        title: 'Could not call',
        description: phone,
        variant: VcareToastVariant.destructive,
      );
    }
  }
}

class _SavedProvidersEmptyState extends StatelessWidget {
  const _SavedProvidersEmptyState({required this.onFindCare});

  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: vcare.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(LucideIcons.heart, color: vcare.accent, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Save your go-to providers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep the places you and your family rely on — Urgent Care, ER, '
            'Pharmacy, PCP and more — one tap away when you need them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onFindCare,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('Go to providers'),
          ),
        ],
      ),
    );
  }
}
