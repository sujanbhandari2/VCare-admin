import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';

part 'app_router_provider.g.dart';

/// Router for the current sign-in.
///
/// Invalidate this through [startAuthenticatedRouterSession] once a sign-in has
/// been persisted. See [AppRouter.startSession] for why a router must not be
/// shared across sessions.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Read, not watch: the session that a router belongs to is fixed for its
  // lifetime, and callers decide explicitly when to swap it.
  final session = AppRouter.startSession(
    loggedIn: ref.read(userLoggedInStateProvider),
  );

  ref.onDispose(() {
    final router = session.router;
    // The outgoing widget tree still holds this delegate for the rest of the
    // frame, so let it unmount before tearing the router down.
    WidgetsBinding.instance.addPostFrameCallback((_) => router.dispose());
  });

  return session.router;
}

/// Swaps in a router for the newly authenticated session.
///
/// Replaces `context.goNamed(home)`: the new router already starts at home, and
/// its shell has never been mounted, so it cannot collide with the shell that
/// belonged to the previous session.
void startAuthenticatedRouterSession(WidgetRef ref) {
  ref.invalidate(appRouterProvider);
}
