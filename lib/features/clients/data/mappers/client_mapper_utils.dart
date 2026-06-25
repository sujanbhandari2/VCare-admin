import 'package:vcare_admin/features/clients/data/models/client_shared_models.dart';

String joinClientName({
  String? firstName,
  String? middleName,
  String? lastName,
}) {
  return [
    firstName,
    middleName,
    lastName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
}

String joinClientNameFromModel(ClientNameModel? name) {
  if (name == null) return '';
  return joinClientName(
    firstName: name.firstName,
    middleName: name.middleName,
    lastName: name.lastName,
  );
}

String formatClientLocation(ClientAddressModel? address) {
  if (address == null) return '';

  final city = address.city?.trim();
  final state = address.state?.trim();

  if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
    return '$city, $state';
  }

  return city ?? state ?? '';
}

String formatClientSsn(String? last4) {
  final value = last4?.trim();
  if (value == null || value.isEmpty) return '—';
  return '***-**-$value';
}

double parseAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  return double.tryParse(value) ?? 0;
}

String humanizeApiEnum(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  return value
      .toLowerCase()
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String shortCaseId(String id) {
  final normalized = id.replaceAll('-', '').toUpperCase();
  if (normalized.length <= 8) return normalized;
  return normalized.substring(0, 8);
}

String resolveClientDocumentUrl(String url, String hostBaseUrl) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
    return trimmed;
  }

  final root = hostBaseUrl.endsWith('/') ? hostBaseUrl : '$hostBaseUrl/';
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${root}api/$path';
}

String mimeTypeFromFileName(String? fileName) {
  final name = fileName?.trim().toLowerCase();
  if (name == null || name.isEmpty) return 'application/octet-stream';

  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.gif')) return 'image/gif';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.bmp')) return 'image/bmp';
  if (name.endsWith('.svg')) return 'image/svg+xml';
  if (name.endsWith('.pdf')) return 'application/pdf';
  if (name.endsWith('.doc')) return 'application/msword';
  if (name.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (name.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (name.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (name.endsWith('.txt')) return 'text/plain';
  if (name.endsWith('.csv')) return 'text/csv';
  if (name.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
  if (name.endsWith('.pptx')) {
    return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  }
  if (name.endsWith('.rtf')) return 'application/rtf';
  if (name.endsWith('.heic')) return 'image/heic';

  return 'application/octet-stream';
}
