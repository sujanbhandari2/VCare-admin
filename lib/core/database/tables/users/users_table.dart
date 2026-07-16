import 'package:vcare_admin/shared/utils/logger.dart';
import 'package:vcare_admin/core/database/core/base_table.dart';
import 'package:vcare_admin/core/database/core/base_database_provider.dart';
import 'package:vcare_admin/core/database/providers/users_database_provider.dart';
import 'package:vcare_admin/core/database/tables/users/user_schema.dart';
import 'package:sqflite/sqflite.dart';

class UsersTable extends BaseTable<UserSchema> {
  @override
  BaseDatabaseProvider get provider => UsersDatabaseProvider.instance;

  @override
  String get tableName => "tbl_users";

  @override
  String get column4OrderBy => columnFirstName;

  @override
  List<String> get columns4Query => [columnFirstName, columnLastName];

  @override
  UserSchema fromJson(json) => UserSchema.fromJson(json);

  /// Columns
  static const String columnId = "id";
  static const String columnFirstName = "first_name";
  static const String columnLastName = "last_name";
  static const String columnUsername = "username";
  static const String columnEmail = "email";

  /// Private static instance, initialized lazily.
  ///
  static UsersTable? _instance;

  /// Private Constructor
  ///
  UsersTable._internal();

  /// Lazy-loaded singleton instance of this class
  ///
  static UsersTable get instance {
    if (_instance == null) {
      Logger.logMessage("UsersTable is initialized!");
    }
    _instance ??= UsersTable._internal();
    return _instance!;
  }

  @override
  Future<void> createTable(Database database) async {
    await database.execute(
      "CREATE TABLE IF NOT EXISTS $tableName ("
      "$columnId INTEGER PRIMARY KEY AUTOINCREMENT,"
      "$columnFirstName TEXT,"
      "$columnLastName TEXT,"
      "$columnUsername TEXT,"
      "$columnEmail TEXT"
      ")",
    );
  }

  @override
  Future<void> migrateTable(Database db, int version) async {
    switch (version) {
      case 2:
        break;
      default:
        break;
    }
  }
}
