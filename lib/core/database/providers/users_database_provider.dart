import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:flutter_template/shared/utils/logger.dart';
import 'package:flutter_template/core/database/core/base_database_provider.dart';
import 'package:flutter_template/core/database/tables/users/users_table.dart';

class UsersDatabaseProvider extends BaseDatabaseProvider {
  UsersDatabaseProvider._();

  static final UsersDatabaseProvider instance = UsersDatabaseProvider._();

  @override
  String get databaseName => 'users.db';

  @override
  int get databaseVersion => 1;

  @override
  FutureOr<void> onConfigure(Database db) {
    db.execute('PRAGMA journal_mode=WAL;');
    db.execute('PRAGMA synchronous=NORMAL;');
    db.execute('PRAGMA cache_size=-20000;');
  }

  @override
  Future<void> onCreate(Database db, int version) async {
    await UsersTable.instance.createTable(db);
  }

  @override
  Future<void> runMigrationScript(Database db, int version) async {
    await UsersTable.instance.migrateTable(db, version);
  }

  @override
  Future<void> deleteTables() async {
    try {
      await UsersTable.instance.deleteTable();
    } catch (e) {
      Logger.logError(e.toString());
    }
  }

  @override
  Future<void> close() async {
    try {
      final db = await database;
      if (db == null) return;
      await db.close();
    } catch (e) {
      Logger.logError(e.toString());
    }
  }
}
