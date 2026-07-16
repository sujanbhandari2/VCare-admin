class AuthSession {
  AuthSession({
    this.refresh,
    this.access,
    this.userId,
    this.email,
    this.username,
    this.profileId,
  });

  final String? refresh;
  final String? access;
  final int? userId;
  final String? email;
  final String? username;
  final String? profileId;

  AuthSession copyWith({
    String? refresh,
    String? access,
    int? userId,
    String? email,
    String? username,
    String? profileId,
  }) {
    return AuthSession(
      refresh: refresh ?? this.refresh,
      access: access ?? this.access,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      profileId: profileId ?? this.profileId,
    );
  }
}
