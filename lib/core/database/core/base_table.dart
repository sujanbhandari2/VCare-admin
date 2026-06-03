import 'dart:async';
import 'package:flutter_template/core/database/core/sql_query_builder.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_template/shared/utils/logger.dart';
import 'package:flutter_template/core/database/core/base_database_provider.dart';
import 'package:flutter_template/core/database/core/base_schema.dart';

/// An abstract class representing a table for a generic entity type [T].
///
/// This class serves as a base for creating various tables for different
/// entities. It defines the common operations that any table should
/// implement, such as creating the table, inserting, updating, deleting,
/// and querying records.
///
/// The type parameter [T] represents the entity class.
abstract class BaseTable<T extends BaseSchema> {
  /// The database provider.
  ///
  /// This provider is responsible for connecting to the database.
  BaseDatabaseProvider get provider;

  /// The name of the table.
  ///
  /// Each derived class should specify the table name for the entity.
  String get tableName;

  /// The list of columns for querying in
  ///
  /// The query given in fetch [fetch] function will execute on this columns
  List<String> get columns4Query;

  /// The column for order by
  ///
  /// Fetched items will be ordered by this column
  String get column4OrderBy;

  /// Specifies the sorting direction for the result set.
  ///
  /// Determines how the data in the column referenced by [column4OrderBy]
  /// should be ordered when fetched.
  ///
  /// It is only applicable for [fetch] function.
  ///
  /// Valid values are:
  /// - `'ASC'` for ascending order (e.g., A → Z, 0 → 9)
  /// - `'DESC'` for descending order (e.g., Z → A, 9 → 0)
  ///
  /// Default value is `'ASC'`
  ///
  /// This value directly affects the ordering of the retrieved items.
  String get sortingOrder => 'ASC';

  /// Method to get Schema [T] from json data
  ///
  /// This will lead to convert json data to the schema [T]
  T fromJson(dynamic json);

  /// Creates the table in the database.
  ///
  /// This method should be called during the database initialization to
  /// create the table structure in the database.
  Future<void> createTable(Database database);

  /// Migrate the table in the database.
  ///
  /// This method should be called during the database initialization to
  /// create the table structure in the database.
  Future<void> migrateTable(Database db, int version);

