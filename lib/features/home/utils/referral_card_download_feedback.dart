import 'package:flutter/widgets.dart';

import 'package:vcare_admin/core/services/firebase/firebase_notification_service.dart';
import 'package:vcare_admin/core/services/notifications/notification_route_payload.dart';
import 'package:vcare_admin/core/services/notifications/notification_router.dart';
import 'package:vcare_admin/features/home/domain/entities/referral_card_download_result.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Shows download completion feedback via system notification or in-app fallback.
class ReferralCardDownloadFeedback {
  ReferralCardDownloadFeedback._();

  static Future<void> showSuccess(
    BuildContext context, {
    required ReferralCardDownloadResult result,
  }) async {
    if (!result.success) {
      if (!context.mounted) return;
      context.showVcareToast(
        title: "Couldn't save referral card",
        description: 'Check photo library permissions and try again',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final payload = NotificationRoutePayload.referralCardDocument(
      fileName: result.fileName,
    );

    final notificationShown =
        await FirebaseNotificationService.instance.showDownloadNotification(
      title: 'Referral card saved',
      body: 'Tap to view in My Documents',
      payload: payload,
      notificationId: NotificationServiceConfig.referralCardDownloadNotificationId,
    );

    if (!context.mounted) return;

    if (notificationShown) {
      context.showVcareToast(
        title: 'Referral card saved',
        description: 'Saved to your gallery',
        variant: VcareToastVariant.success,
      );
      return;
    }

    context.showVcareToast(
      title: 'Referral card saved',
      description: 'Tap to open in My Documents',
      variant: VcareToastVariant.success,
      duration: const Duration(seconds: 6),
      onTap: () => NotificationRouter.openReferralCardDocument(
        context: context,
        fileName: result.fileName,
      ),
    );
  }
}
