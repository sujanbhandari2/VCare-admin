import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';

/// Tappable country-code prefix for login phone fields.
class LoginPhoneCountrySelector extends StatelessWidget {
  const LoginPhoneCountrySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthPhoneCountry selected;
  final ValueChanged<AuthPhoneCountry> onChanged;

  Future<void> _showPicker(BuildContext context) async {
    final vcare = context.vcare;
    final picked = await showModalBottomSheet<AuthPhoneCountry>(
      context: context,
      backgroundColor: vcare.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Select country',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              for (final country in AuthPhoneCountry.values)
                ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(country.label),
                  subtitle: Text(
                    country.dialCodeDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: country == selected
                          ? VCareColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: country == selected
                      ? Icon(LucideIcons.check, color: VCareColors.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(country),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.dialCodeDisplay,
              style: TextStyle(
                color: vcare.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: vcare.mutedForeground,
            ),
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.only(left: 8),
              color: vcare.border,
            ),
          ],
        ),
      ),
    );
  }
}
