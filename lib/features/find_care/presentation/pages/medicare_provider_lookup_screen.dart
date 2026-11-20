import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_lookup_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/medicare_provider_result_card.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class MedicareProviderLookupScreen extends ConsumerStatefulWidget {
  const MedicareProviderLookupScreen({super.key});

  @override
  ConsumerState<MedicareProviderLookupScreen> createState() =>
      _MedicareProviderLookupScreenState();
}

class _MedicareProviderLookupScreenState
    extends ConsumerState<MedicareProviderLookupScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(medicareProviderLookupStateProvider);
    _firstNameController = TextEditingController(text: state.firstName);
    _lastNameController = TextEditingController(text: state.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final lookupState = ref.watch(medicareProviderLookupStateProvider);
    final notifier = ref.read(medicareProviderLookupStateProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverVcarePageHeader(
            title: 'Medicare Lookup',
            subtitle: 'CMS physician & practitioner directory',
            showBack: true,
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: vcare.mutedForeground,
                    ),
                    children: [
                      const TextSpan(text: 'Results come from the '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => launchUrlString(
                            'https://data.cms.gov/tools/medicare-physician-other-practitioner-look-up-tool',
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            'Medicare Physician & Other Practitioners',
                            style: TextStyle(
                              color: context.vcare.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' dataset (fee-for-service claims). This is not a guarantee of current participation, network status, or availability.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _LookupField(
                        label: 'First name',
                        hint: 'Maya',
                        controller: _firstNameController,
                        onChanged: notifier.setFirstName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LookupField(
                        label: 'Last name',
                        hint: 'Patel',
                        controller: _lastNameController,
                        onChanged: notifier.setLastName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Material(
                  color: vcare.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: VCareRadius.xlAll,
                    side: BorderSide(color: vcare.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: lookupState.state.isEmpty
                            ? '__any__'
                            : lookupState.state,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: '__any__',
                            child: Text('Any state'),
                          ),
                          ...usStateCodes.map(
                            (entry) => DropdownMenuItem(
                              value: entry.code,
                              child: Text('${entry.name} (${entry.code})'),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            notifier.setStateCode(value ?? '__any__'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: lookupState.loading ? null : notifier.submitSearch,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: lookupState.loading && !lookupState.loadingMore
                      ? const Text('Searching…')
                      : const Text('Search CMS directory'),
                ),
                if (lookupState.error != null) ...[
                  const SizedBox(height: 12),
                  VcareInlineErrorCard(
                    message: lookupState.error,
                    onRetry: notifier.submitSearch,
                  ),
                ],
                if (lookupState.enabled) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Results',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (lookupState.loading && lookupState.items.isEmpty)
                    const _LookupSkeleton()
                  else if (lookupState.items.isEmpty)
                    Text(
                      'No providers found for that name and state.',
                      style: TextStyle(color: vcare.mutedForeground),
                    )
                  else ...[
                    for (final item in lookupState.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MedicareProviderResultCardWithFavorite(
                          item: item,
                        ),
                      ),
                    if (lookupState.hasMore)
                      OutlinedButton(
                        onPressed: lookupState.loadingMore
                            ? null
                            : notifier.loadMore,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(
                          lookupState.loadingMore ? 'Loading…' : 'Load more',
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  'Data is sourced from CMS public files and may not reflect real-time participation. Confirm details with the provider before scheduling care.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: vcare.mutedForeground,
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

class _LookupField extends StatelessWidget {
  const _LookupField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 4),
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: VCareRadius.xlAll,
            side: BorderSide(color: vcare.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LookupSkeleton extends StatelessWidget {
  const _LookupSkeleton();

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
              borderRadius: VCareRadius.xlAll,
            ),
          ),
        ),
      ),
    );
  }
}
