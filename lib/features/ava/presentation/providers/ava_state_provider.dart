import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../state/ava_state.dart';
import 'ava_repository_provider.dart';
import '../../domain/entities/ava_message.dart';
import '../../data/ava_mock_data.dart';

part 'ava_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AvaStateNotifier extends _$AvaStateNotifier {
  @override
  AvaState build() {
    // Initialize with seed messages immediately for better UX
    return AvaState(messages: List.from(AvaMockData.seedMessages));
  }

  Future<void> sendMessage(String body) async {
    if (body.trim().isEmpty) return;

    final editingId = state.editingId;
    if (editingId != null) {
      await _editMessage(editingId, body);
      return;
    }

    final mine = AvaMessage(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      sender: AvaSender.me,
      body: body,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, mine]);

    // Mock Ava reply
    _handleAvaReply();
  }

  Future<void> _editMessage(String id, String body) async {
    state = state.loading();
    final result = await ref.read(avaRepositoryProvider).editMessage(id, body);

    result.when(
      success: (updated) {
        final messages = state.messages
            .map((m) => m.id == id ? updated : m)
            .toList();
        state = state.success(messages: messages).copyWith(editingId: null);
      },
      failure: (error) {
        state = state.failure(error.message);
      },
    );
  }

  void startEdit(String id, String body) {
    state = state.copyWith(editingId: id);
  }

  void cancelEdit() {
    state = state.copyWith(editingId: null);
  }

  Future<void> deleteMessage(String id) async {
    final result = await ref.read(avaRepositoryProvider).deleteMessage(id);
    result.when(
      success: (_) {
        final messages = state.messages.where((m) => m.id != id).toList();
        state = state.copyWith(
          messages: messages,
          editingId: state.editingId == id ? null : state.editingId,
        );
      },
      failure: (error) {
        state = state.failure(error.message);
      },
    );
  }

  void _handleAvaReply() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!ref.mounted) return;

      final reply = AvaMessage(
        id: 'a-${DateTime.now().millisecondsSinceEpoch}',
        sender: AvaSender.ava,
        body: AvaMockData.mockReply,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(messages: [...state.messages, reply]);
    });
  }
}
