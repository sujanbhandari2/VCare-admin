import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Blocks [child] until tenant feature access resolves from `/settings`.
class FeatureAccessGate extends ConsumerWidget {
  const FeatureAccessGate({
    super.key,
    required this.isEnabled,
    required this.deniedTitle,
    required this.deniedMessage,
    required this.deniedIcon,
    required this.child,
    this.loadingChild,
  });

  final bool Function(FeatureAccess access) isEnabled;
  final String deniedTitle;
  final String deniedMessage;
  final IconData deniedIcon;
  final Widget child;
  final Widget? loadingChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(featureAccessStateProvider);

    if (accessState.fetching) {
      return loadingChild ?? const Center(child: CircularProgressIndicator());
    }

    if (accessState.hasError) {
      return Center(
        child: VcareErrorStatePanel(
          title: 'Unable to load settings',
          message: accessState.error,
          actionLabel: context.appLocalization.retry,
          onAction: () => ref
              .read(featureAccessStateProvider.notifier)
              .refreshFromApi(forceRefresh: true),
        ),
      );
    }

    final access = accessState.data ?? FeatureAccess.disabled;
    if (!isEnabled(access)) {
      return Center(
        child: FeatureAccessDeniedPanel(
          title: deniedTitle,
          message: deniedMessage,
          icon: deniedIcon,
        ),
      );
    }

    return child;
  }
}

/// Permission edge state when a tenant feature is disabled.
class FeatureAccessDeniedPanel extends StatelessWidget {
  const FeatureAccessDeniedPanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: vcare.card,
          borderRadius: VCareRadius.xxlAll,
          border: Border.all(color: vcare.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.35),
                  borderRadius: VCareRadius.xlAll,
                ),
                child: Icon(icon, color: vcare.mutedForeground, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: vcare.mutedForeground,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
