import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_empty_state.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_header_action.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/cases_request_card.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  Future<void> _onRefresh() async {
    if (mounted) {
      setState(() {});
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final requests = ShellMockData.allRequests();
    final open = requests
        .where((r) => r.status != RequestStatus.resolved)
        .toList();
    final resolved = requests
        .where((r) => r.status == RequestStatus.resolved)
        .toList();

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        padForMobileBottomNav: true,
        slivers: [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'Cases',
              subtitle: 'Your advocate is here to help',
              action: CasesHeaderAction(
                onPressed: () => context.pushNamed(AppRouter.requestNewName),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (requests.isEmpty)
                  const CasesEmptyState()
                else ...[
                  const SizedBox(height: 8),
                  if (open.isNotEmpty) ...[
                    _SectionLabel(text: 'Open', vcare: vcare),
                    const SizedBox(height: 8),
                    for (final request in open)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CasesRequestCard(request: request),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (resolved.isNotEmpty) ...[
                    _SectionLabel(text: 'Resolved', vcare: vcare),
                    const SizedBox(height: 8),
                    for (final request in resolved)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CasesRequestCard(
                          request: request,
                          resolved: true,
                        ),
                      ),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.vcare});

  final String text;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: vcare.mutedForeground,
        ),
      ),
    );
  }
}
