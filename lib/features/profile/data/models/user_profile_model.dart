class UserProfileModel {
  UserProfileModel({
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
  UserProfileModel copyWith({
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
    return UserProfileModel(
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

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json["id"],
      username: json["username"],
      firstName: json["first_name"],
      middleName: json["middle_name"],
      lastName: json["last_name"],
      gender: json["gender"],
      email: json["email"],
      phone: json["phone"],
      address: json["address"],
      image: json["image"],
      thumbnail: json["thumbnail"],
      user: json["user"] ?? json['user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "first_name": firstName,
    "middle_name": middleName,
    "last_name": lastName,
    "gender": gender,
    "email": email,
    "phone": phone,
    "address": address,
    "image": image,
    "thumbnail": thumbnail,
    "user": user,
  };
}
