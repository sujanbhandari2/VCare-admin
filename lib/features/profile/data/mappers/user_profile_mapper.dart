import 'package:vcare_admin/features/profile/data/models/user_profile_model.dart'
    as model;
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

extension UserProfileMapper on model.UserProfileModel {
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      username: username,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      email: email,
      phone: phone,
      address: address,
      image: image,
      thumbnail: thumbnail,
      user: user,
    );
  }
}

extension UserProfileEntityMapper on UserProfile {
  model.UserProfileModel toModel() {
    return model.UserProfileModel(
      id: id,
      username: username,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      email: email,
      phone: phone,
      address: address,
      image: image,
      thumbnail: thumbnail,
      user: user,
    );
  }
}
