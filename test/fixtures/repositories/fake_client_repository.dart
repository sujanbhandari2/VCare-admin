import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_detail.dart';
import 'package:vcare_admin/features/clients/domain/entities/client_memberships_result.dart';
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
          dependents: [],
          totalGroup: 0,
        ),
      );

  EitherResponseOrException<List<ClientPaymentMethod>>
  fetchPaymentMethodsResult = Success(const []);

  EitherResponseOrException<PaginatedResult<ClientTransaction>>
  fetchTransactionsResult = Success(
    PaginatedResult(items: const [], pagination: PaginationMeta.empty),
  );

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
  String? lastUploadNote;
  String? lastUploadDate;

  String? lastRenameDocumentId;
  String? lastRenameName;

  String? lastCreateCaseClientId;
  String? lastCreateCaseTitle;
  String? lastCreateCaseDescription;

  PaginatedListRequest? lastClientsRequest;
  String? lastClientId;
  PaginatedListRequest? lastTransactionsRequest;
  PaginatedListRequest? lastCasesRequest;
  bool? lastCasesForceRefresh;
  PaginatedListRequest? lastDocumentsRequest;
  bool? lastDocumentsForceRefresh;

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientListItem>>>
  fetchClients(PaginatedListRequest request, {CancelToken? cancelToken}) async {
    lastClientsRequest = request;

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
    CancelToken? cancelToken,
  }) async {
    lastClientId = clientId;
    return fetchDetailResult;
  }

  @override
  Future<EitherResponseOrException<ClientMembershipsResult>>
  fetchClientMemberships(String clientId, {CancelToken? cancelToken}) async {
    lastClientId = clientId;
    return fetchMembershipsResult;
  }

  @override
  Future<EitherResponseOrException<List<ClientPaymentMethod>>>
  fetchPaymentMethods(String clientId, {CancelToken? cancelToken}) async {
    lastClientId = clientId;
    return fetchPaymentMethodsResult;
  }

  @override
  Future<EitherResponseOrException<PaginatedResult<ClientTransaction>>>
  fetchTransactions(
    String clientId,
    PaginatedListRequest request, {
    CancelToken? cancelToken,
  }) async {
    lastClientId = clientId;
    lastTransactionsRequest = request;
    return fetchTransactionsResult;
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
    String? note,
    String? date,
    CancelToken? cancelToken,
  }) async {
    lastUploadClientId = clientId;
    lastUploadFileName = fileName;
    lastUploadBytes = bytes;
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
}
