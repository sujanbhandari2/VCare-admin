import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/add_client_payment_method_request.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/clients/domain/repositories/client_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

class FakeClientRepository implements ClientRepository {
  EitherResponseOrException<PaginatedResult<ClientListItem>>
  fetchClientsResult = Success(
    PaginatedResult(
      items: const [
        ClientListItem(
          id: 'client-1',
          fullName: 'Aspen Michael',
          email: 'test@example.com',
          phone: '+11111111111',
          location: 'City, ST',
          avatarUrl: '',
        ),
      ],
      pagination: const PaginationMeta(
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
        hasNext: false,
        hasPrev: false,
      ),
    ),
  );

  EitherResponseOrException<ClientDetail> fetchDetailResult = Success(
    const ClientDetail(
      id: 'client-1',
      fullName: 'Aspen Michael',
      email: 'test@example.com',
      phone: '+11111111111',
      avatarUrl: '',
      dob: '2026-06-03T00:00:00.000Z',
      location: 'City, ST',
      gender: ClientGender.male,
      ssn: '***-**-2342',
      status: 'INACTIVE',
      allowTextNotification: false,
    ),
  );

  EitherResponseOrException<ClientMembershipsResult> fetchMembershipsResult =
      Success(
        const ClientMembershipsResult(
          clientId: 'client-1',
          memberships: [],
          totalGroup: 0,
        ),
      );

  EitherResponseOrException<PaginatedResult<ClientDependent>>
  fetchDependentsResult = Success(
    PaginatedResult(items: const [], pagination: PaginationMeta.empty),
  );

  EitherResponseOrException<List<ClientPaymentMethod>>
  fetchPaymentMethodsResult = Success(const []);

  EitherResponseOrException<ClientPaymentMethod> addPaymentMethodResult =
      Success(
        const ClientPaymentMethod(
          id: 'pm-new',
          type: ClientPaymentMethodType.cash,
          label: 'Cash',
        ),
      );

  EitherResponseOrException<ClientPaymentMethod> setPrimaryPaymentMethodResult =
      Success(
        const ClientPaymentMethod(
          id: 'pm-1',
          type: ClientPaymentMethodType.cash,
          label: 'Cash',
          isPrimary: true,
        ),
      );

  EitherResponseOrException<void> removePaymentMethodResult = const Success(
    null,
  );

  EitherResponseOrException<PaginatedResult<ClientTransaction>>
  fetchTransactionsResult = Success(
    PaginatedResult(items: const [], pagination: PaginationMeta.empty),
  );

  EitherResponseOrException<void> chargeTransactionResult = const Success(null);

  EitherResponseOrException<PaginatedResult<ClientCase>> fetchCasesResult =
      Success(
        PaginatedResult(items: const [], pagination: PaginationMeta.empty),
      );

  EitherResponseOrException<PaginatedResult<ClientFile>> fetchDocumentsResult =
      Success(
        PaginatedResult(items: const [], pagination: PaginationMeta.empty),
      );

  EitherResponseOrException<void> uploadClientDocumentResult = const Success(
    null,
  );

  EitherResponseOrException<void> renameClientDocumentResult = const Success(
    null,
  );

  EitherResponseOrException<void> deleteClientDocumentResult = const Success(
    null,
  );

  EitherResponseOrException<ClientCase> createClientCaseResult = Success(
    const ClientCase(
      id: 'case-new',
      caseId: 'CASENEW',
      title: 'New case',
      status: ClientCaseStatus.requested,
      createdAt: '2026-06-25T11:29:06.803Z',
      updatedAt: '2026-06-25T11:29:06.803Z',
    ),
  );

  String? lastUploadClientId;
  String? lastUploadFileName;
  List<int>? lastUploadBytes;
  String? lastUploadDocumentType;
  String? lastUploadNote;
  String? lastUploadDate;

  String? lastRenameDocumentId;
  String? lastRenameName;
  String? lastDeleteDocumentId;

  String? lastCreateCaseClientId;
  String? lastCreateCaseTitle;
  String? lastCreateCaseDescription;

