import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/data/find_care_mock_data.dart';

part 'provider_favorites_provider.g.dart';

@Riverpod(keepAlive: true)
class ProviderFavorites extends _$ProviderFavorites {
  @override
  List<String> build() =>
      List<String>.from(FindCareMockData.favoriteProviderIds);

  bool isFavorite(String id) => state.contains(id);

  bool toggle(String id) {
    if (state.contains(id)) {
      state = state.where((entry) => entry != id).toList();
      return false;
    }
    state = [...state, id];
    return true;
  }
}
