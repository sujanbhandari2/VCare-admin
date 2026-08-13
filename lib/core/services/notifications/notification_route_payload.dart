/// Payload keys and helpers for local notification deep links.
class NotificationRoutePayload {
  NotificationRoutePayload._();

  static const routeKey = 'route';
  static const documentIdKey = 'documentId';
  static const documentSourceKey = 'documentSource';
  static const fileNameKey = 'fileName';
  static const openDocumentKey = 'openDocument';

  static const routeDocuments = 'documents';
  static const sourceCard = 'card';

  static Map<String, dynamic> referralCardDocument({
    String? documentId,
    String? fileName,
  }) {
    return {
      routeKey: routeDocuments,
      documentSourceKey: sourceCard,
      openDocumentKey: 'true',
      if (documentId != null && documentId.isNotEmpty) documentIdKey: documentId,
      if (fileName != null && fileName.isNotEmpty) fileNameKey: fileName,
    };
  }

  static bool isReferralCardDocumentsRoute(Map<String, dynamic> data) {
    return data[routeKey] == routeDocuments &&
        data[documentSourceKey] == sourceCard;
  }
}
