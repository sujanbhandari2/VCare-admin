import 'package:flutter_template/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_template/core/database/core/base_schema.dart';
import 'package:flutter_template/core/database/tables/users/users_table.dart';

class UserSchema extends BaseSchema<UserProfile> {
  UserSchema({
    super.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
  });

  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;

  @override
  UserSchema copy({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) {
    return UserSchema(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }

  factory UserSchema.fromJson(dynamic json) {
    if (json == null) return UserSchema();
    return UserSchema(
      id: json[UsersTable.columnId],
      firstName: json[UsersTable.columnFirstName],
      lastName: json[UsersTable.columnLastName],
      username: json[UsersTable.columnUsername],
      email: json[UsersTable.columnEmail],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) UsersTable.columnId: id,
      if (firstName != null) UsersTable.columnFirstName: firstName,
      if (lastName != null) UsersTable.columnLastName: lastName,
      if (username != null) UsersTable.columnUsername: username,
      if (email != null) UsersTable.columnEmail: email,
    };
  }

  @override
  UserProfile get toModel => UserProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
      );
}
