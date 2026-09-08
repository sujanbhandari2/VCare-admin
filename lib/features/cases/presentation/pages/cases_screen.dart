import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/feature_access/presentation/widgets/feature_access_gate.dart';

import 'cases_screen_content.dart';

/// Cases list — status / priority / bookmark filters with paginated search.
class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureAccessGate(
      isEnabled: (access) => access.caseManagement,
      deniedTitle: 'Cases unavailable',
      deniedMessage: 'You do not have permission to view cases.',
      deniedIcon: LucideIcons.briefcase,
      child: const CasesScreenContent(),
    );
  }
}
