import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/state/case_notes_state.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'case_notes_state_provider.g.dart';

const Duration caseNotesStreamInterval = Duration(seconds: 3);

@Riverpod(keepAlive: true)
class CaseNotesState extends _$CaseNotesState {
  int _generation = 0;
  int _streamGeneration = 0;
  Timer? _streamTimer;
  CancelToken? _streamCancelToken;
  var _streaming = false;
  var _streamInFlight = false;

  @override
  CaseNotesStateData build(String caseId) {
    ref.onDispose(stopStreamingNotes);
    return const CaseNotesStateData();
  }

  bool get isStreamingNotes => _streaming;

  String? get _currentUserId {
    final sessionId = ref.read(adminAuthSessionProvider).user?.id.trim();
    if (sessionId != null && sessionId.isNotEmpty) return sessionId;

    final authMeId = ref.read(authMeStateProvider).user?.id?.trim();
    if (authMeId != null && authMeId.isNotEmpty) return authMeId;

    return null;
  }

  void startStreamingNotes({Duration interval = caseNotesStreamInterval}) {
    if (_streaming) return;

    _streaming = true;
    _streamTimer = Timer.periodic(interval, (_) {
      unawaited(fetchNotes(forceRefresh: true, silent: true));
    });
  }

  void stopStreamingNotes() {
    if (!_streaming && _streamTimer == null && _streamCancelToken == null) {
      return;
    }

    _streaming = false;
    _streamTimer?.cancel();
    _streamTimer = null;
    _streamCancelToken?.cancel();
    _streamCancelToken = null;
    _streamGeneration++;
    _streamInFlight = false;
  }

