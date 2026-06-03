import 'package:dio/dio.dart';

import 'package:flutter_template/core/services/network/models/form_file.dart';

/// Canonical media types used by network request payloads.
abstract final class RequestMediaType {
  static const String json = 'application/json';
  static const String formUrlEncoded = 'application/x-www-form-urlencoded';
  static const String textPlainUtf8 = 'text/plain; charset=utf-8';
  static const String binary = 'application/octet-stream';
}

/// Base abstraction for request payloads. Each subtype controls its encoding.
sealed class RequestBody {
  const RequestBody();

  /// The explicit content type for this payload. Null means let Dio infer it.
  String? get contentType;

  /// Encodes this payload into a body accepted by Dio.
  Future<dynamic> encode();
}

/// JSON payload.
class JsonRequestBody extends RequestBody {
  const JsonRequestBody(this.data);

  final Map<String, dynamic> data;

  @override
  String get contentType => RequestMediaType.json;

  @override
  Future<dynamic> encode() async => data;
}

/// Empty body payload.
class EmptyRequestBody extends RequestBody {
  const EmptyRequestBody();

  @override
  String? get contentType => null;

  @override
  Future<dynamic> encode() async => null;
}

/// application/x-www-form-urlencoded payload.
class FormUrlEncodedRequestBody extends RequestBody {
  const FormUrlEncodedRequestBody(this.data);

  final Map<String, dynamic> data;

  @override
  String get contentType => RequestMediaType.formUrlEncoded;

  @override
  Future<dynamic> encode() async => data;
}

/// text/plain payload.
class TextRequestBody extends RequestBody {
  const TextRequestBody(
    this.text, {
    this.mediaType = RequestMediaType.textPlainUtf8,
  });

  final String text;
  final String mediaType;

  @override
  String get contentType => mediaType;

  @override
  Future<dynamic> encode() async => text;
}

/// Raw bytes payload.
class BinaryRequestBody extends RequestBody {
  const BinaryRequestBody(
    this.bytes, {
    this.mediaType = RequestMediaType.binary,
  });

  final List<int> bytes;
  final String mediaType;

  @override
  String get contentType => mediaType;

  @override
  Future<dynamic> encode() async => bytes;
}

/// Escape hatch payload for specialized use cases.
class RawRequestBody extends RequestBody {
  const RawRequestBody(this.value, {this.mediaType});

  final dynamic value;
  final String? mediaType;

  @override
  String? get contentType => mediaType;

  @override
  Future<dynamic> encode() async => value;
}

/// Multipart payload supporting both fields and files.
class MultipartFormData extends RequestBody {
  MultipartFormData({
    this.fields = const <String, dynamic>{},
    this.files = const <FormFile>[],
  });

  final Map<String, dynamic> fields;
  final List<FormFile> files;

  /// Only non-null values are included in request body.
  Map<String, dynamic> get nonNullFormFields {
    return {
      for (final entry in fields.entries)
        if (entry.value != null) entry.key: entry.value,
    };
  }

  @override
  String? get contentType => null;

  @override
  Future<dynamic> encode() async => toFormData;

  /// Converts to Dio FormData.
  Future<FormData> get toFormData async {
    final map = <String, dynamic>{...nonNullFormFields};

    for (final file in files) {
      map[file.key] = await file.toMultipartFile();
    }

    return FormData.fromMap(map);
  }

  /// Converts dynamic map values into strings.
  static Map<String, String> convertDynamicToStringMap(
    Map<String, dynamic> formFields,
  ) {
    final result = <String, String>{};
    formFields.forEach((key, value) {
      if (value != null) result[key] = value.toString();
    });
    return result;
  }
}
