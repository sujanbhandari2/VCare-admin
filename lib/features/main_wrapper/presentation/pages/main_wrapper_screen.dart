import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_provider.dart';
import 'package:vcare_admin/features/messages/presentation/providers/live_chat_mobile_thread_visible_provider.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/fcm_notification_init_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_state_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';
import 'package:vcare_admin/features/main_wrapper/presentation/widgets/vcare_bottom_navigation.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';
import 'package:vcare_admin/shared/navigation/tab_data_refresh_coordinator.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/keyboard_inset.dart';

import '../../../inapp_update/domain/entities/remote_config_app_update_info.dart';
import '../../../inapp_update/presentation/providers/remote_config_app_update_state_provider.dart';
import '../../../inapp_update/presentation/widgets/app_update_sheet.dart';

class MainWrapperScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  final GoRouterState state;

  const MainWrapperScreen({
    super.key,
    required this.shell,
    required this.state,
  });

  @override
  ConsumerState<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends ConsumerState<MainWrapperScreen>
    with WidgetsBindingObserver {
  bool get _showNavBar => NavItem.mobileTabs.any(
    (item) => widget.state.matchedLocation.startsWith(item.path),
  );

  /// Case detail hosts a pinned note composer — shell inset would leave a
  /// large empty band above the floating nav (same as Live Chat threads).
  bool get _isCaseDetailRoute {
    final location = widget.state.matchedLocation;
    return RegExp(r'^/cases/[^/]+$').hasMatch(location);
  }

  NavItem get _currentNavItem =>
      NavItem.fromBranchIndex(widget.shell.currentIndex);

  bool _appliesShellBottomInset(
    BuildContext context, {
    required bool liveChatThreadOpen,
  }) {
    if (MediaQuery.sizeOf(context).width >= VCareLayout.mobileBreakpoint) {
      return false;
    }
    if (!_showNavBar) {
      return false;
    }
    // Conversation thread handles its own composer clearance; keeping the
    // shell inset would leave a large empty gap above the floating nav.
    if (liveChatThreadOpen && _currentNavItem == NavItem.messages) {
      return false;
    }
    if (_isCaseDetailRoute) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Rebuild when platform view insets change so the floating nav can
    // collapse/restore even if MediaQuery was zeroed by a nested Scaffold.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteConfigAppUpdateStateProvider.notifier).checkForUpdate();
      if (ref.read(userLoggedInStateProvider)) {
        unawaited(_bootstrapAuthenticatedSession());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _bootstrapAuthenticatedSession() async {
    await Future.wait([
      ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true),
      ref.read(tenantBrandingStateProvider.notifier).refreshFromApi(),
    ]);
    if (!mounted) return;
    try {
      await ref.read(healthMessengerSessionProvider.notifier).ensureStarted();
    } catch (_) {
      // Bootstrap error is stored on session state for Live Chat UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remoteConfigAppUpdateStateProvider, (previous, next) {
      if (next.operation.isSuccess && next.hasUpdate) {
        _handleUpdateInfo(next.info);
      }
    });
    ref.watch(fcmNotificationInitProvider);
    final liveChatThreadOpen = ref.watch(liveChatMobileThreadVisibleProvider);
    final appliesShellBottomInset = _appliesShellBottomInset(
      context,
      liveChatThreadOpen: liveChatThreadOpen,
    );
    final keyboardOpen = isSoftKeyboardOpen(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        // Let tab screens / nested Scaffolds handle IME avoidance. Resizing
        // this shell would also push [bottomNavigationBar] above the keyboard.
        resizeToAvoidBottomInset: false,
        // Do not conditionally wrap [widget.shell] — StatefulNavigationShell's
        // GlobalKey cannot be reparented when chat session bootstrap completes.
        body: VCareMobileShellScope(
          // Keep the scope flag stable while the keyboard is open so child
          // composers do not re-add nav clearance on top of the IME.
          appliesBottomContentInset: appliesShellBottomInset,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: appliesShellBottomInset && !keyboardOpen
                  ? vcareMobileBottomNavContentPadding(context)
                  : 0,
            ),
            child: widget.shell,
          ),
        ),
        extendBody: true,
        // Always the same [VcareBottomNavigation] instance type — collapse to
        // height 0 while the IME is open instead of nulling this slot (that
        // previously left the bar missing until a full restart).
        bottomNavigationBar: VcareBottomNavigation(
          currentItem: _currentNavItem,
          collapsed: keyboardOpen,
          onSelect: (item) {
            widget.shell.goBranch(
              NavItem.branchIndexFor(item),
              initialLocation: item == _currentNavItem,
            );
            unawaited(refreshTabData(ref, item));
          },
        ),
      ),
    );
  }

  Future<void> _handleUpdateInfo(RemoteConfigAppUpdateInfo? info) async {
    if (kDebugMode) return;
    if (!mounted || info == null || !info.isUpdateAvailable) return;

    AppUpdateSheet.show(context, info: info);
  }
}
