import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/presentation/widgets/cases_empty_state.dart';
import 'package:flutter_template/features/cases/presentation/widgets/cases_header_action.dart';
import 'package:flutter_template/features/cases/presentation/widgets/cases_request_card.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/shell/data/shell_mock_data.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  bool _previewEmpty = false;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final requests = _previewEmpty
        ? <CareRequest>[]
        : ShellMockData.allRequests();
    final open = requests
        .where((r) => r.status != RequestStatus.resolved)
        .toList();
    final resolved = requests
        .where((r) => r.status == RequestStatus.resolved)
        .toList();

    return Scaffold(
      body: CustomScrollView(
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Align(
                  alignment: Alignment.centerRight,
                  child: _PreviewToggle(
                    previewEmpty: _previewEmpty,
                    onToggle: () =>
                        setState(() => _previewEmpty = !_previewEmpty),
                  ),
                ),
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

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({required this.previewEmpty, required this.onToggle});

  final bool previewEmpty;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.muted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onToggle,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            previewEmpty ? LucideIcons.eye : LucideIcons.eyeOff,
            size: 12,
            color: vcare.mutedForeground,
          ),
        ),
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
