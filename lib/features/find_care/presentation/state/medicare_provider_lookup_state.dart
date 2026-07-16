import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';

class MedicareLookupSubmitted {
  const MedicareLookupSubmitted({
    required this.firstName,
    required this.lastName,
    required this.state,
  });

  final String firstName;
  final String lastName;
  final String state;
}

class MedicareProviderLookupState {
  const MedicareProviderLookupState({
    this.firstName = '',
    this.lastName = '',
    this.state = '',
    this.submitted,
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.hasMore = false,
  });

  final String firstName;
  final String lastName;
  final String state;
  final MedicareLookupSubmitted? submitted;
  final List<MedicareProviderListItem> items;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool hasMore;

  bool get enabled =>
      submitted != null &&
      submitted!.firstName.trim().isNotEmpty &&
      submitted!.lastName.trim().isNotEmpty;

  MedicareProviderLookupState copyWith({
    String? firstName,
    String? lastName,
    String? state,
    MedicareLookupSubmitted? submitted,
    bool clearSubmitted = false,
    List<MedicareProviderListItem>? items,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    bool? hasMore,
  }) {
    return MedicareProviderLookupState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      state: state ?? this.state,
      submitted: clearSubmitted ? null : (submitted ?? this.submitted),
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
