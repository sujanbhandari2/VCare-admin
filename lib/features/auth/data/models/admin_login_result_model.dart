import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/app_urls.dart';

class AdminAuthTenantModel {
  const AdminAuthTenantModel({
    required this.id,
    required this.slug,
    required this.name,
  });

  final String id;
  final String slug;
  final String name;

  factory AdminAuthTenantModel.fromJson(Map<String, dynamic> json) {
    return AdminAuthTenantModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
    };
  }

  AdminAuthTenant toEntity() {
    return AdminAuthTenant(id: id, slug: slug, name: name);
  }
}

class AdminAuthUserModel {
  const AdminAuthUserModel({
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
  final AdminAuthTenantModel currentTenant;
  final List<String> currentRoles;

  factory AdminAuthUserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['currentRoles'];
    return AdminAuthUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      currentTenant: AdminAuthTenantModel.fromJson(
        json['currentTenant'] as Map<String, dynamic>? ?? const {},
      ),
      currentRoles: rolesRaw is List
          ? rolesRaw.whereType<String>().toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'currentTenant': currentTenant.toJson(),
      'currentRoles': currentRoles,
    };
  }

  AdminAuthUser toEntity() {
    return AdminAuthUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      currentTenant: currentTenant.toEntity(),
      currentRoles: currentRoles,
    );
  }
}

class AppUrlsModel {
  const AppUrlsModel({
    this.portal,
    this.client,
    this.agent,
    this.landing,
  });

  final String? portal;
  final String? client;
  final String? agent;
  final String? landing;

  factory AppUrlsModel.fromJson(Map<String, dynamic> json) {
    return AppUrlsModel(
      portal: json['portal'] as String?,
      client: json['client'] as String?,
      agent: json['agent'] as String?,
      landing: json['landing'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (portal != null) 'portal': portal,
      if (client != null) 'client': client,
      if (agent != null) 'agent': agent,
      if (landing != null) 'landing': landing,
    };
  }

  AppUrls toEntity() {
    return AppUrls(
      portal: portal,
      client: client,
      agent: agent,
      landing: landing,
    );
  }
}

class TenantOptionModel {
  const TenantOptionModel({
    required this.slug,
    required this.name,
  });

  final String slug;
  final String name;

  factory TenantOptionModel.fromJson(Map<String, dynamic> json) {
    return TenantOptionModel(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  TenantOption toEntity() {
    return TenantOption(slug: slug, name: name);
  }
}

class AdminLoginResultModel {
  AdminLoginResultModel._({
    this.session,
    this.tenants = const [],
    this.requiresTenantSelection = false,
  });

  final AdminAuthSession? session;
  final List<TenantOptionModel> tenants;
  final bool requiresTenantSelection;

  factory AdminLoginResultModel.fromJson(Map<String, dynamic> json) {
    if (json['requiresTenantSelection'] == true) {
      final tenantsRaw = json['tenants'];
      return AdminLoginResultModel._(
        requiresTenantSelection: true,
        tenants: tenantsRaw is List
            ? tenantsRaw
                  .whereType<Map<String, dynamic>>()
                  .map(TenantOptionModel.fromJson)
                  .toList()
            : const [],
      );
    }

    final user = json['user'] as Map<String, dynamic>? ?? {};
    final tokens = json['tokens'] as Map<String, dynamic>? ?? {};
    final menuRaw = json['menu'];
    final urlsRaw = json['urls'];

    final userModel = AdminAuthUserModel.fromJson(user);
    final accessToken = tokens['accessToken'] as String? ?? '';
    final refreshToken = tokens['refreshToken'] as String? ?? '';

    return AdminLoginResultModel._(
      session: AdminAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: userModel.toEntity(),
        menu: menuRaw is List
            ? menuRaw.whereType<String>().toList()
            : const [],
        urls: urlsRaw is Map<String, dynamic>
            ? AppUrlsModel.fromJson(urlsRaw).toEntity()
            : null,
      ),
    );
  }

  AdminLoginOutcome toOutcome() {
    if (requiresTenantSelection) {
      return AdminLoginTenantSelectionRequired(
        tenants.map((tenant) => tenant.toEntity()).toList(),
      );
    }

    final resolvedSession = session;
    if (resolvedSession == null) {
      throw StateError('Admin login response missing session data');
    }

    return AdminLoginAuthenticated(resolvedSession);
  }
}

class AuthRefreshTokensModel {
  const AuthRefreshTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory AuthRefreshTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthRefreshTokensModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  AuthRefreshTokens toEntity() {
    return AuthRefreshTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
