import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/notifications/presentation/providers/fcm_notification_init_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_template/features/main_wrapper/domain/enums/nav_item.dart';
import 'package:flutter_template/features/main_wrapper/presentation/widgets/vcare_bottom_navigation.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

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

class _MainWrapperScreenState extends ConsumerState<MainWrapperScreen> {
  bool get _showNavBar => NavItem.mobileTabs.any(
    (item) => widget.state.matchedLocation.startsWith(item.path),
  );

  NavItem get _currentNavItem =>
      NavItem.fromBranchIndex(widget.shell.currentIndex);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteConfigAppUpdateStateProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remoteConfigAppUpdateStateProvider, (previous, next) {
      if (next.operation.isSuccess && next.hasUpdate) {
        _handleUpdateInfo(next.info);
      }
    });
    ref.watch(fcmNotificationInitProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: widget.shell,
        extendBody: true,
        bottomNavigationBar: AnimatedSize(
          duration: const Duration(milliseconds: 175),
          child: _showNavBar
              ? VcareBottomNavigation(
                  currentItem: _currentNavItem,
                  onSelect: (item) {
                    widget.shell.goBranch(
                      NavItem.branchIndexFor(item),
                      initialLocation: item == _currentNavItem,
                    );
                  },
                )
              : const SizedBox.shrink(),
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
