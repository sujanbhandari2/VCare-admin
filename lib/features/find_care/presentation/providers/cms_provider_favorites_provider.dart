import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/features/find_care/domain/entities/cms_provider_favorite.dart';
import 'package:flutter_template/features/find_care/domain/entities/medicare_provider_lookup_row.dart';

part 'cms_provider_favorites_provider.g.dart';

@Riverpod(keepAlive: true)
class CmsProviderFavorites extends _$CmsProviderFavorites {
  @override
  List<CmsProviderFavorite> build() => [];

  bool isFavorite(String npi) => state.any((item) => item.npi == npi);

  bool toggle(MedicareProviderListItem item) {
    if (isFavorite(item.row.npi)) {
      state = state.where((fav) => fav.npi != item.row.npi).toList();
      return false;
    }
    state = [
      ...state,
      CmsProviderFavorite(npi: item.row.npi, row: item.row, raw: item.raw),
    ];
    return true;
  }

  void remove(String npi) {
    state = state.where((fav) => fav.npi != npi).toList();
  }
}
