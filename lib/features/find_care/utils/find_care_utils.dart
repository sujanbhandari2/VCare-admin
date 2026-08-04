import 'package:intl/intl.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/shared/utils/us_states.dart';

export 'package:vcare_admin/shared/utils/us_states.dart'
    show usStateCodes, normalizeUsStateCode;

String normalizeNpi(String npi) => npi.replaceAll(RegExp(r'\D'), '');

String formatCmsServiceValue(Map<String, String> row, String key) {
  final value = row[key]?.trim();
  return value == null || value.isEmpty ? '—' : value;
}

String formatCmsMoney(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  final amount = double.tryParse(value.replaceAll(',', ''));
  if (amount == null) return value;
  return NumberFormat.simpleCurrency(decimalDigits: 2).format(amount);
}

List<MedicareProviderListItem> dedupeMedicareProviderItems(
  List<MedicareProviderListItem> items,
) {
  final seen = <String>{};
  final deduped = <MedicareProviderListItem>[];
  for (final item in items) {
    if (seen.contains(item.row.npi)) continue;
    seen.add(item.row.npi);
    deduped.add(item);
  }
  return deduped;
}

List<MedicareProviderListItem> mergeMedicareProviderItems({
  required List<MedicareProviderListItem> existing,
  required List<MedicareProviderListItem> incoming,
}) {
  return dedupeMedicareProviderItems([...existing, ...incoming]);
}

String? parseSearchState(String locationText) {
  final trimmed = locationText.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(',');
  if (parts.length < 2) return null;
  final state = parts.last.trim();
  return normalizeUsStateCode(state) ??
      (state.length == 2 ? state.toUpperCase() : state);
}

/// Builds a [SearchLocation] city/state pair from reverse-geocode placemark fields.
SearchLocation? searchLocationFromAddressParts({
  String? locality,
  String? subAdministrativeArea,
  String? subLocality,
  String? administrativeArea,
  bool fromCurrentLocation = false,
}) {
  final cityCandidates = [locality, subAdministrativeArea, subLocality];
  String city = '';
  for (final candidate in cityCandidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) {
      city = value;
      break;
    }
  }

  final state = normalizeUsStateCode(administrativeArea) ?? '';
  if (city.isEmpty && state.isEmpty) return null;
  return SearchLocation(
    city: city,
    state: state,
    fromCurrentLocation: fromCurrentLocation,
  );
}

/// Builds a [SearchLocation] from the user's profile primary city/state.
SearchLocation searchLocationFromProfile({
  String? primaryCity,
  String? primaryState,
}) {
  final city = primaryCity?.trim() ?? '';
  final rawState = primaryState?.trim() ?? '';
  final state = normalizeUsStateCode(rawState) ?? rawState;
  return SearchLocation(city: city, state: state);
}
