import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_service_line.dart';

class MedicareProviderDetailState {
  const MedicareProviderDetailState({
    required this.npiDigits,
    this.row,
    this.raw = const {},
    this.fieldOrder = const [],
    this.serviceLines = const [],
    this.lookupLoading = false,
    this.servicesLoading = false,
    this.servicesLoadingMore = false,
    this.lookupError,
    this.servicesError,
    this.hasMoreServices = false,
  });

  final String npiDigits;
  final MedicareProviderLookupRow? row;
  final Map<String, String> raw;
  final List<String> fieldOrder;
  final List<MedicareProviderServiceLine> serviceLines;
  final bool lookupLoading;
  final bool servicesLoading;
  final bool servicesLoadingMore;
  final String? lookupError;
  final String? servicesError;
  final bool hasMoreServices;

  bool get isValidNpi => npiDigits.length == 10;

  MedicareProviderDetailState copyWith({
    MedicareProviderLookupRow? row,
    Map<String, String>? raw,
    List<String>? fieldOrder,
    List<MedicareProviderServiceLine>? serviceLines,
    bool? lookupLoading,
    bool? servicesLoading,
    bool? servicesLoadingMore,
    String? lookupError,
    String? servicesError,
    bool clearLookupError = false,
    bool clearServicesError = false,
    bool? hasMoreServices,
  }) {
    return MedicareProviderDetailState(
      npiDigits: npiDigits,
      row: row ?? this.row,
      raw: raw ?? this.raw,
      fieldOrder: fieldOrder ?? this.fieldOrder,
      serviceLines: serviceLines ?? this.serviceLines,
      lookupLoading: lookupLoading ?? this.lookupLoading,
      servicesLoading: servicesLoading ?? this.servicesLoading,
      servicesLoadingMore: servicesLoadingMore ?? this.servicesLoadingMore,
      lookupError: clearLookupError ? null : (lookupError ?? this.lookupError),
      servicesError: clearServicesError
          ? null
          : (servicesError ?? this.servicesError),
      hasMoreServices: hasMoreServices ?? this.hasMoreServices,
    );
  }
}
