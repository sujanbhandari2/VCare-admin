import 'package:vcare_admin/features/profile/data/models/family_member_model.dart';
import 'package:vcare_admin/features/profile/domain/entities/family_member.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_family_section.dart';

extension FamilyMemberModelMapper on FamilyMemberModel {
  FamilyMember toEntity() {
    return FamilyMember(
      id: id,
      fullName: fullName,
      relationship: relationship,
      dateOfBirth: dateOfBirth,
      gender: gender,
      photoUrl: profilePreviewLink,
    );
  }
}

extension FamilyMemberEntityMapper on FamilyMember {
  ProfileFamilyMember toProfileFamilyMember() {
    return ProfileFamilyMember(
      id: id,
      name: fullName,
      relationship: relationship,
      dob: dateOfBirth,
      gender: gender,
      photoUrl: photoUrl,
    );
  }
}

Map<String, dynamic> toFamilyMemberPayload({
  required String fullName,
  required String relationship,
  required String gender,
  required String dateOfBirth,
  String? profileId,
}) {
  final payload = <String, dynamic>{
    'fullName': fullName,
    'relationship': relationship,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
  };

  final trimmedProfileId = profileId?.trim();
  if (trimmedProfileId != null && trimmedProfileId.isNotEmpty) {
    payload['profileId'] = trimmedProfileId;
  }

  return payload;
}
