class LoginResponseModel {
  LoginResponseModel({
    this.refresh,
    this.access,
    this.userId,
    this.email,
    this.username,
  });

  final String? refresh;
  final String? access;
  final int? userId;
  final String? email;
  final String? username;
  LoginResponseModel copyWith({
    String? refresh,
    String? access,
    int? userId,
    String? email,
    String? username,
  }) {
    return LoginResponseModel(
      refresh: refresh ?? this.refresh,
      access: access ?? this.access,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
    );
  }

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      refresh: json["refresh"],
      access: json["access"],
      userId: json["user_id"],
      email: json["email"],
      username: json["username"],
    );
  }

  Map<String, dynamic> toJson() => {
        "refresh": refresh,
        "access": access,
        "user_id": userId,
        "email": email,
        "username": username,
      };
}
