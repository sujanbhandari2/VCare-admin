import 'medicare_provider_lookup_row.dart';
import 'medicare_provider_service_line.dart';

class MedicareProviderLookupResult {
  const MedicareProviderLookupResult({
    required this.items,
    required this.headers,
  });

  final List<MedicareProviderListItem> items;
  final List<String> headers;
}

class MedicareProviderServicesResult {
  const MedicareProviderServicesResult({
    required this.serviceLines,
    required this.headers,
  });

  final List<MedicareProviderServiceLine> serviceLines;
  final List<String> headers;
}

class MedicareProviderByNpiResult {
  const MedicareProviderByNpiResult({this.item, required this.headers});

  final MedicareProviderListItem? item;
  final List<String> headers;
}