  Future<void> fetchNotes({
    bool forceRefresh = true,
    bool silent = false,
    CancelToken? cancelToken,
  }) async {
    if (silent) {
      await _fetchNotesSilently(
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );
      return;
    }

    final generation = ++_generation;

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(caseNoteRepositoryProvider)
        .fetchNotes(
          caseId,
          currentUserId: _currentUserId,
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
        );

    if (!ref.mounted || generation != _generation) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _generation) {
          state = state.failure(error.userMessage);
        }
      },
      success: (notes) {
        if (ref.mounted && generation == _generation) {
          state = state.success(notes);
        }
      },
    );
  }

  Future<void> _fetchNotesSilently({
    required bool forceRefresh,
    CancelToken? cancelToken,
  }) async {
    if (!_streaming || _streamInFlight || state.fetching || state.mutating) {
      return;
    }

    final generation = ++_streamGeneration;
    final requestGeneration = _generation;
    _streamInFlight = true;
    final token = cancelToken ?? CancelToken();
    _streamCancelToken = token;

    try {
      final response = await ref
          .read(caseNoteRepositoryProvider)
          .fetchNotes(
            caseId,
            currentUserId: _currentUserId,
            cancelToken: token,
            forceRefresh: forceRefresh,
          );

      if (!ref.mounted ||
          !_streaming ||
          generation != _streamGeneration ||
          requestGeneration != _generation ||
          state.mutating) {
        return;
      }

      response.when(
        failure: (_) {
          // Keep the last good list so a background tick never flashes
          // an error or loading state.
        },
        success: (notes) {
          if (!ref.mounted ||
              !_streaming ||
              generation != _streamGeneration ||
              requestGeneration != _generation ||
              state.mutating) {
            return;
          }
          if (_notesUnchanged(state.notes, notes)) return;
          state = state.success(notes);
        },
      );
    } finally {
      if (generation == _streamGeneration) {
        _streamInFlight = false;
        if (identical(_streamCancelToken, token)) {
          _streamCancelToken = null;
        }
      }
    }
  }

  Future<void> addNote({
    required String note,
    CaseStatus? status,
    String? accessType,
    List<({String fileName, List<int> bytes})> files = const [],
    List<CaseNotePublicUrl> publicUrls = const [],
    void Function(CaseNote? created, String? error)? onCompleted,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty || state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final createResponse = await ref
        .read(caseNoteRepositoryProvider)
        .createNote(
          caseId,
          note: trimmed,
          status: status,
          accessType: accessType ?? defaultNoteAccessType,
          currentUserId: _currentUserId,
        );

    await createResponse.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (created) async {
        if (files.isNotEmpty || publicUrls.isNotEmpty) {
          final uploadResponse = await ref
              .read(caseNoteRepositoryProvider)
              .uploadNoteAttachments(
                caseId,
                created.id,
                files: files,
                publicUrls: publicUrls,
              );

          final uploadError = uploadResponse.when(
            failure: (error) => error.userMessage,
            success: (_) => null,
          );
          if (uploadError != null) {
            if (ref.mounted) {
              state = state.mutationFailure(uploadError);
            }
            onCompleted?.call(created, uploadError);
            await fetchNotes(forceRefresh: true);
            return;
          }
        }

        await fetchNotes(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(created, null);
      },
    );
  }

  Future<void> updateNote({
    required String noteId,
    String? note,
    CaseStatus? status,
    String? accessType,
    void Function(CaseNote? updated, String? error)? onCompleted,
  }) async {
    if (state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref
        .read(caseNoteRepositoryProvider)
        .updateNote(
          caseId,
          noteId,
          note: note,
          status: status,
          accessType: accessType,
          currentUserId: _currentUserId,
        );

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(null, error.userMessage);
      },
      success: (updated) async {
        await fetchNotes(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(updated, null);
      },
    );
  }

  /// Flips a note between INTERNAL and EXTERNAL without touching its content.
  Future<void> toggleNoteAccess({
    required CaseNote note,
    void Function(bool isPublic, String? error)? onCompleted,
  }) async {
    if (!note.canEdit || state.mutating) return;

    final nextAccessType = toggleNoteAccessType(note.accessType);

    if (ref.mounted) {
      state = state.mutationLoading().copyWith(accessTogglingNoteId: note.id);
    }

    final response = await ref
        .read(caseNoteRepositoryProvider)
        .updateNote(
          caseId,
          note.id,
          accessType: nextAccessType,
          currentUserId: _currentUserId,
        );

    final error = response.when(
      failure: (failure) => failure.userMessage,
      success: (_) => null,
    );

    if (error == null) {
      await fetchNotes(forceRefresh: true);
    }

    if (ref.mounted) {
      state =
          (error == null ? state.mutationIdle() : state.mutationFailure(error))
              .copyWith(clearAccessTogglingNoteId: true);
    }

    onCompleted?.call(isPublicNoteAccessType(nextAccessType), error);
  }

  Future<void> deleteNote({
    required String noteId,
    void Function(bool success, String? error)? onCompleted,
  }) async {
    if (state.mutating) return;

    if (ref.mounted) {
      state = state.mutationLoading();
    }

    final response = await ref
        .read(caseNoteRepositoryProvider)
        .deleteNote(caseId, noteId);

    await response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.mutationFailure(error.userMessage);
        }
        onCompleted?.call(false, error.userMessage);
      },
      success: (_) async {
        await fetchNotes(forceRefresh: true);
        if (ref.mounted) {
          state = state.mutationIdle();
        }
        onCompleted?.call(true, null);
      },
    );
  }

  Future<void> fetchTagUsers({
    String? search,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.copyWith(
        tagUsersOperation: OperationState<List<CaseNoteTagUser>>.loading(
          data: state.tagUsers,
        ),
      );
    }

    final response = await ref
        .read(caseNoteRepositoryProvider)
        .fetchTagUsers(
          caseId,
          search: search,
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
        );

    if (!ref.mounted) return;

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.copyWith(
            tagUsersOperation: OperationState<List<CaseNoteTagUser>>.failure(
              error.userMessage,
              data: state.tagUsers,
            ),
          );
        }
      },
      success: (users) {
        if (ref.mounted) {
          state = state.copyWith(
            tagUsersOperation: OperationState<List<CaseNoteTagUser>>.success(
              users,
            ),
          );
        }
      },
    );
  }
}

bool _notesUnchanged(List<CaseNote> current, List<CaseNote> next) {
  if (identical(current, next) || current.length != next.length) {
    return identical(current, next);
  }

  for (var i = 0; i < current.length; i++) {
    final a = current[i];
    final b = next[i];
    if (a.id != b.id ||
        a.content != b.content ||
        a.createdAt != b.createdAt ||
        a.status != b.status ||
        a.accessType != b.accessType ||
        a.authorName != b.authorName ||
        a.canEdit != b.canEdit ||
        a.canDelete != b.canDelete ||
        a.files.length != b.files.length) {
      return false;
    }
  }

  return true;
}
