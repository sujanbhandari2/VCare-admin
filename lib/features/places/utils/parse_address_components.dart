import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/shared/utils/us_states.dart';

String normalizeZip(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 5) return digits;
  return digits.substring(0, 5);
}

String formatPrimaryLocation(String city, String state) {
  final c = city.trim();
  final s = toFullStateName(state);
  final stateText = s.isNotEmpty ? s : state.trim();
  if (c.isEmpty) return '';
  if (stateText.isEmpty) return c;
  return '$c, $stateText';
}

({String city, String state}) parsePrimaryLocationInput(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return (city: '', state: '');

  final parts = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  while (parts.isNotEmpty &&
      RegExp(r'^(USA|United States)$', caseSensitive: false)
          .hasMatch(parts.last)) {
    parts.removeLast();
  }

  if (parts.length >= 2) {
    final city = parts.first;
    final stateToken = parts.sublist(1).join(' ');
    final full = toFullStateName(stateToken);
    return (city: city, state: full.isNotEmpty ? full : stateToken);
  }

  final match = RegExp(r'^(.*)\s+([A-Za-z]{2})$').firstMatch(raw);
  if (match != null) {
    final city = match.group(1)!.trim();
    final code = match.group(2)!;
    final full = toFullStateName(code);
    return (
      city: city,
      state: full.isNotEmpty ? full : code.toUpperCase(),
    );
  }

  return (city: raw, state: '');
}

PlaceAddressComponent? findComponent(
  List<PlaceAddressComponent> components,
  String type,
) {
  for (final component in components) {
    if (component.types.contains(type)) return component;
  }
  return null;
}

String readLongText(
  List<PlaceAddressComponent> components,
  List<String> types,
) {
  for (final type in types) {
    final component = findComponent(components, type);
    if (component != null && component.longText.isNotEmpty) {
      return component.longText;
    }
  }
  return '';
}

String readStateName(List<PlaceAddressComponent> components) {
  final component = findComponent(components, 'administrative_area_level_1');
  if (component == null) return '';
  final token = component.longText.isNotEmpty
      ? component.longText
      : component.shortText;
  return toFullStateName(token);
}

({String city, String state}) parseCityStateFromPlace(PlaceDetails details) {
  final components = details.addressComponents;
  final city = readLongText(components, const [
    'locality',
    'postal_town',
    'sublocality',
  ]);
  final state = readStateName(components);
  return (city: city, state: state);
}

({String city, String state}) parseCityStateLabel(String label) {
  return parsePrimaryLocationInput(label);
}

ParsedAddressParts parseAddressComponents(PlaceDetails details) {
  final components = details.addressComponents;
  final streetNumber = readLongText(components, const ['street_number']);
  final route = readLongText(components, const ['route']);
  final joined = [streetNumber, route].where((v) => v.isNotEmpty).join(' ');
  final line1 = joined.isNotEmpty
      ? joined
      : (readLongText(components, const ['premise']).isNotEmpty
            ? readLongText(components, const ['premise'])
            : route);

  final city = readLongText(components, const [
    'locality',
    'postal_town',
    'sublocality',
  ]);
  final state = readStateName(components);
  final zipRaw = readLongText(components, const ['postal_code']);

  return ParsedAddressParts(
    line1: line1,
    city: city,
    state: state,
    postalCode: zipRaw.isNotEmpty ? normalizeZip(zipRaw) : '',
  );
}

ParsedAddressParts parseAddressLabel(String label) {
  final parts = label
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  while (parts.isNotEmpty &&
      RegExp(r'^(USA|United States)$', caseSensitive: false)
          .hasMatch(parts.last)) {
    parts.removeLast();
  }

  final first = parts.isNotEmpty ? parts.first : label.trim();
  if (parts.length <= 1) {
    return ParsedAddressParts(line1: first);
  }
  if (parts.length == 2) {
    return ParsedAddressParts(line1: first, city: parts[1]);
  }

  final city = parts[1];
  final stateZipPart = parts[2];
  final zipMatch = RegExp(r'(\d{5})(?:-\d{4})?\s*$').firstMatch(stateZipPart);

  var postalCode = '';
  var stateToken = stateZipPart;
  if (zipMatch != null) {
    postalCode = normalizeZip(zipMatch.group(1)!);
    stateToken = stateZipPart.substring(0, zipMatch.start).trim();
  }

  return ParsedAddressParts(
    line1: first,
    city: city,
    state: toFullStateName(stateToken),
    postalCode: postalCode,
  );
}
