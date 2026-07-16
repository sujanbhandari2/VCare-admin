import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/saved_providers/data/mappers/saved_provider_mapper.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';

const homeSavedProvidersCarouselLimit = 6;
const homeCareTeamCarouselLimit = 4;

List<SavedProviderItem> buildHomeSavedProviders({
  required List<SavedProvider> savedProviders,
}) {
  return savedProviders
      .map((savedProvider) {
        final row = savedProvider.provider.toMedicareProviderLookupRow();
        return SavedProviderItem(
          kind: HomeSavedProviderKind.cms,
          key: 'c-${savedProvider.provider.npi}',
          medicareNpi: savedProvider.provider.npi,
          name: formatMedicareProviderName(row),
          tag: 'CMS · Medicare',
          providerSubtitle: savedProvider.provider.type.isNotEmpty
              ? savedProvider.provider.type
              : 'Provider',
          location: [
            savedProvider.provider.city,
            savedProvider.provider.state,
          ].where((part) => part.trim().isNotEmpty).join(', '),
        );
      })
      .toList();
}
