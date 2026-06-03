import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_mock_data.dart';
import 'package:flutter_template/features/profile/domain/entities/local_profile.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_address.dart';
import 'package:flutter_template/features/profile/utils/profile_utils.dart';
import 'package:flutter_template/shared/widgets/common_image.dart';

/// Parity with vcareapp ProfileSummaryCard.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onEdit,
    this.onAddressTap,
  });

  final LocalProfile profile;
  final VoidCallback onEdit;
  final VoidCallback? onAddressTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final address = profile.address;
    final dobLabel = profile.dob.isEmpty
        ? 'Add date of birth'
        : formatProfileDob(profile.dob);

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ProfileAvatar(photoUrl: profile.photoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          HomeMockData.member.plan,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VCareColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: vcare.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 16,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Divider(height: 1, color: vcare.border),
              ),
              const SizedBox(height: 12),
              _DetailRow(icon: LucideIcons.cake, label: dobLabel),
              const SizedBox(height: 6),
              _DetailRow(icon: LucideIcons.mail, label: profile.email),
              const SizedBox(height: 6),
              _DetailRow(icon: LucideIcons.phone, label: profile.phone),
              const SizedBox(height: 6),
              _AddressDetailRow(address: address, onAddressTap: onAddressTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = HomeMockData.member.photoAsset;
    final source = photoUrl ?? fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: source.startsWith('assets/')
          ? CommonImage(
              assetsOrUrlOrPath: source,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(source),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CommonImage(
                assetsOrUrlOrPath: fallback,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Row(
      children: [
        Icon(icon, size: 14, color: vcare.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
        ),
      ],
    );
  }
}

class _AddressDetailRow extends StatelessWidget {
  const _AddressDetailRow({required this.address, this.onAddressTap});

  final ProfileAddress? address;
  final VoidCallback? onAddressTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (address == null) {
      return InkWell(
        onTap: onAddressTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, size: 14, color: vcare.mutedForeground),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: VCareColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add home address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VCareColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final savedAddress = address;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            LucideIcons.mapPin,
            size: 14,
            color: vcare.mutedForeground,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            formatProfileAddress(savedAddress!),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
        ),
      ],
    );
  }
}
