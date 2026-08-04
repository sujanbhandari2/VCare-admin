import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';
import 'package:vcare_admin/features/documents/presentation/providers/documents_repository_provider.dart';
import 'package:vcare_admin/features/documents/presentation/state/document_types_state.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'document_types_state_provider.g.dart';

@Riverpod(keepAlive: true)
class DocumentTypesStateNotifier extends _$DocumentTypesStateNotifier {
  @override
  DocumentTypesState build() => const DocumentTypesState();

  Future<void> fetchDocumentTypes({
    bool forceRefresh = false,
    void Function(bool success)? onCompleted,
  }) async {
    if (state.requesting) return;
    if (!forceRefresh && state.data.isNotEmpty) {
      onCompleted?.call(true);
      return;
    }

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(documentsRepositoryProvider)
        .fetchDocumentTypes(forceRefresh: forceRefresh);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(false);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(true);
      },
    );
  }

  List<DocumentTypeOption> filteredOptions({required bool includeW9}) {
    return filterDocumentTypeOptions(state.data, includeW9: includeW9);
  }
}
