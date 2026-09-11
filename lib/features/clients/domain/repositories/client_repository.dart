import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/add_client_payment_method_request.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class ClientRepository {
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>>
  fetchClients(
    ClientsListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ClientDetail>> fetchClientDetail(
    String clientId, {
    ClientListType clientType = ClientListType.individual,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ClientMembershipsResult>>
  fetchClientMemberships(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<PaginatedResult<ClientDependent>>>
  fetchDependents(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<List<ClientPaymentMethod>>>
  fetchPaymentMethods(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<ClientPaymentMethod>> addPaymentMethod({
    required String clientId,
    required AddClientPaymentMethodRequest request,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<ClientPaymentMethod>>
  setPrimaryPaymentMethod({
    required String clientId,
    required String paymentMethodId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> removePaymentMethod({
    required String clientId,
    required String paymentMethodId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchTransactions(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> chargeTransaction({
    required String transactionId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<PaginatedResult<ClientCase>>> fetchCases(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
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
    required String documentType,
    String? note,
    String? date,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> renameClientDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteClientDocument({
    required String documentId,
    CancelToken? cancelToken,
  });
}
