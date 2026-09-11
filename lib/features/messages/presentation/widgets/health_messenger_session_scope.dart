import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';

/// Wraps authenticated shell content with [MessengerPresenceScope] when chat session exists.
class HealthMessengerSessionScope extends ConsumerWidget {
  const HealthMessengerSessionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(healthMessengerSessionProvider).session;
    if (session == null) {
      return child;
    }
    return MessengerPresenceScope(session: session, child: child);
  }
}
