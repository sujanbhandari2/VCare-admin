/// An abstract class representing a base schema for a generic entity type [T].
///
/// This class provides the basic structure and operations for any schema
/// that will be used to interact with the database. Each derived class
/// should implement the necessary methods and properties based on the
/// specific requirements of the entity.
///
/// The type parameter [T] represents the entity class.
abstract class BaseSchema<T> {
  /// Creates a new instance of [BaseSchema].
  ///
  /// [id] is the optional identifier of the schema.
  BaseSchema({
    this.id,
  });

  /// The identifier of the schema.
  ///
  /// This property holds the primary key value for the schema.
  final int? id;

  /// Converts the schema to the corresponding model [T].
  ///
  /// This getter should be implemented to convert the schema instance
  /// into the corresponding model instance.
  T get toModel;

  /// Creates a copy of the current schema with optional new values.
  ///
  /// [id] is the optional new identifier for the schema.
  /// Returns a new instance of [BaseSchema] with the updated values.
  BaseSchema copy({
    int? id,
  });

  /// Converts the schema instance to a JSON object.
  ///
  /// Returns a map representing the schema instance in JSON format.
  Map<String, dynamic> toJson();
}
