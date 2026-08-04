import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';

part 'find_care_search_location_provider.g.dart';

@Riverpod(keepAlive: true)
class FindCareSearchLocation extends _$FindCareSearchLocation {
  @override
  SearchLocation build() {
    final storage = ref.read(storageServiceProvider);
    final raw = storage.get(StorageKeys.findCareSearchLocation);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        if (json is Map) {
          return SearchLocation.fromJson(Map<String, dynamic>.from(json));
        }
      } catch (_) {}
    }
    return _locationFromProfile();
  }

  SearchLocation _locationFromProfile() {
    final profile = ref.read(localProfileStateProvider);
    return searchLocationFromProfile(
      primaryCity: profile.primaryCity,
      primaryState: profile.primaryState,
    );
  }

  Future<void> setLocation(SearchLocation location) async {
    state = location;
    await ref
        .read(storageServiceProvider)
        .set(StorageKeys.findCareSearchLocation, jsonEncode(location.toJson()));
  }

  /// Applies a GPS-resolved search area and marks it as current location.
  Future<void> setFromCurrentLocation(SearchLocation location) async {
    await setLocation(
      location.copyWith(fromCurrentLocation: true),
    );
  }

  /// Restores the search area to the user's profile city/state.
  Future<void> useProfileLocation() async {
    await setLocation(_locationFromProfile());
  }

  Future<void> setFromDisplayText(String text) async {
    final stateCode = parseSearchState(text);
    final parts = text.split(',');
    final city = parts.isNotEmpty ? parts.first.trim() : '';
    await setLocation(
      SearchLocation(
        city: city,
        state: stateCode ?? '',
        fromCurrentLocation: false,
      ),
    );
  }
}
