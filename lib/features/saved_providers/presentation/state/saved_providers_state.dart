import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class SavedProvidersState {
  const SavedProvidersState({
    this.operation = const OperationState<List<SavedProvider>>.idle(),
    this.togglingNpis = const {},
  });

  final OperationState<List<SavedProvider>> operation;
  final Set<String> togglingNpis;

  List<SavedProvider> get providers => operation.data ?? const [];

  bool get fetching => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  bool isSaved(String npi) =>
      providers.any((provider) => provider.provider.npi == npi);

  bool isToggling(String npi) => togglingNpis.contains(npi);

  SavedProvider? byNpi(String npi) {
    for (final provider in providers) {
      if (provider.provider.npi == npi) return provider;
    }
    return null;
  }

  SavedProvidersState loading() => SavedProvidersState(
        operation: OperationState.loading(data: providers),
        togglingNpis: togglingNpis,
      );

  SavedProvidersState success(List<SavedProvider> providers) => SavedProvidersState(
        operation: OperationState.success(providers),
        togglingNpis: togglingNpis,
      );

  SavedProvidersState failure(String? message) => SavedProvidersState(
        operation: OperationState.failure(message, data: providers),
        togglingNpis: togglingNpis,
      );

  SavedProvidersState withProviders(List<SavedProvider> providers) =>
      SavedProvidersState(
        operation: OperationState.success(providers),
        togglingNpis: togglingNpis,
      );

  SavedProvidersState withTogglingNpi(String npi, {required bool toggling}) {
    final next = Set<String>.from(togglingNpis);
    if (toggling) {
      next.add(npi);
    } else {
      next.remove(npi);
    }
    return SavedProvidersState(
      operation: operation,
      togglingNpis: next,
    );
  }
}
