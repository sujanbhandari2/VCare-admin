class AuthSession {
  AuthSession({
    this.refresh,
    this.access,
    this.userId,
    this.email,
    this.username,
    this.profileId,
    this.tenantId,
  });

  final String? refresh;
  final String? access;
  final int? userId;
  final String? email;
  final String? username;
  final String? profileId;
  final String? tenantId;

  AuthSession copyWith({
    String? refresh,
    String? access,
    int? userId,
    String? email,
    String? username,
    String? profileId,
    String? tenantId,
  }) {
    return AuthSession(
      refresh: refresh ?? this.refresh,
      access: access ?? this.access,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      profileId: profileId ?? this.profileId,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}
