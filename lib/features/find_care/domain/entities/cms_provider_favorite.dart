import 'medicare_provider_lookup_row.dart';

class CmsProviderFavorite {
  const CmsProviderFavorite({
    required this.npi,
    required this.row,
    this.raw = const {},
  });

  final String npi;
  final MedicareProviderLookupRow row;
  final Map<String, String> raw;
}
