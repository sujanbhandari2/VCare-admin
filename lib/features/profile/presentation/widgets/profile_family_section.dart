import 'package:flutter/material.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Presentation model for a family member row in the profile section.
class ProfileFamilyMember {
  const ProfileFamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.dob,
    this.gender,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String relationship;
  final String dob;
  final String? gender;
  final String? photoUrl;
}

/// Parity with vcareapp ProfileFamilySection.
class ProfileFamilySection extends StatelessWidget {
  const ProfileFamilySection({
    super.key,
    required this.family,
    required this.onAdd,
    required this.onMemberTap,
    this.fetching = false,
    this.error,
  });

  final List<ProfileFamilyMember> family;
  final VoidCallback onAdd;
  final ValueChanged<String> onMemberTap;
  final bool fetching;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text(
                'My Family',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                '(${family.length})',
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
              const Spacer(),
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '+ Add',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.vcare.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (error != null && error!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error!,
              style: TextStyle(fontSize: 12, color: context.vcare.destructive),
            ),
          ),
        ],
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: VCareRadius.xxlAll,
            side: BorderSide(color: vcare.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: fetching && family.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : family.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Text(
                    'No family members yet. Tap "+ Add" above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: vcare.mutedForeground,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < family.length; index++)
                      _FamilyMemberRow(
                        member: family[index],
                        showDivider: index > 0,
                        onTap: () => onMemberTap(family[index].id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FamilyMemberRow extends StatelessWidget {
  const _FamilyMemberRow({
    required this.member,
    required this.showDivider,
    required this.onTap,
  });

  final ProfileFamilyMember member;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        if (showDivider) Divider(height: 1, color: vcare.border),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ProfileAvatar(
                  name: member.name,
                  photoUrl: member.photoUrl,
                  photoCacheKey: 'family-member:${member.id}',
                  size: 40,
                  circular: true,
                  initialsFontSize: 14,
                  emptyIconSize: 16,
                  initialsColor: context.vcare.foreground.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${member.relationship} · ${ageFromDob(member.dob)} yrs',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
}
