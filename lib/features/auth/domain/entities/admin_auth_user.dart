import 'admin_auth_tenant.dart';

class AdminAuthUser {
  const AdminAuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.currentTenant,
    required this.currentRoles,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final AdminAuthTenant currentTenant;
  final List<String> currentRoles;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }
}
