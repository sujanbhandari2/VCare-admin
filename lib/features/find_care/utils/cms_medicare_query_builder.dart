/// CMS Medicare Physician & Other Practitioners — query builders.
/// Ported from web `cms-medicare-providers-api.ts`.
library;

const cmsMedicarePhysicianDatasetId = 'e4a25bed-8a57-40e6-ab2b-a952c95619d8';

const cmsMedicareDataViewerBaseUrl =
    'https://data.cms.gov/data-api/v1/dataset/$cmsMedicarePhysicianDatasetId/data-viewer';

const findCareCategoryPageSize = 15;
const medicareLookupPageSize = 15;
const cmsProviderServicesPageSize = 50;

/// CONTAINS substring on CMS `Rndrng_Prvdr_Type` per app browse category.
const cmsProviderTypeContainsByCategory = <String, String>{
  'pediatrics': 'Pediatric',
  'womens-health': 'Gynecology',
  'urgent-care': 'Clinic',
  'er': 'Emergency',
  'specialist': 'Medicine',
  'mental-health': 'Psychiat',
  'hearing': 'Audiolog',
  'physical-therapy': 'Physical',
  'sleep-medicine': 'Sleep',
  'home-health': 'Home',
};

void _appendContains(
  Map<String, String> params,
  String filterKey,
  String column,
  String value,
) {
  params['filter[$filterKey][condition][path]'] = column;
  params['filter[$filterKey][condition][operator]'] = 'CONTAINS';
  params['filter[$filterKey][condition][value]'] = value;
}

/// CMS data-viewer query: at least one of first name, last name, or provider type.
Map<String, String> buildMedicareDirectorySearchQuery({
  String? firstName,
  String? lastName,
  String? providerTypeContains,
  String? state,
  required int size,
  required int offset,
}) {
  final fn = firstName?.trim();
  final ln = lastName?.trim();
  final pt = providerTypeContains?.trim();
  if ((fn == null || fn.isEmpty) &&
      (ln == null || ln.isEmpty) &&
      (pt == null || pt.isEmpty)) {
    throw ArgumentError(
      'CMS directory search needs a name and/or provider type filter.',
    );
  }

  final params = <String, String>{};
  if (fn != null && fn.isNotEmpty) {
    _appendContains(params, 'firstName', 'Rndrng_Prvdr_First_Name', fn);
  }
  if (ln != null && ln.isNotEmpty) {
    _appendContains(params, 'lastName', 'Rndrng_Prvdr_Last_Org_Name', ln);
  }
  if (pt != null && pt.isNotEmpty) {
    _appendContains(params, 'ptype', 'Rndrng_Prvdr_Type', pt);
  }

  final st = state?.trim().toUpperCase();
  if (st != null && st.isNotEmpty) {
    params['filter[state][condition][path]'] = 'Rndrng_Prvdr_State_Abrvtn';
    params['filter[state][condition][operator]'] = '=';
    params['filter[state][condition][value]'] = st;
  }

  params['size'] = size.toString();
  params['offset'] = offset.toString();
  params['sort'] =
      'Rndrng_Prvdr_Last_Org_Name,Rndrng_Prvdr_First_Name,Rndrng_Prvdr_State_Abrvtn';
  params['_table'] = 'lookup';

  return params;
}

/// One word → last/org name; two or more → first token + remainder as last/org.
({String? firstName, String? lastName}) parseMedicareNameSearchInput(
  String raw,
) {
  final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return (firstName: null, lastName: null);
  final parts = s.split(' ');
  if (parts.length == 1) return (firstName: null, lastName: parts.first);
  return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
}

Map<String, String> buildMedicareProviderSearchQuery({
  required String firstName,
  required String lastName,
  String? providerTypeContains,
  String? state,
  required int size,
  required int offset,
}) {
  return buildMedicareDirectorySearchQuery(
    firstName: firstName.trim().isEmpty ? null : firstName.trim(),
    lastName: lastName.trim().isEmpty ? null : lastName.trim(),
    providerTypeContains: providerTypeContains?.trim(),
    state: state,
    size: size,
    offset: offset,
  );
}

Map<String, String> buildMedicareProviderNpiQuery(String npi) {
  final digits = npi.replaceAll(RegExp(r'\D'), '');
  return {
    'filter[npi][condition][path]': 'Rndrng_NPI',
    'filter[npi][condition][operator]': '=',
    'filter[npi][condition][value]': digits,
    'size': '5',
    'offset': '0',
    '_table': 'lookup',
  };
}

Map<String, String> buildMedicareProviderServicesQuery(
  String npi,
  int size,
  int offset,
) {
  final digits = npi.replaceAll(RegExp(r'\D'), '');
  return {
    'filter[provider][condition][path]': 'Rndrng_NPI',
    'filter[provider][condition][operator]': '=',
    'filter[provider][condition][value]': digits,
    'size': size.toString(),
    'offset': offset.toString(),
  };
}
