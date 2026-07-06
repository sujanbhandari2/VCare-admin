import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/features/find_care/data/models/cms_data_viewer_response_model.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';

/// Plain HTTP client for the public CMS Medicare data-viewer API.
/// Intentionally separate from [ApiClient] — no auth, no vCare interceptors.
class CmsMedicareApiClient {
  CmsMedicareApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 30),
              headers: const {'accept': 'application/json'},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  final Dio _dio;

  Future<CmsDataViewerResponseModel> fetchDataViewer(
    Map<String, String> queryParameters,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        cmsMedicareDataViewerBaseUrl,
        queryParameters: queryParameters,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw HttpException(
          title: 'CMS request failed',
          message: 'CMS request failed (${response.statusCode})',
        );
      }

      final data = response.data;
      if (data == null) {
        throw HttpException(
          title: 'CMS error',
          message: 'Unexpected CMS response',
        );
      }

      return CmsDataViewerResponseModel.fromJson(data);
    } on HttpException {
      rethrow;
    } on DioException catch (error) {
      throw HttpException.fromException(error);
    } catch (error) {
      throw HttpException.fromException(error);
    }
  }
}
