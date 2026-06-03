import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:flutter_template/shared/utils/logger.dart';

/// An abstract class that provides base functionality for SQLite database access.
///
/// This class can be extended to create different database providers with their
/// own specific tables and configurations.
abstract class BaseDatabaseProvider {
  /// The SQLite database instance.
  Database? _database;

  /// The name of the database file.
  ///
  /// Must be implemented by subclasses.
  String get databaseName;

  /// The version of the database.
  ///
  /// Must be implemented by subclasses.
  int get databaseVersion;

  /// Gets the database instance asynchronously.
  ///
  /// If the database is already initialized, it returns the existing instance.
  /// Otherwise, it initializes the database and then returns the instance.
  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await _initDatabase();
    return _database;
  }

  /// Initializes the database.
  ///
  /// This method sets up the database by specifying the file path, version,
  /// and the onCreate and onUpgrade callbacks.
  ///
  /// Returns the initialized [Database] instance.
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();

    return await openDatabase(
      join(path, databaseName),
      version: databaseVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  /// Abstract method to be implemented by subclasses for database configuration.
  /// This function will be invoked on the very beginning of the database creation
  /// You can run script to configure the database.
  /// Like:
  /// - db.execute('PRAGMA journal_mode=WAL;');
  /// - db.execute('PRAGMA synchronous=NORMAL;');
  /// - db.execute('PRAGMA cache_size=-20000;');
  ///
  FutureOr<void> onConfigure(Database db);

  /// Abstract method to be implemented by subclasses for database creation.
  ///
  /// This method should create all necessary tables for the specific database.
  Future<void> onCreate(Database db, int version);

  /// Handles database upgrades through migration scripts.
  ///
  /// Can be overridden by subclasses if needed.
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      await runMigrationScript(db, i);
    }
  }

  /// Runs the migration script for the given version.
  ///
  /// Should be implemented by subclasses to handle specific migrations.
  Future<void> runMigrationScript(Database db, int version);

  /// Delete all the tables in the database.
  ///
  /// This method should be implemented by subclasses to handle clearing
  /// their specific tables.
  ///
  Future<void> deleteTables();

  /// Closes the database connection.
  ///
  /// This should be called when the database is no longer needed.
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
