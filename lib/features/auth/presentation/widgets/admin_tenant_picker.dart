import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

class AdminTenantPicker extends StatefulWidget {
  const AdminTenantPicker({
    super.key,
    required this.tenants,
    required this.onContinue,
    required this.isSubmitting,
  });

  final List<TenantOption> tenants;
  final void Function(String tenantSlug) onContinue;
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
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoginStepHeader(
          icon: LucideIcons.building2,
          title: 'Select organization',
          subtitle: Text(
            'Your account is linked to multiple organizations. Select one to continue.',
          ),
        ),
        ...widget.tenants.map((tenant) {
          final isSelected = _selectedSlug == tenant.slug;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? vcare.primary.withValues(alpha: 0.08)
                  : vcare.card,
              shape: RoundedRectangleBorder(
                borderRadius: VCareRadius.lgAll,
                side: BorderSide(
                  color: isSelected ? vcare.primary : vcare.border,
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
                          color: vcare.muted,
                          borderRadius: VCareRadius.mdAll,
                        ),
                        child: Icon(
                          LucideIcons.building2,
                          size: 18,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              tenant.slug,
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
            ),
          );
        }),
        const SizedBox(height: 16),
        LoginPrimaryButton(
          label: 'Continue',
          loading: widget.isSubmitting,
          onPressed: _selectedSlug == null || widget.isSubmitting
              ? null
              : () => widget.onContinue(_selectedSlug!),
        ),
      ],
    );
  }
}
