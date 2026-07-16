import 'dart:convert';
import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';

/// Model for the response returned from HTTP Cache.
///
/// This class represents the cached response from an HTTP request, including
/// the data, age of the cache, status code, and headers. It also provides
/// methods to validate the cache, convert the response to JSON, and build a
/// Dio response.
class CachedResponse {
  /// Creates an instance of [CachedResponse].
  ///
  /// [data] - The actual data returned in the cached response.
  /// [age] - The timestamp when the response was cached.
  /// [statusCode] - The HTTP status code of the cached response.
  /// [headers] - The headers of the cached HTTP response.
  CachedResponse({
    required this.data,
    required this.age,
    required this.statusCode,
    required this.headers,
  });

  /// The data inside the cached response.
  ///
  /// This represents the body of the cached HTTP response.
  final dynamic data;

  /// The age of the cached response.
  ///
  /// This timestamp is used to determine whether the cached response is
  /// still valid based on the maximum cache age configuration.
  final DateTime age;

  /// The HTTP status code of the cached HTTP response.
  ///
  /// This indicates the HTTP status of the original response (e.g., 200 for success).
  final int statusCode;

  /// The cached HTTP response headers.
  ///
  /// This contains the headers associated with the cached response.
  final Headers headers;

  /// True when cached response has successful status code.
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Determines if the cached response is still valid.
  ///
  /// The cached response is considered valid if the cache age is within the
  /// maximum allowed cache age as configured in [Configuration.of().maxCacheAge].
  ///
  /// Returns `true` if the cache is still valid, otherwise `false`.
  bool get isValid =>
      clock.now().isBefore(age.add(Configuration.of().maxCacheAge));

  /// Creates an instance of [CachedResponse] parsed from raw JSON data.
  ///
  /// [data] - The raw JSON data representing the cached response.
  ///
  /// The method parses the response data and returns an instance of [CachedResponse].
  factory CachedResponse.fromJson(Map<String, dynamic> data) {
    final rawAge = data['age'];
    final parsedAge = rawAge is String
        ? DateTime.tryParse(rawAge)
        : rawAge is int
        ? DateTime.fromMillisecondsSinceEpoch(rawAge)
        : null;

    return CachedResponse(
      data: data['data'],
      age: parsedAge ?? DateTime.fromMillisecondsSinceEpoch(0),
      statusCode: data['statusCode'] is int
          ? data['statusCode'] as int
          : int.tryParse('${data['statusCode']}') ?? 0,
      headers: _parseHeaders(data['headers']),
    );
  }

  /// Converts the cached response data to a JSON map.
  ///
  /// This method serializes the data, age, status code, and headers into a
  /// JSON-compatible map format.
  ///
  /// Returns a [Map<String, dynamic>] representation of the cached response.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data,
      'age': age.toIso8601String(),
      'ageEpochMs': age.millisecondsSinceEpoch,
      'statusCode': statusCode,
      'headers': headers.map,
    };
  }

  /// Builds a Dio response from a [RequestOptions] object.
  ///
  /// [options] - The request options used to construct the Dio response.
  ///
  /// Returns a [Response<dynamic>] constructed from the cached response data,
  /// headers, and status code.
  Response<dynamic> buildResponse(RequestOptions options) {
    return Response<dynamic>(
      data: data,
      headers: headers,
      requestOptions: options.copyWith(extra: options.extra),
      statusCode: statusCode,
    );
  }

  /// Helper function to parse HTTP headers from raw data.
  ///
  /// [rawHeaders] - The raw headers data, typically from a JSON source.
  ///
  /// Returns a [Headers] object parsed from the raw data.
  static Headers _parseHeaders(dynamic rawHeaders) {
    if (rawHeaders is! Map) {
      return Headers.fromMap(const <String, List<String>>{});
    }
    final decodedMap = json.decode(json.encode(rawHeaders));
    if (decodedMap is! Map) {
      return Headers.fromMap(const <String, List<String>>{});
    }
    final Map<String, List<dynamic>> decodedHeaders =
        Map<String, List<dynamic>>.from(decodedMap);

    return Headers.fromMap(
      decodedHeaders.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }
}