  ClientsListRequest? lastClientsRequest;
  bool? lastClientsForceRefresh;
  Future<void>? fetchClientsPage2Delay;
  String? lastClientId;
  ClientListType? lastClientType;
  PaginatedListRequest? lastTransactionsRequest;
  PaginatedListRequest? lastCasesRequest;
  bool? lastCasesForceRefresh;
  PaginatedListRequest? lastDocumentsRequest;
  bool? lastDocumentsForceRefresh;
  bool? lastDetailForceRefresh;
  bool? lastMembershipsForceRefresh;
  bool? lastDependentsForceRefresh;
  PaginatedListRequest? lastDependentsRequest;
  bool? lastPaymentMethodsForceRefresh;
  Future<void>? fetchPaymentMethodsDelay;
  bool? lastTransactionsForceRefresh;
  String? lastChargeTransactionId;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>>
  fetchClients(
    ClientsListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientsRequest = request;
    lastClientsForceRefresh = forceRefresh;

    if (request.page > 1 && fetchClientsPage2Delay != null) {
      await fetchClientsPage2Delay;
    }

    if (request.page > 1) {
      return Success(
        PaginatedResult(
          items: const [
            ClientListItem(
              id: 'client-2',
              fullName: 'Page 2 Client',
              email: 'p2@example.com',
              phone: '+12222222222',
              location: 'A, B',
              avatarUrl: '',
            ),
          ],
          pagination: const PaginationMeta(
            page: 2,
            limit: 20,
            total: 2,
            totalPages: 1,
            hasNext: false,
            hasPrev: true,
          ),
        ),
      );
    }

    return fetchClientsResult;
  }

  @override
  Future<EitherResponseOrException<ClientDetail>> fetchClientDetail(
    String clientId, {
    ClientListType clientType = ClientListType.individual,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastClientType = clientType;
    lastDetailForceRefresh = forceRefresh;
    return fetchDetailResult;
  }

  @override
  Future<EitherResponseOrException<ClientMembershipsResult>>
  fetchClientMemberships(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastMembershipsForceRefresh = forceRefresh;
    return fetchMembershipsResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientDependent>>>
  fetchDependents(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastDependentsRequest = request;
    lastDependentsForceRefresh = forceRefresh;
    return fetchDependentsResult;
  }

  @override
  Future<EitherResponseOrException<List<ClientPaymentMethod>>>
  fetchPaymentMethods(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastPaymentMethodsForceRefresh = forceRefresh;

    if (fetchPaymentMethodsDelay != null) {
      await fetchPaymentMethodsDelay;
    }

    return fetchPaymentMethodsResult;
  }

  @override
  Future<EitherResponseOrException<ClientPaymentMethod>> addPaymentMethod({
    required String clientId,
    required AddClientPaymentMethodRequest request,
    CancelToken? cancelToken,
  }) async {
    lastClientId = clientId;
    return addPaymentMethodResult;
  }

  @override
  Future<EitherResponseOrException<ClientPaymentMethod>>
  setPrimaryPaymentMethod({
    required String clientId,
    required String paymentMethodId,
    CancelToken? cancelToken,
  }) async {
    lastClientId = clientId;
    return setPrimaryPaymentMethodResult;
  }

  @override
  Future<EitherResponseOrException<void>> removePaymentMethod({
    required String clientId,
    required String paymentMethodId,
    CancelToken? cancelToken,
  }) async {
    lastClientId = clientId;
    return removePaymentMethodResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchTransactions(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastTransactionsRequest = request;
    lastTransactionsForceRefresh = forceRefresh;
    return fetchTransactionsResult;
  }

  @override
  Future<EitherResponseOrException<void>> chargeTransaction({
    required String transactionId,
    CancelToken? cancelToken,
  }) async {
    lastChargeTransactionId = transactionId;
    return chargeTransactionResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientCase>>> fetchCases(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastCasesRequest = request;
    lastCasesForceRefresh = forceRefresh;
    return fetchCasesResult;
  }

  @override
  Future<EitherResponseOrException<ClientCase>> createClientCase({
    required String clientId,
    required String title,
    required String description,
    CancelToken? cancelToken,
  }) async {
    lastCreateCaseClientId = clientId;
    lastCreateCaseTitle = title;
    lastCreateCaseDescription = description;
    return createClientCaseResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientFile>>> fetchDocuments(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastClientId = clientId;
    lastDocumentsRequest = request;
    lastDocumentsForceRefresh = forceRefresh;
    return fetchDocumentsResult;
  }

  @override
  Future<EitherResponseOrException<void>> uploadClientDocument({
    required String clientId,
    required String fileName,
    required List<int> bytes,
    required String documentType,
    String? note,
    String? date,
    CancelToken? cancelToken,
  }) async {
    lastUploadClientId = clientId;
    lastUploadFileName = fileName;
    lastUploadBytes = bytes;
    lastUploadDocumentType = documentType;
    lastUploadNote = note;
    lastUploadDate = date;
    return uploadClientDocumentResult;
  }

  @override
  Future<EitherResponseOrException<void>> renameClientDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  }) async {
    lastRenameDocumentId = documentId;
    lastRenameName = name;
    return renameClientDocumentResult;
  }

  @override
  Future<EitherResponseOrException<void>> deleteClientDocument({
    required String documentId,
    CancelToken? cancelToken,
  }) async {
    lastDeleteDocumentId = documentId;
    return deleteClientDocumentResult;
  }
}
