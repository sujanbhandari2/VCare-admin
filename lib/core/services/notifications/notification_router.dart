import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/services/notifications/notification_route_payload.dart';

/// Navigates to in-app destinations from notification payloads.
class NotificationRouter {
  NotificationRouter._();

  static void navigateFromPayload(Map<String, dynamic> data) {
    if (NotificationRoutePayload.isReferralCardDocumentsRoute(data)) {
      openReferralCardDocument(
        documentId: _stringValue(data[NotificationRoutePayload.documentIdKey]),
        fileName: _stringValue(data[NotificationRoutePayload.fileNameKey]),
      );
      return;
    }

    final route = _stringValue(data[NotificationRoutePayload.routeKey]);
    if (route == NotificationRoutePayload.routeDocuments) {
      openReferralCardDocument(
        documentId: _stringValue(data[NotificationRoutePayload.documentIdKey]),
        fileName: _stringValue(data[NotificationRoutePayload.fileNameKey]),
      );
    }
  }

  static void openReferralCardDocument({
    BuildContext? context,
    String? documentId,
    String? fileName,
  }) {
    final navigatorContext =
        context ?? AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    navigatorContext.pushNamed(
      AppRouter.documentsName,
      queryParameters: {
        NotificationRoutePayload.documentSourceKey:
            NotificationRoutePayload.sourceCard,
        NotificationRoutePayload.openDocumentKey: 'true',
        if (documentId != null && documentId.isNotEmpty)
          NotificationRoutePayload.documentIdKey: documentId,
        if (fileName != null && fileName.isNotEmpty)
          NotificationRoutePayload.fileNameKey: fileName,
      },
    );
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
