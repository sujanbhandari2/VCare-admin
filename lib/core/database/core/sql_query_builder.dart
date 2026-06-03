/// A builder class to construct SQL queries dynamically for the specified table.
///
/// This class provides a fluent interface to build SQL queries with
/// optional conditions, grouping, sorting, and pagination.
class SqlQueryBuilder {
  /// The name of the table for which the query is being built.
  String? _tableName;

  /// Gets the name of the database table associated with this query builder.
  String? get tableName => _tableName;

  /// The columns to be selected in the query.
  List<String>? _columns;

  /// The WHERE clause for the query.
  ///
  /// This clause is used to filter the records based on specific conditions.
  String? _whereClause;

  /// The arguments for the WHERE clause.
  ///
  /// These are the values that replace the placeholders in the WHERE clause.
  List<Object?>? _whereArgs;

  List<Object?>? get whereArgs =>
      _whereArgs != null ? List<Object?>.unmodifiable(_whereArgs!) : null;

  /// The GROUP BY clause for the query.
  ///
  /// This clause is used to group the records based on specific columns.
  String? _groupBy;

  /// The ORDER BY clause for the query.
  ///
  /// This clause is used to sort the records based on specific columns.
  String? _orderBy;

  /// The LIMIT clause for the query.
  ///
  /// This clause is used to limit the number of records returned by the query.
  int? _limit;

  /// The OFFSET clause for the query.
  ///
  /// This clause is used to specify the starting point for the query.
  int? _offset;

  /// Constructs an instance of [SqlQueryBuilder] for the specified table.
  ///
  /// [tableName] is the name of the table for which the query is being built.
  SqlQueryBuilder();

  /// Sets the name of the database table for the query.
  ///
  /// This method specifies the table from which data will be selected or manipulated.
  /// It is used to construct the `FROM` clause of the SQL query.
  ///
  /// [name] The name of the database table.
  /// Returns the updated instance of [SqlQueryBuilder] for method chaining.
  SqlQueryBuilder table(String? name) {
    _tableName = name;
    return this;
  }

  /// Sets the columns to be selected in the query.
  ///
  /// [columns] The list of columns to be selected.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder columns(List<String> columns) {
    _columns = columns;
    return this;
  }

  /// Sets the WHERE clause for the query.
  ///
  /// [whereClause] is the SQL WHERE clause.
  /// [args] are the arguments for the WHERE clause.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder where(String? whereClause, {List<Object?>? args}) {
    _whereClause = whereClause;
    _whereArgs = args;
    return this;
  }

  /// Sets the GROUP BY clause for the query.
  ///
  /// [groupBy] is the SQL GROUP BY clause.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder groupBy(String? groupBy) {
    _groupBy = groupBy;
    return this;
  }

  /// Sets the ORDER BY clause for the query.
  ///
  /// [orderBy] is the SQL ORDER BY clause.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder orderBy(String? orderBy) {
    _orderBy = orderBy;
    return this;
  }

  /// Sets the LIMIT clause for the query.
  ///
  /// [limit] is the number of records to limit the query to.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder limit(int limit) {
    _limit = limit;
    return this;
  }

  /// Sets the OFFSET clause for the query.
  ///
  /// [offset] is the starting point for the query.
  /// Returns the updated instance of [SqlQueryBuilder].
  SqlQueryBuilder offset(int offset) {
    _offset = offset;
    return this;
  }

  /// Builds and returns the final SQL query string.
  ///
  /// This method constructs the SQL query string based on the provided
  /// clauses and returns it.
  ///
  /// Returns the constructed SQL query string.
  String build() {
    String columnsPart = _columns?.join(', ') ?? '*';
    String query = 'SELECT $columnsPart FROM $_tableName';

    if (_whereClause != null && _whereClause!.isNotEmpty) {
      query += ' WHERE $_whereClause';
    }

    if (_groupBy != null && _groupBy!.isNotEmpty) {
      query += ' GROUP BY $_groupBy';
    }

    if (_orderBy != null && _orderBy!.isNotEmpty) {
      query += ' ORDER BY $_orderBy';
    }

    if (_limit != null) {
      query += ' LIMIT $_limit';
    }

    if (_offset != null) {
      query += ' OFFSET $_offset';
    }

    return query;
  }
}
