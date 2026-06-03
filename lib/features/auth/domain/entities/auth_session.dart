class AuthSession {
  AuthSession({
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

  AuthSession copyWith({
    String? refresh,
    String? access,
    int? userId,
    String? email,
    String? username,
  }) {
    return AuthSession(
      refresh: refresh ?? this.refresh,
      access: access ?? this.access,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
    );
  }
}
