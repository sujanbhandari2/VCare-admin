import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/find_care/data/find_care_mock_data.dart';

part 'provider_favorites_provider.g.dart';

@Riverpod(keepAlive: true)
class ProviderFavorites extends _$ProviderFavorites {
  @override
  List<String> build() {
    final storage = ref.read(storageServiceProvider);
    final raw = storage.get(StorageKeys.findCareMockProviderFavorites);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((entry) => entry.toString()).toList();
        }
      } catch (_) {}
    }
    return List<String>.from(FindCareMockData.favoriteProviderIds);
  }

  bool isFavorite(String id) => state.contains(id);

  bool toggle(String id) {
    if (state.contains(id)) {
      state = state.where((entry) => entry != id).toList();
    } else {
      state = [...state, id];
    }
    _persist();
    return state.contains(id);
  }

  Future<void> _persist() async {
    await ref.read(storageServiceProvider).set(
          StorageKeys.findCareMockProviderFavorites,
          jsonEncode(state),
        );
  }
}
