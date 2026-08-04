import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';

StatefulShellRoute _shellRouteOf(GoRouter router) =>
    router.configuration.routes.whereType<StatefulShellRoute>().single;

String _initialLocationOf(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // These assertions run against the shared `AppRouter` statics, so they are
  // ordered as one lifecycle rather than split into independent tests.
  test('each sign-in gets its own router, keys, and shell route', () {
    final boot = AppRouter.session;
    expect(
      _initialLocationOf(boot.router),
      AppRouter.splash,
      reason: 'first session should boot into splash',
    );
    expect(
      AppRouter.startSession(loggedIn: true),
      same(boot),
      reason:
          'the boot session must be adopted, not orphaned, so a static '
          'consumer touching the navigator key first cannot leak a router',
    );

    final afterLogout = AppRouter.startSession(loggedIn: false);
    expect(_initialLocationOf(afterLogout.router), AppRouter.login);

    final afterLogin = AppRouter.startSession(loggedIn: true);
    expect(_initialLocationOf(afterLogin.router), AppRouter.home);

    expect(AppRouter.session, same(afterLogin));
    expect(AppRouter.router, same(afterLogin.router));
    expect(AppRouter.rootNavigatorKey, same(afterLogin.rootNavigatorKey));

    for (final (a, b) in [
      (boot, afterLogout),
      (afterLogout, afterLogin),
      (boot, afterLogin),
    ]) {
      expect(a.router, isNot(same(b.router)));
      expect(a.rootNavigatorKey, isNot(same(b.rootNavigatorKey)));
      expect(a.shellNavigatorKey, isNot(same(b.shellNavigatorKey)));
      // StatefulShellRoute builds every shell with one GlobalKey created in its
      // constructor, so sessions must never share a route instance.
      expect(_shellRouteOf(a.router), isNot(same(_shellRouteOf(b.router))));
    }

    for (final session in [boot, afterLogout, afterLogin]) {
      session.router.dispose();
    }
  });
}
