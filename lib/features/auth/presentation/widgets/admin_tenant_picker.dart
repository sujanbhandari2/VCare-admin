import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class AdminTenantPicker extends StatefulWidget {
  const AdminTenantPicker({
    super.key,
    required this.tenants,
    required this.onContinue,
    required this.onBack,
    required this.isSubmitting,
  });

  final List<TenantOption> tenants;
  final void Function(String tenantSlug) onContinue;
  final VoidCallback onBack;
  final bool isSubmitting;

  @override
  State<AdminTenantPicker> createState() => _AdminTenantPickerState();
}

class _AdminTenantPickerState extends State<AdminTenantPicker> {
  String? _selectedSlug;

  @override
  void initState() {
    super.initState();
    if (widget.tenants.length == 1) {
      _selectedSlug = widget.tenants.first.slug;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose your organization',
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your account is linked to multiple organizations. Select one to continue.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.theme.hintColor,
          ),
        ),
        const SizedBox(height: 20),
        ...widget.tenants.map((tenant) {
          final isSelected = _selectedSlug == tenant.slug;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? context.theme.colorScheme.primary.withValues(alpha: 0.08)
                  : context.theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.lgAll,
                side: BorderSide(
                  color: isSelected
                      ? context.theme.colorScheme.primary
                      : context.theme.dividerColor,
                ),
              ),
              child: InkWell(
                borderRadius: VCareRadius.lgAll,
                onTap: widget.isSubmitting
                    ? null
                    : () => setState(() => _selectedSlug = tenant.slug),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainerHighest,
                          borderRadius: VCareRadius.mdAll,
                        ),
                        child: const Icon(LucideIcons.building2, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              tenant.slug,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.theme.hintColor,
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
          );
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                text: 'Back',
                onPressed: widget.isSubmitting ? null : widget.onBack,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.elevated(
                text: widget.isSubmitting ? 'Signing in…' : 'Continue',
                loading: widget.isSubmitting,
                onPressed: _selectedSlug == null || widget.isSubmitting
                    ? null
                    : () => widget.onContinue(_selectedSlug!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
