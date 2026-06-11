import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

class ProfileFamilyMember {
  const ProfileFamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.dob,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String relationship;
  final String dob;
  final String? photoUrl;
}

/// Seed data parity with vcareapp mock-data dependents.
const profileFamilySeed = <ProfileFamilyMember>[
  ProfileFamilyMember(
    id: 'd1',
    name: 'Jordan Rivera',
    relationship: 'Spouse',
    dob: '1988-03-12',
  ),
  ProfileFamilyMember(
    id: 'd2',
    name: 'Maya Rivera',
    relationship: 'Child',
    dob: '2015-09-21',
  ),
  ProfileFamilyMember(
    id: 'd3',
    name: 'Leo Rivera',
    relationship: 'Child',
    dob: '2018-06-04',
  ),
];

/// Parity with vcareapp ProfileFamilySection.
class ProfileFamilySection extends StatelessWidget {
  const ProfileFamilySection({
    super.key,
    required this.family,
    required this.onAdd,
    required this.onMemberTap,
  });

  final List<ProfileFamilyMember> family;
  final VoidCallback onAdd;
  final ValueChanged<String> onMemberTap;

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
                    color: VCareColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: vcare.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: family.isEmpty
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
    final initials = profileInitials(member.name);

    return Column(
      children: [
        if (showDivider) Divider(height: 1, color: vcare.border),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: vcare.muted,
                  child: initials.isEmpty
                      ? Icon(
                          LucideIcons.user,
                          size: 16,
                          color: vcare.mutedForeground,
                        )
                      : Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                          fontWeight: FontWeight.w600,
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
