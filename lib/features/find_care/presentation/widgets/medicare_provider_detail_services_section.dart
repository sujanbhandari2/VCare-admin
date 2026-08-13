import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/state/medicare_provider_detail_state.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class MedicareProviderDetailServicesSection extends StatelessWidget {
  const MedicareProviderDetailServicesSection({
    super.key,
    required this.npiDigits,
    required this.state,
    required this.onLoadMore,
  });

  final String npiDigits;
  final MedicareProviderDetailState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final cmsUrl =
        'https://data.cms.gov/tools/medicare-physician-other-practitioner-look-up-tool/provider/$npiDigits';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.xxlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.clipboardList,
                size: 20,
                color: context.vcare.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HCPCS & services (Medicare FFS)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => launchUrlString(
                        cmsUrl,
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: vcare.mutedForeground,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Service lines from the CMS utilization file for this NPI (same source as the ',
                            ),
                            TextSpan(
                              text: 'CMS provider detail',
                              style: TextStyle(
                                color: context.vcare.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '). Amounts are averages in the published extract.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.servicesLoading && state.serviceLines.isEmpty)
            Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: vcare.muted.withValues(alpha: 0.4),
                      borderRadius: VCareRadius.lgAll,
                    ),
                  ),
                ),
              ),
            ),
          if (state.servicesError != null)
            VcareInlineErrorCard(message: state.servicesError),
          if (!state.servicesLoading &&
              state.servicesError == null &&
              state.serviceLines.isEmpty)
            Text(
              'No HCPCS service rows were returned for this NPI in the current CMS dataset.',
              style: TextStyle(color: vcare.mutedForeground),
            ),
          if (state.serviceLines.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('HCPCS')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('POS')),
                  DataColumn(label: Text('Drug')),
                  DataColumn(label: Text('Services')),
                  DataColumn(label: Text('Avg pay')),
                ],
                rows: state.serviceLines
                    .map(
                      (line) => DataRow(
                        cells: [
                          DataCell(Text(line.hcpcsCode)),
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                line.hcpcsDescription,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(line.placeOfService)),
                          DataCell(Text(line.drugIndicator)),
                          DataCell(Text(line.totalServices)),
                          DataCell(
                            Text(
                              formatCmsMoney(line.averageMedicarePaymentAmount),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            if (state.hasMoreServices)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: state.servicesLoadingMore ? null : onLoadMore,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(
                    state.servicesLoadingMore
                        ? 'Loading…'
                        : 'Load more services',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
