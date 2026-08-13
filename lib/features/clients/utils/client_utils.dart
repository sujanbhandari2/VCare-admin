import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';

String clientInitials(String fullName) => profileInitials(fullName);

String buildClientsSubtitle(
  int totalCount, {
  bool isLoading = false,
  ClientListType clientType = ClientListType.individual,
}) {
  if (isLoading) {
    return clientType == ClientListType.group
        ? 'Loading groups…'
        : 'Loading clients…';
  }
  if (clientType == ClientListType.group) {
    final label = totalCount == 1 ? 'group' : 'groups';
    return '$totalCount $label';
  }
  final label = totalCount == 1 ? 'client' : 'clients';
  return '$totalCount active $label';
}

String formatClientDate(String isoDate) => formatDisplayDateString(isoDate);

/// Date-only display for client detail and commission — `Aug 2, 1999`.
String formatClientDateNumeric(String isoDate) =>
    formatDisplayDateString(isoDate);

String clientPaymentMethodTypeLabel(ClientPaymentMethodType type) {
  switch (type) {
    case ClientPaymentMethodType.creditDebitCard:
      return 'Credit/Debit Card';
    case ClientPaymentMethodType.bankTransfer:
      return 'Bank Transfer';
    case ClientPaymentMethodType.cash:
      return 'Cash';
    case ClientPaymentMethodType.check:
      return 'Check';
    case ClientPaymentMethodType.others:
      return 'Others';
  }
}

String clientGenderLabel(ClientGender gender) {
  switch (gender) {
    case ClientGender.male:
      return 'Male';
    case ClientGender.female:
      return 'Female';
    case ClientGender.nonBinary:
      return 'Non-binary';
  }
}

/// Human-readable file size — parity with web client detail uploads.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Last four digits of current timestamp for local case IDs (CS-2401 style).
String shortCaseSequence() {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  return timestamp.substring(timestamp.length - 4);
}

String todayIsoDate() {
  return DateTime.now().toIso8601String().split('T').first;
}

/// Splits a file name into editable base name and preserved extension.
({String baseName, String extension}) splitDocumentFileName(String fileName) {
  final lastDot = fileName.lastIndexOf('.');
  if (lastDot <= 0 || lastDot == fileName.length - 1) {
    return (baseName: fileName, extension: '');
  }

  return (
    baseName: fileName.substring(0, lastDot),
    extension: fileName.substring(lastDot),
  );
}

String joinDocumentFileName({
  required String baseName,
  required String extension,
}) {
  final trimmed = baseName.trim();
  if (extension.isEmpty) return trimmed;
  return '$trimmed$extension';
}
