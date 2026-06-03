class UserProfile {
  UserProfile({
    this.id,
    this.username,
    this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.email,
    this.phone,
    this.address,
    this.image,
    this.thumbnail,
    this.user,
  });

  final int? id;
  final String? username;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? email;
  final String? phone;
  final String? address;
  final String? image;
  final String? thumbnail;
  final int? user;

  UserProfile copyWith({
    int? id,
    String? username,
    String? firstName,
    String? middleName,
    String? lastName,
    String? gender,
    String? email,
    String? phone,
    String? address,
    String? image,
    String? thumbnail,
    int? user,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      image: image ?? this.image,
      thumbnail: thumbnail ?? this.thumbnail,
      user: user ?? this.user,
    );
  }
}
