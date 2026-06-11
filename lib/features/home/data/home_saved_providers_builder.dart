import 'package:vcare_admin/features/find_care/data/find_care_mock_data.dart';
import 'package:vcare_admin/features/find_care/domain/entities/cms_provider_favorite.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

const homeSavedProvidersCarouselLimit = 6;
const homeCareTeamCarouselLimit = 4;

List<SavedProviderItem> buildHomeSavedProviders({
  required List<String> mockFavoriteIds,
  required List<CmsProviderFavorite> cmsFavorites,
}) {
  final mockItems = FindCareMockData.providers
      .where((provider) => mockFavoriteIds.contains(provider.id))
      .map(
        (provider) => SavedProviderItem(
          kind: HomeSavedProviderKind.mock,
          key: 'm-${provider.id}',
          providerId: provider.id,
          name: provider.name,
          tag: provider.specialty,
          location: provider.distanceMi > 0
              ? '${provider.distanceMi} mi'
              : provider.address,
          rating: provider.rating,
          phone: provider.phone,
          inNetwork: provider.inNetwork,
        ),
      );

  final cmsItems = cmsFavorites.map(
    (favorite) => SavedProviderItem(
      kind: HomeSavedProviderKind.cms,
      key: 'c-${favorite.npi}',
      medicareNpi: favorite.npi,
      name: formatMedicareProviderName(favorite.row),
      tag: 'CMS · Medicare',
      providerSubtitle: favorite.row.providerType.isNotEmpty
          ? favorite.row.providerType
          : 'Provider',
      location: [
        favorite.row.city,
        favorite.row.state,
      ].where((part) => part.trim().isNotEmpty).join(', '),
    ),
  );

  return [...mockItems, ...cmsItems];
}
