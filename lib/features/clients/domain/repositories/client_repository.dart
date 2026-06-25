import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class ClientRepository {
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>>
  fetchClients(PaginatedListRequest request, {CancelToken? cancelToken});

  Future<EitherResponseOrException<ClientDetail>> fetchClientDetail(
    String clientId, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<ClientMembershipsResult>>
  fetchClientMemberships(String clientId, {CancelToken? cancelToken});

  Future<EitherResponseOrException<List<ClientPaymentMethod>>>
  fetchPaymentMethods(String clientId, {CancelToken? cancelToken});

  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchTransactions(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<ClientCase>>> fetchCases(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ClientCase>> createClientCase({
    required String clientId,
    required String title,
    required String description,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<ClientFile>>> fetchDocuments(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> uploadClientDocument({
    required String clientId,
    required String fileName,
    required List<int> bytes,
    String? note,
    String? date,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> renameClientDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  });
}
