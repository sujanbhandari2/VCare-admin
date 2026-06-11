import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/shell/data/shell_mock_data.dart';
import 'package:vcare_admin/features/vcare_sync/data/vcare_catalog.dart';

export 'package:vcare_admin/features/shell/data/shell_mock_data.dart'
    show ProviderCategoryItem;

const findCareCategoryPageSize = 15;

ProviderCategoryItem? findCareCategoryBySlug(String slug) {
  for (final category in ShellMockData.providerCategories) {
    if (category.slug == slug) return category;
  }
  return null;
}

String? parseSearchState(String locationText) {
  final trimmed = locationText.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(',');
  if (parts.length < 2) return null;
  final state = parts.last.trim();
  return state.length == 2 ? state.toUpperCase() : state;
}

String npiFromCatalogId(String id) {
  final hash = id.hashCode.abs() % 1000000000;
  return '1${hash.toString().padLeft(9, '0').substring(0, 9)}';
}

List<MedicareProviderListItem> searchCategoryProviders({
  required String slug,
  required String keyword,
  String? stateFilter,
}) {
  final needle = keyword.trim().toLowerCase();
  final matches = VCareCatalog.providers.where((provider) {
    if (provider.category != slug) return false;
    if (stateFilter != null &&
        stateFilter.isNotEmpty &&
        !provider.city.toUpperCase().contains(stateFilter.toUpperCase())) {
      return false;
    }
    if (needle.isEmpty) return true;
    return provider.name.toLowerCase().contains(needle) ||
        provider.specialty.toLowerCase().contains(needle) ||
        provider.address.toLowerCase().contains(needle);
  });

  return matches.map(_catalogToMedicareItem).toList();
}

MedicareProviderListItem _catalogToMedicareItem(VCareProvider provider) {
  final nameParts = provider.name.split(',').first.trim().split(' ');
  final lastName = nameParts.length > 1 ? nameParts.last : '';
  final firstName = nameParts.length > 1
      ? nameParts.sublist(0, nameParts.length - 1).join(' ')
      : provider.name;

  final cityParts = provider.city.split(',');
  final city = cityParts.first.trim();
  final stateZip = cityParts.length > 1 ? cityParts[1].trim() : '';
  final stateZipParts = stateZip.split(' ');
  final state = stateZipParts.isNotEmpty ? stateZipParts.first : 'CA';
  final zip5 = stateZipParts.length > 1 ? stateZipParts[1] : '94102';

  final npi = npiFromCatalogId(provider.id);

  return MedicareProviderListItem(
    row: MedicareProviderLookupRow(
      npi: npi,
      firstName: firstName,
      lastName: lastName,
      providerType: provider.specialty,
      street1: provider.address,
      city: city,
      state: state,
      zip5: zip5,
    ),
    raw: {
      'NPI': npi,
      'Provider Type': provider.specialty,
      'City': city,
      'State': state,
    },
  );
}
