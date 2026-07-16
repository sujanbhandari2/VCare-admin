import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';

/// Right-side panel — parity with vcareapp client info `Sheet side="right"`.
class ClientDetailsDrawer extends StatelessWidget {
  const ClientDetailsDrawer({super.key, required this.detail});

  final ClientDetail detail;

  /// Web `sm:max-w-md`.
  static const double maxPanelWidth = 448;

  static Future<void> show(BuildContext context, ClientDetail detail) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ClientDetailsDrawer(detail: detail);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(slide), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final panelWidth = math.min(
      MediaQuery.sizeOf(context).width,
      maxPanelWidth,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: panelWidth,
        height: double.infinity,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 16,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Client details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: vcare.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: LucideIcons.user,
                              label: 'Full name',
                              value: detail.fullName,
                            ),
                            _InfoRow(
                              icon: LucideIcons.mail,
                              label: 'Email',
                              value: detail.email,
                            ),
                            _InfoRow(
                              icon: LucideIcons.phone,
                              label: 'Phone',
                              value: detail.phone,
                            ),
                            _InfoRow(
                              icon: LucideIcons.calendar,
                              label: 'Date of birth',
                              value: formatClientDate(detail.dob),
                            ),
                            _InfoRow(
                              icon: LucideIcons.mapPin,
                              label: 'Location',
                              value: detail.location,
                            ),
                            _InfoRow(
                              icon: LucideIcons.user,
                              label: 'Gender',
                              value: clientGenderLabel(detail.gender),
                            ),
                            _InfoRow(
                              icon: LucideIcons.shield,
                              label: 'SSN',
                              value: detail.ssn,
                            ),
                            _InfoRow(
                              icon: LucideIcons.tag,
                              label: 'Reference',
                              value: '#${detail.id.toUpperCase()}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: vcare.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
