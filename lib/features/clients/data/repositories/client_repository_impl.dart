import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_case_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_detail_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_document_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_list_item_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_membership_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_payment_method_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_transaction_mapper.dart';
import 'package:vcare_admin/features/clients/data/models/client_case_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_detail_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_document_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_list_item_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_membership_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_payment_method_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_transaction_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/features/clients/domain/repositories/client_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class ClientRepositoryImpl implements ClientRepository {
  const ClientRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>>
  fetchClients(PaginatedListRequest request, {CancelToken? cancelToken}) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClients,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => ClientListItemModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );

      return parsed;
    });
  }

  @override
  Future<EitherResponseOrException<ClientDetail>> fetchClientDetail(
    String clientId, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClient(clientId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ClientDetailModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map && data['profile'] is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<ClientMembershipsResult>>
  fetchClientMemberships(String clientId, {CancelToken? cancelToken}) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClientMemberships(clientId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) =>
            ClientMembershipsResultModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map && data['details'] is List,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<List<ClientPaymentMethod>>>
  fetchPaymentMethods(String clientId, {CancelToken? cancelToken}) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClientPaymentMethods(clientId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final methods = ResponseValidator.parse(response, (data) {
        if (data is! List) return <ClientPaymentMethod>[];
        return data
            .whereType<Map>()
            .map(
              (item) => ClientPaymentMethodModel.fromJson(
                Map<String, dynamic>.from(item),
              ).toEntity(),
            )
            .toList();
      }, dataValidator: (data) => data is List);

      return methods;
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchTransactions(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClientTransactions(clientId),
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => ClientTransactionModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );

      return parsed;
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientCase>>> fetchCases(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agentClientCases(clientId),
        queryParameters: {
          ...request.toQueryParameters(),
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => ClientCaseModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );

      return parsed;
    });
  }

  @override
  Future<EitherResponseOrException<ClientCase>> createClientCase({
    required String clientId,
    required String title,
    required String description,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.agentClientCases(clientId),
        JsonRequestBody({
          'title': title,
          'description': description,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => ClientCaseModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map && data['id'] != null,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientFile>>> fetchDocuments(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final hostBaseUrl = Configuration.of().baseUrl;

      final response = await apiClient.get(
        ApiEndpoints.agentClientDocuments(clientId),
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => ClientDocumentModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(hostBaseUrl: hostBaseUrl),
      );

      return parsed;
    });
  }

  @override
  Future<EitherResponseOrException<void>> uploadClientDocument({
    required String clientId,
    required String fileName,
    required List<int> bytes,
    String? note,
    String? date,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          fields: {
            'category': 'CLIENT',
            'categoryReferenceId': clientId,
            if (note != null) 'note': note,
            if (date != null) 'date': date,
          },
          files: [
            FormFile.fromBytes(
              fieldName: 'files',
              bytes: bytes,
              fileName: fileName,
            ),
          ],
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<void>> renameClientDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.file(documentId),
        JsonRequestBody({'name': name}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }
}
