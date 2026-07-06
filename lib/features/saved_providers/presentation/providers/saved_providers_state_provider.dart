import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';
import 'package:vcare_admin/features/saved_providers/presentation/providers/saved_provider_repository_provider.dart';
import 'package:vcare_admin/features/saved_providers/presentation/state/saved_providers_state.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'saved_providers_state_provider.g.dart';

@Riverpod(keepAlive: true)
class SavedProvidersStateNotifier extends _$SavedProvidersStateNotifier {
  @override
  SavedProvidersState build() => const SavedProvidersState();

  Future<void> ensureSavedProvidersLoaded({
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    if (state.fetching) return;
    if (!forceRefresh && state.operation.status == OperationStatus.success) {
      return;
    }
    await fetchSavedProviders(
      forceRefresh: forceRefresh,
      cancelToken: cancelToken,
    );
  }

  Future<void> fetchSavedProviders({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(List<SavedProvider>? providers)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(savedProviderRepositoryProvider)
        .fetchSavedProviders(
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (providers) {
        if (ref.mounted) {
          state = state.success(providers);
        }
        onCompleted?.call(providers);
      },
    );
  }

  Future<bool?> toggleSave(
    MedicareProviderListItem item, {
    CancelToken? cancelToken,
  }) async {
    final npi = item.row.npi;
    if (npi.trim().isEmpty || state.isToggling(npi)) {
      return null;
    }

    final existing = state.byNpi(npi);
    if (ref.mounted) {
      state = state.withTogglingNpi(npi, toggling: true);
    }

    if (existing == null) {
      final response = await ref.read(savedProviderRepositoryProvider).saveProvider(
            row: item.row,
            cancelToken: cancelToken,
          );

      return response.when(
        failure: (_) {
          if (ref.mounted) {
            state = state.withTogglingNpi(npi, toggling: false);
          }
          return null;
        },
        success: (savedProvider) async {
          if (!ref.mounted) return null;

          if (savedProvider.provider.id.isEmpty) {
            await fetchSavedProviders(cancelToken: cancelToken);
            if (!ref.mounted) return null;
            final saved = state.isSaved(npi);
            state = state.withTogglingNpi(npi, toggling: false);
            return saved ? true : null;
          }

          final current = List<SavedProvider>.from(state.providers)
            ..add(savedProvider);
          state = state
              .withProviders(current)
              .withTogglingNpi(npi, toggling: false);
          return true;
        },
      );
    }

    final response = await ref.read(savedProviderRepositoryProvider).deleteSavedProvider(
          providerId: existing.provider.id,
          cancelToken: cancelToken,
        );

    return response.when(
      failure: (_) {
        if (ref.mounted) {
          state = state.withTogglingNpi(npi, toggling: false);
        }
        return null;
      },
      success: (_) {
        if (!ref.mounted) return null;

        final current = List<SavedProvider>.from(state.providers)
          ..removeWhere((provider) => provider.provider.npi == npi);
        state = state
            .withProviders(current)
            .withTogglingNpi(npi, toggling: false);
        return false;
      },
    );
  }

  Future<bool> removeByNpi(
    String npi, {
    CancelToken? cancelToken,
  }) async {
    final existing = state.byNpi(npi);
    if (existing == null) return false;

    if (ref.mounted) {
      state = state.withTogglingNpi(npi, toggling: true);
    }

    final response = await ref
        .read(savedProviderRepositoryProvider)
        .deleteSavedProvider(
          providerId: existing.provider.id,
          cancelToken: cancelToken,
        );

    var removed = false;
    response.when(
      failure: (_) {
        if (ref.mounted) {
          state = state.withTogglingNpi(npi, toggling: false);
        }
      },
      success: (_) {
        if (!ref.mounted) return;

        final current = List<SavedProvider>.from(state.providers)
          ..removeWhere((provider) => provider.provider.npi == npi);
        state = state
            .withProviders(current)
            .withTogglingNpi(npi, toggling: false);
        removed = true;
      },
    );

    return removed;
  }
}
