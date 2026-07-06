import 'package:intl/intl.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';

const usStateCodes = <({String code, String name})>[
  (code: 'AL', name: 'Alabama'),
  (code: 'AK', name: 'Alaska'),
  (code: 'AZ', name: 'Arizona'),
  (code: 'AR', name: 'Arkansas'),
  (code: 'CA', name: 'California'),
  (code: 'CO', name: 'Colorado'),
  (code: 'CT', name: 'Connecticut'),
  (code: 'DE', name: 'Delaware'),
  (code: 'DC', name: 'District of Columbia'),
  (code: 'FL', name: 'Florida'),
  (code: 'GA', name: 'Georgia'),
  (code: 'HI', name: 'Hawaii'),
  (code: 'ID', name: 'Idaho'),
  (code: 'IL', name: 'Illinois'),
  (code: 'IN', name: 'Indiana'),
  (code: 'IA', name: 'Iowa'),
  (code: 'KS', name: 'Kansas'),
  (code: 'KY', name: 'Kentucky'),
  (code: 'LA', name: 'Louisiana'),
  (code: 'ME', name: 'Maine'),
  (code: 'MD', name: 'Maryland'),
  (code: 'MA', name: 'Massachusetts'),
  (code: 'MI', name: 'Michigan'),
  (code: 'MN', name: 'Minnesota'),
  (code: 'MS', name: 'Mississippi'),
  (code: 'MO', name: 'Missouri'),
  (code: 'MT', name: 'Montana'),
  (code: 'NE', name: 'Nebraska'),
  (code: 'NV', name: 'Nevada'),
  (code: 'NH', name: 'New Hampshire'),
  (code: 'NJ', name: 'New Jersey'),
  (code: 'NM', name: 'New Mexico'),
  (code: 'NY', name: 'New York'),
  (code: 'NC', name: 'North Carolina'),
  (code: 'ND', name: 'North Dakota'),
  (code: 'OH', name: 'Ohio'),
  (code: 'OK', name: 'Oklahoma'),
  (code: 'OR', name: 'Oregon'),
  (code: 'PA', name: 'Pennsylvania'),
  (code: 'RI', name: 'Rhode Island'),
  (code: 'SC', name: 'South Carolina'),
  (code: 'SD', name: 'South Dakota'),
  (code: 'TN', name: 'Tennessee'),
  (code: 'TX', name: 'Texas'),
  (code: 'UT', name: 'Utah'),
  (code: 'VT', name: 'Vermont'),
  (code: 'VA', name: 'Virginia'),
  (code: 'WA', name: 'Washington'),
  (code: 'WV', name: 'West Virginia'),
  (code: 'WI', name: 'Wisconsin'),
  (code: 'WY', name: 'Wyoming'),
  (code: 'AS', name: 'American Samoa'),
  (code: 'GU', name: 'Guam'),
  (code: 'MP', name: 'Northern Mariana Islands'),
  (code: 'PR', name: 'Puerto Rico'),
  (code: 'VI', name: 'U.S. Virgin Islands'),
];

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
  return state.length == 2 ? state.toUpperCase() : state;
}
