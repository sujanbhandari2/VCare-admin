import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';

/// Silently streams case notes while this case detail route is the active
/// foreground screen. Polling stops on pop, tab/route change, or background.
class CaseNotesLiveSync extends ConsumerStatefulWidget {
  const CaseNotesLiveSync({
    super.key,
    required this.caseId,
    required this.child,
  });

  final String caseId;
  final Widget child;

  @override
  ConsumerState<CaseNotesLiveSync> createState() => _CaseNotesLiveSyncState();
}

class _CaseNotesLiveSyncState extends ConsumerState<CaseNotesLiveSync>
    with WidgetsBindingObserver {
  GoRouter? _router;
  late CaseNotesState _notesNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notesNotifier = ref.read(caseNotesStateProvider(widget.caseId).notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_syncStreaming);
      _router = router;
      _router!.routerDelegate.addListener(_syncStreaming);
    }
    _syncStreaming();
  }

  @override
  void didUpdateWidget(CaseNotesLiveSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caseId == widget.caseId) return;

    ref
        .read(caseNotesStateProvider(oldWidget.caseId).notifier)
        .stopStreamingNotes();
    _notesNotifier = ref.read(caseNotesStateProvider(widget.caseId).notifier);
    _syncStreaming();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncStreaming();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_syncStreaming);
    WidgetsBinding.instance.removeObserver(this);
    _notesNotifier.stopStreamingNotes();
    super.dispose();
  }

  bool get _isAppForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool get _isThisCaseRoute {
    final path = _router?.state.uri.path;
    if (path == null || widget.caseId.isEmpty) return false;
    return path == '${AppRouter.cases}/${widget.caseId}';
  }

  void _syncStreaming() {
    if (!mounted) return;
    if (_isAppForeground && _isThisCaseRoute) {
      _notesNotifier.startStreamingNotes();
      return;
    }
    _notesNotifier.stopStreamingNotes();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