  /// Inserts a new record into the table.
  ///
  /// [schema] is the instance of [T] to be inserted.
  /// Returns inserted [T] if the insert was successful, otherwise `null`.
  Future<T?> insert(T schema) async {
    try {
      final database = await provider.database;
      final id = await database?.insert(
        tableName,
        schema.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return id != null ? schema.copy(id: id) as T : null;
    } catch (e) {
      Logger.logError(e.toString());
      return null;
    }
  }

  /// Inserts list of new records into the table with batch if necessary.
  ///
  /// [schemas] is the list of instance of [T] to be inserted.
  /// Returns inserted `true` if the insert was successful, otherwise `false`.
  Future<bool> inserts(
    List<T> schemas, {
    bool batch = false,
  }) async {
    try {
      final database = await provider.database;

      // If database is empty return false
      if (database == null) return false;

      // If schema is empty return false
      if (schemas.isEmpty) return false;

      // Getting the json from the first schema
      final firstJson = schemas.first.toJson();

      // Extracting the columns from the first schema
      final columns = firstJson.keys.toList();

      // Creating the placeholders for the insert statement
      final placeholders = List.filled(columns.length, '?').join(', ');

      // Creating the sql insert statement
      final sql =
          'INSERT OR IGNORE INTO $tableName (${columns.join(', ')}) VALUES ($placeholders)';

      // If batch is enabled, use dynamic batching
      if (batch) {
        // Calculating the total records and dynamic batch size
        final total = schemas.length;
        final batchSize = (total / 50).ceil().clamp(50, 5000);

        Logger.logMessage('Total: $total, Batch Size: $batchSize');

        // Executing the insert statement in batches
        for (int i = 0; i < total; i += batchSize) {
          final upper = (i + batchSize).clamp(0, total);
          final chunk = schemas.sublist(i, upper);

          final batchStatement = database.batch();

          for (final schema in chunk) {
            final json = schema.toJson();
            final values = columns.map((key) => json[key] ?? '').toList();
            batchStatement.rawInsert(sql, values);
          }

          await batchStatement.commit(noResult: true);
        }
      } else {
        // Executing the insert statement
        final batchStatement = database.batch();

        for (final schema in schemas) {
          final json = schema.toJson();
          final values = columns.map((key) => json[key] ?? '').toList();
          batchStatement.rawInsert(sql, values);
        }

        await batchStatement.commit(noResult: true);
      }

      return true;
    } catch (e) {
      Logger.logError(e);
      return false;
    }
  }

  /// Updates an existing record in the table.
  ///
  /// [id] is the identifier of the record to be updated.
  /// [schema] is the instance of [T] with updated data.
  /// Returns updated [T] if the update was successful, otherwise `null`.
  Future<T?> update(int id, T schema) async {
    try {
      final database = await provider.database;

      final count = await database?.update(
        tableName,
        schema.toJson(),
        where: "id = ?",
        whereArgs: [
          schema.id ?? id,
        ],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (count != null && count > 0) {
        final updated = await get(id);

        return updated;
      }

      return null;
    } catch (e) {
      Logger.logError(e.toString());
      return null;
    }
  }

  /// Deletes a record from the table.
  ///
  /// [id] is the identifier of the record to be deleted.
  /// Returns `true` if the deletion was successful, otherwise `false`.
  Future<bool> delete(int id) async {
    try {
      final database = await provider.database;

      final count = await database?.delete(
        tableName,
        where: "id = ?",
        whereArgs: [
          id,
        ],
      );

      return count != null && count > 0;
    } catch (e) {
      Logger.logError(e.toString());
      return false;
    }
  }

  /// Deletes all records from the table.
  ///
  /// Returns `true` if the deletion was successful, otherwise `false`.
  Future<bool> deleteALl() async {
    try {
      final database = await provider.database;

      final count = await database?.delete(tableName);

      return count != null && count > 0;
    } catch (e) {
      Logger.logError(e.toString());
      return false;
    }
  }

  /// Retrieves a record from the table by its identifier.
  ///
  /// [id] is the identifier of the record to be retrieved.
  /// Returns an instance of [T] if the record was found, otherwise `null`.
  Future<T?> get(int id) async {
    try {
      final database = await provider.database;

      final query = await database?.query(
        tableName,
        where: "id = ?",
        whereArgs: [id],
      );

      return query != null && query.isNotEmpty ? fromJson(query.first) : null;
    } catch (e) {
      Logger.logError(e.toString());
    }

    return null;
  }

  /// Fetches all records from the table.
  ///
  /// [limit] specifies the maximum number of records to fetch.
  /// [offset] specifies the starting point for the query.
  /// [query] is an optional search query to filter records.
  /// Returns a list of [T] instances.
  Future<List<T>> fetch({
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    try {
      final database = await provider.database;

      final whereClause = query != null
          ? query.isNotEmpty
              ? columns4Query
                  .map((column) => 'LOWER($column) LIKE ?')
                  .join(' OR ')
              : null
          : null;

      final whereArgs = query != null && query.isNotEmpty
          ? [
              '%$query%',
              '%$query%',
              '%$query%',
            ]
          : null;

      final res = await database?.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: limit,
        offset: (page - 1) * limit,
        orderBy: '$column4OrderBy $sortingOrder',
      );

      final lst = res?.map((json) => fromJson(json)).toList(growable: true);

      return lst ?? List.empty();
    } catch (e) {
      Logger.logError(e.toString());
    }
    return List.empty();
  }

  /// Fetches records from the table with a custom SQL query.
  ///
  /// This method allows for advanced querying using SQL statements.
  /// It supports pagination, filtering, grouping, and sorting.
  ///
  /// [limit] specifies the maximum number of records to fetch.
  /// [page] specifies the page number for pagination. The default value is 1.
  /// [where] is the optional WHERE clause to apply filters.
  /// [whereArgs] contains the values that replace the ? placeholders in the WHERE clause.
  /// [groupBy] specifies the optional GROUP BY clause to group the results.
  /// [orderBy] specifies the optional ORDER BY clause to sort the results.
  ///
  /// Returns a list of [T] instances that match the query.
  Future<List<T>> fetchWithRawQuery({
    int page = 1,
    int limit = 50,
    String? where,
    List<Object?>? whereArgs,
    List<String>? columns,
    String? groupBy,
    String? orderBy,
  }) async {
    try {
      final database = await provider.database;

      final res = await database?.query(
        tableName,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        limit: limit,
        offset: (page - 1) * limit,
        orderBy: orderBy ?? '$column4OrderBy $sortingOrder',
        groupBy: groupBy,
      );

      final lst = res?.map((json) => fromJson(json)).toList(growable: true);

      return lst ?? List.empty();
    } catch (e) {
      Logger.logError(e.toString());
    }
    return List.empty();
  }

  /// Executes a raw SQL query and maps the results to a list of [T] instances.
  ///
  /// This method provides a flexible way to interact with the database using custom SQL queries.
  /// It leverages the [SqlQueryBuilder] to construct the query and handle parameters.
  ///
  /// The [builder] parameter is an instance of [SqlQueryBuilder] that encapsulates the queryDetails:
  /// - `build()`: Generates the SQL query string.
  /// - `whereArgs`: Provides the values for any placeholders in the query.
  ///
  /// The method executes the query using the underlying database connection and maps the resulting
  /// rows to a list of [T] objects using the `fromJson` method.
  ///
  /// **Returns:**
  /// A [Future] that resolves to a list of [T] instances representing the query results.
  /// If an error occurs during the query execution, an empty list is returned.
  ///
  Future<List<T>> rawQuery({
    required SqlQueryBuilder builder,
  }) async {
    try {
      final database = await provider.database;

      // If builder contains different table name or null update this with current
      // table name
      if (builder.tableName != tableName) {
        builder.table(tableName);
      }

      final res = await database?.rawQuery(builder.build(), builder.whereArgs);

      final lst = res?.map((json) => fromJson(json)).toList(growable: true);

      return lst ?? List.empty();
    } catch (e) {
      Logger.logError(e.toString());
    }
    return List.empty();
  }

  /// Retrieves the total number of records in the table.
  ///
  /// Returns the total count of records.
  Future<int> count() async {
    try {
      final database = await provider.database;

      final q = 'SELECT COUNT(*) FROM $tableName';

      final res = await database?.rawQuery(q);

      if (res == null || res.isEmpty) return 0;

      if (res.first.containsKey('COUNT(*)')) {
        return Sqflite.firstIntValue(res) ?? 0;
      }
    } catch (e) {
      Logger.logError(e.toString());
    }
    return 0;
  }

  /// Delete the table.
  ///
  Future<void> deleteTable() async {
    try {
      final database = await provider.database;
      database?.execute("DROP TABLE IF EXISTS $tableName");
    } catch (e) {
      Logger.logError(e.toString());
    }
  }
}
