import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/state/medicare_provider_detail_state.dart';
import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'medicare_provider_detail_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MedicareProviderDetailStateNotifier
    extends _$MedicareProviderDetailStateNotifier {
  @override
  MedicareProviderDetailState build(String npi) {
    return MedicareProviderDetailState(npiDigits: normalizeNpi(npi));
  }

  Future<void> load({
    MedicareProviderLookupRow? passedRow,
    Map<String, String>? passedRaw,
  }) async {
    final digits = state.npiDigits;
    if (digits.length != 10) return;

    if (passedRow != null && normalizeNpi(passedRow.npi) == digits) {
      state = state.copyWith(
        row: passedRow,
        raw: passedRaw ?? state.raw,
        fieldOrder: passedRaw?.keys.toList() ?? state.fieldOrder,
      );
    }

    state = state.copyWith(lookupLoading: true, clearLookupError: true);
    final lookupResponse = await ref
        .read(medicareProviderRepositoryProvider)
        .fetchByNpi(digits);

    if (!ref.mounted) return;

    lookupResponse.when(
      failure: (error) {
        state = state.copyWith(
          lookupLoading: false,
          lookupError: error.userMessage ?? 'Request failed',
        );
      },
      success: (result) {
        final item = result.item;
        state = state.copyWith(
          lookupLoading: false,
          row: item?.row ?? passedRow ?? state.row,
          raw: item?.raw ?? passedRaw ?? state.raw,
          fieldOrder: result.headers.isNotEmpty
              ? result.headers
              : (item?.raw.keys.toList() ?? state.fieldOrder),
        );
      },
    );

    await _loadServices(reset: true);
  }

  Future<void> loadMoreServices() async {
    if (!state.hasMoreServices || state.servicesLoadingMore) return;
    state = state.copyWith(servicesLoadingMore: true, clearServicesError: true);
    await _loadServices(reset: false);
  }

  Future<void> _loadServices({required bool reset}) async {
    if (state.npiDigits.length != 10) return;

    if (reset) {
      state = state.copyWith(
        servicesLoading: true,
        clearServicesError: true,
        serviceLines: [],
        hasMoreServices: false,
      );
    }

    final offset = reset ? 0 : state.serviceLines.length;
    final response = await ref
        .read(medicareProviderRepositoryProvider)
        .fetchServices(
          npi: state.npiDigits,
          offset: offset,
          size: cmsProviderServicesPageSize,
        );

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        state = state.copyWith(
          servicesLoading: false,
          servicesLoadingMore: false,
          servicesError: error.userMessage ?? 'Request failed',
          serviceLines: reset ? [] : state.serviceLines,
        );
      },
      success: (result) {
        final merged = reset
            ? result.serviceLines
            : [...state.serviceLines, ...result.serviceLines];
        state = state.copyWith(
          servicesLoading: false,
          servicesLoadingMore: false,
          serviceLines: merged,
          hasMoreServices:
              result.serviceLines.length == cmsProviderServicesPageSize,
        );
      },
    );
  }
}
