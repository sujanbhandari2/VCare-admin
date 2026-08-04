import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/help_support/domain/entities/contact_support_attachment.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_result.dart';
import 'package:vcare_admin/features/help_support/presentation/providers/help_support_repository_provider.dart';
import 'package:vcare_admin/features/help_support/presentation/state/help_support_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'help_support_state_provider.g.dart';

@Riverpod(keepAlive: true)
class HelpSupportStateNotifier extends _$HelpSupportStateNotifier {
  @override
  HelpSupportState build() => const HelpSupportState();

  Future<void> submitContactSupport({
    required String message,
    Map<String, Object?>? context,
    List<ContactSupportAttachment> files = const [],
    CancelToken? cancelToken,
    void Function(ContactSupportResult? result)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(helpSupportRepositoryProvider)
        .submitContactSupport(
          message: message,
          context: context,
          files: files,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );
  }

  void reset() {
    if (ref.mounted) {
      state = state.idle();
    }
  }
}
