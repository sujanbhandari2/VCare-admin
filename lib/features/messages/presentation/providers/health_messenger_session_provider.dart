import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:health_messenger_ui/lib/health_messenger_push.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/core/services/connectivity/connectivity_service.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/messages/health_messenger/coalesce_in_flight.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_connection_recovery.dart';
import 'package:vcare_admin/features/messages/presentation/providers/health_messenger_session_state.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/user_profile_state_provider.dart';

part 'health_messenger_session_provider.g.dart';

@Riverpod(keepAlive: true)
class HealthMessengerSession extends _$HealthMessengerSession
    with WidgetsBindingObserver {
  static const Duration backgroundOfflineGrace = Duration(minutes: 4);

  Future<void>? _ensureStartedFuture;
  bool _lifecycleObserverRegistered = false;
  StreamSubscription<MessengerPushEvent>? _pushEventsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ChatConnectionState>? _connectionStateSubscription;
  Timer? _watchdogTimer;
  Timer? _stuckDisconnectTimer;
  Timer? _connectivitySettleTimer;
  ChatSession? _connectionBoundSession;
  Future<void>? _recoverFuture;
  DateTime? _disconnectedSince;
  bool? _hadUsableNetwork;
  int _socketReconnectFailures = 0;
  MessengerPushFirebaseBinding? _pushFirebaseBinding;
  final StreamController<MessengerPushEvent> _pushEventsController =
      StreamController<MessengerPushEvent>.broadcast();

  Stream<MessengerPushEvent> get pushEvents => _pushEventsController.stream;

  @override
  HealthMessengerSessionState build() {
    ref.onDispose(_onDispose);
    return const HealthMessengerSessionState();
  }

  Future<void> ensureStarted() {
    return coalesceInFlightFuture(
      read: () => _ensureStartedFuture,
      write: (next) => _ensureStartedFuture = next,
      start: _ensureStartedInternal,
    );
  }

  Future<void> stopSession() => _stopSession();

  /// Reconnects chat when the package is down and the device has internet.
  ///
  /// [force] skips the native socket.io grace window (user retry, network
  /// restored). It still will not abort an in-flight connect/reconnect.
  Future<void> recoverConnection({bool force = false}) async {
    await _recoverIfNeeded(reason: 'manual', force: force);
    if (force && ref.mounted) {
      await _recoverIfNeeded(reason: 'manual_force', force: true);
    }
  }

  /// Waits for the live socket without starting a competing handshake.
  Future<bool> waitUntilSocketConnected({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final session = state.session;
    if (session == null) {
      return false;
    }
    if (session.isSocketConnected) {
      return true;
    }

    final connected = Completer<void>();
    final subscription = session.client.connectionState.listen((
      connectionState,
    ) {
      if (connectionState == ChatConnectionState.connected &&
          !connected.isCompleted) {
        connected.complete();
      }
    });
    try {
      if (session.isSocketConnected) {
        return true;
      }
      await connected.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return session.isSocketConnected;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _ensureStartedInternal() async {
    _startRecoveryWatch();

    try {
      final storage = ref.read(storageServiceProvider);
      final profile = ref.read(userProfileStateProvider).profile;
      final adminUser = ref.read(adminAuthSessionProvider).user;
      final authMeTenantId =
          ref.read(authMeStateProvider).data?.user.currentTenant?.id;
      final adminTenantId = adminUser?.currentTenant.id.trim();
      final currentTenantId =
          (adminTenantId != null && adminTenantId.isNotEmpty)
              ? adminTenantId
              : authMeTenantId;
      final sessionExternalUserId = adminUser?.id;
      final sessionEmail = adminUser?.email;
      final sessionDisplayName = adminUser?.displayName;
      final externalUserRole = adminUser?.currentRoles
              .map((role) => role.trim())
              .firstWhere((role) => role.isNotEmpty, orElse: () => '') ??
          HealthMessengerBootstrapConfig.defaultExternalUserRole;
      final config = HealthMessengerBootstrapConfig.tryBuild(
        storage: storage,
        profile: profile,
        currentTenantId: currentTenantId,
        sessionExternalUserId: sessionExternalUserId,
        sessionEmail: sessionEmail,
        sessionDisplayName: sessionDisplayName,
        externalUserRole: externalUserRole,
      );

      if (config == null) {
        throw Exception(
          HealthMessengerBootstrapConfig.describeValidationFailure(
            storage: storage,
            profile: profile,
            currentTenantId: currentTenantId,
            sessionExternalUserId: sessionExternalUserId,
            sessionEmail: sessionEmail,
            sessionDisplayName: sessionDisplayName,
          ),
        );
      }

      if (state.isReady &&
          state.bootstrapConfig != null &&
          _sameBootstrapConfig(state.bootstrapConfig!, config)) {
        _log('Session already active for current identity');
        final session = state.session;
        if (session != null) {
          _bindConnectionState(session);
          if (!session.isSocketConnected) {
            unawaited(_recoverIfNeeded(reason: 'ensure_started_existing'));
          }
        }
        return;
      }

      state = state.copyWith(isBootstrapping: true, clearBootstrapError: true);

      await _stopSession(clearInFlight: false);

      final socketLogger = SocketPrettyLogger(
        verboseData: kDebugMode,
      ).asChatLogger();
      final session = ChatSession(
        config: ChatServiceConfig(
          apiBaseUrl: config.apiBaseUrl,
          socketUrl: config.socketUrl,
          socketTransports: const ['websocket'],
          apiLogger: (message, {data}) => _log('API $message', data: data),
          socketLogger: socketLogger,
        ),
        presenceConfig: const PresenceConfig(
          backgroundOfflineGrace: backgroundOfflineGrace,
          disconnectSocketWhenBackgrounded: true,
        ),
      );

      await session.bootstrap(
        apiAuth: ChatAuth(apiKey: config.apiKey),
        externalTenantId: config.externalTenantId,
        externalUserId: config.externalUserId,
        externalUserRole: config.externalUserRole,
        email: config.email,
        name: config.displayName.isEmpty ? null : config.displayName,
        profile: config.profile,
        awaitSocketConnect: false,
      );

      if (session.sessionAuth == null) {
        await session.dispose();
        throw Exception('Chat session has no credentials.');
      }

      _registerLifecycleObserver();
      // Forward onto the new session instance (state.session is still the old
      // value until copyWith below).
      session.handleAppLifecycleState(
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
      );

      state = state.copyWith(
        session: session,
        bootstrapConfig: config,
        isBootstrapping: false,
      );
      _bindConnectionState(session, socketConnectPending: true);
      _socketReconnectFailures = 0;

      unawaited(_setupPushAfterBootstrap(session));
    } catch (error, stackTrace) {
      _log(
        'Session bootstrap failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      state = state.copyWith(
        bootstrapError: error,
        isBootstrapping: false,
        clearSession: true,
        clearBootstrapConfig: true,
      );
      await _stopSession(clearInFlight: false);
      rethrow;
    } finally {
      if (state.isBootstrapping) {
        state = state.copyWith(isBootstrapping: false);
      }
    }
  }

  Future<void> _stopSession({bool clearInFlight = true}) async {
    if (clearInFlight) {
      _ensureStartedFuture = null;
      _stopRecoveryWatch();
      _unregisterLifecycleObserver();
    }
    _unbindConnectionState();
    await _teardownPushIntegration();

    final session = state.session;
    state = state.copyWith(
      clearSession: true,
      clearBootstrapConfig: true,
      clearBootstrapError: true,
      isBootstrapping: false,
      pushIntegrationReady: false,
    );

    if (session == null) {
      return;
    }

    try {
      await session.logout().timeout(const Duration(seconds: 3));
    } catch (error, stackTrace) {
      _log(
        'Session logout failed',
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
      // logout() already disposes on success; retry dispose only after
      // timeout/failure. Package dispose is not idempotent — never overlap.
      try {
        await session.dispose();
      } catch (_) {}
    }
  }

  void _registerLifecycleObserver() {
    if (_lifecycleObserverRegistered) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _lifecycleObserverRegistered = true;
  }

  void _unregisterLifecycleObserver() {
    if (!_lifecycleObserverRegistered) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleObserverRegistered = false;
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    state.session?.handleAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(_recoverIfNeeded(reason: 'lifecycle_resumed'));
    }
  }

  Future<void> _recoverIfNeeded({
    required String reason,
    bool force = false,
  }) {
    return coalesceInFlightFuture(
      read: () => _recoverFuture,
      write: (next) => _recoverFuture = next,
      start: () => _recoverIfNeededBody(reason: reason, force: force),
    );
  }

  Future<void> _recoverIfNeededBody({
    required String reason,
    required bool force,
  }) async {
    if (!ref.mounted) {
      return;
    }

    final inFlightBootstrap = _ensureStartedFuture;
    if (inFlightBootstrap != null) {
      try {
        await inFlightBootstrap;
      } catch (_) {
        return;
      }
      if (!ref.mounted) {
        return;
      }
    }

    final isForeground =
        HealthMessengerConnectionRecovery.isForegroundLifecycle(
          WidgetsBinding.instance.lifecycleState,
        );
    if (!HealthMessengerConnectionRecovery.shouldAttempt(
      hasInternet: true,
      isForeground: isForeground,
      recoverInFlight: false,
      isBootstrapping: state.isBootstrapping,
    )) {
      return;
    }

    final hasInternet = await ConnectivityService.instance
        .hasActiveConnection();
    if (!ref.mounted ||
        !HealthMessengerConnectionRecovery.shouldAttempt(
          hasInternet: hasInternet,
          isForeground: HealthMessengerConnectionRecovery.isForegroundLifecycle(
            WidgetsBinding.instance.lifecycleState,
          ),
          recoverInFlight: false,
          isBootstrapping: state.isBootstrapping,
        )) {
      return;
    }

    final connectionState = _resolvedConnectionState();
    final disconnectedSince = _disconnectedSince;
    final disconnectedFor = disconnectedSince == null
        ? Duration.zero
        : DateTime.now().difference(disconnectedSince);
    final action = HealthMessengerConnectionRecovery.action(
      sessionReady: state.isReady,
      connectionState: connectionState,
      consecutiveSocketFailures: _socketReconnectFailures,
      disconnectedFor: disconnectedFor,
      bypassNativeGrace: force,
    );
    if (action == HealthMessengerRecoveryAction.none) {
      if (HealthMessengerConnectionRecovery.isSocketHealthy(connectionState)) {
        _socketReconnectFailures = 0;
      }
      return;
    }

    try {
      _log(
        'Recovering messenger connection',
        data: {'reason': reason, 'action': action.name, 'force': force},
      );
      switch (action) {
        case HealthMessengerRecoveryAction.none:
          return;
        case HealthMessengerRecoveryAction.bootstrapSession:
          await ensureStarted();
        case HealthMessengerRecoveryAction.reconnectSocket:
          await _reconnectActiveSocket();
        case HealthMessengerRecoveryAction.restartSession:
          _socketReconnectFailures = 0;
          await _stopSession(clearInFlight: false);
          await ensureStarted();
      }
    } catch (error, stackTrace) {
      _log(
        'Messenger recovery failed',
        data: {
          'reason': reason,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  ChatConnectionState _resolvedConnectionState() {
    final session = state.session;
    if (session == null) {
      return ChatConnectionState.disconnected;
    }
    if (session.isSocketConnected) {
      return ChatConnectionState.connected;
    }
    return state.connectionState;
  }

  Future<void> _reconnectActiveSocket() async {
    final session = state.session;
    if (session == null || session.sessionAuth == null) {
      return;
    }
    if (session.isSocketConnected) {
      _socketReconnectFailures = 0;
      return;
    }
    final connectionState = _resolvedConnectionState();
    if (HealthMessengerConnectionRecovery.isSocketInProgress(connectionState)) {
      return;
    }
    try {
      await session.reconnectSocket();
      _socketReconnectFailures = 0;
    } catch (error) {
      _socketReconnectFailures++;
      rethrow;
    }
  }

  void _startRecoveryWatch() {
    _registerLifecycleObserver();
    _connectivitySubscription ??= ConnectivityService
        .instance
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    _watchdogTimer ??= Timer.periodic(
      HealthMessengerConnectionRecovery.watchdogInterval,
      (_) => unawaited(_recoverIfNeeded(reason: 'watchdog')),
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final usable = ConnectivityService.hasUsableNetwork(results);
    final restored = HealthMessengerConnectionRecovery.isNetworkRestored(
      previousUsable: _hadUsableNetwork,
      currentUsable: usable,
    );
    _hadUsableNetwork = usable;
    if (!restored) {
      return;
    }
    _connectivitySettleTimer?.cancel();
    _connectivitySettleTimer = Timer(
      HealthMessengerConnectionRecovery.connectivitySettle,
      () {
        _connectivitySettleTimer = null;
        unawaited(() async {
          await _recoverIfNeeded(
            reason: 'connectivity_restored',
            force: true,
          );
          if (ref.mounted) {
            await _recoverIfNeeded(
              reason: 'connectivity_restored_force',
              force: true,
            );
          }
        }());
      },
    );
  }

  void _stopRecoveryWatch() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _stuckDisconnectTimer?.cancel();
    _stuckDisconnectTimer = null;
    _connectivitySettleTimer?.cancel();
    _connectivitySettleTimer = null;
    _hadUsableNetwork = null;
    _disconnectedSince = null;
  }

  void _bindConnectionState(
    ChatSession session, {
    bool socketConnectPending = false,
  }) {
    if (identical(_connectionBoundSession, session)) {
      return;
    }
    _unbindConnectionState();
    _connectionBoundSession = session;
    final ChatConnectionState initial;
    if (session.isSocketConnected) {
      initial = ChatConnectionState.connected;
    } else if (socketConnectPending) {
      initial = ChatConnectionState.connecting;
    } else {
      initial = ChatConnectionState.disconnected;
    }
    if (ref.mounted) {
      state = state.copyWith(connectionState: initial);
    }
    _onObservedConnectionState(initial);
    _connectionStateSubscription = session.client.connectionState.listen(
      _onObservedConnectionState,
    );
  }

  void _onObservedConnectionState(ChatConnectionState connectionState) {
    if (!ref.mounted) {
      return;
    }
    if (state.connectionState != connectionState) {
      state = state.copyWith(connectionState: connectionState);
    }

    if (HealthMessengerConnectionRecovery.isSocketHealthy(connectionState)) {
      _socketReconnectFailures = 0;
      _disconnectedSince = null;
      _stuckDisconnectTimer?.cancel();
      _stuckDisconnectTimer = null;
      return;
    }

    if (HealthMessengerConnectionRecovery.isSocketInProgress(connectionState)) {
      _disconnectedSince = null;
      _stuckDisconnectTimer?.cancel();
      _stuckDisconnectTimer = null;
      return;
    }

    _disconnectedSince ??= DateTime.now();
    _scheduleStuckDisconnectRecovery();
  }

  void _scheduleStuckDisconnectRecovery() {
    if (_stuckDisconnectTimer != null) {
      return;
    }
    final disconnectedSince = _disconnectedSince ?? DateTime.now();
    final elapsed = DateTime.now().difference(disconnectedSince);
    final remaining =
        HealthMessengerConnectionRecovery.nativeReconnectGrace - elapsed;
    _stuckDisconnectTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () {
        _stuckDisconnectTimer = null;
        unawaited(_recoverIfNeeded(reason: 'socket_stuck'));
      },
    );
  }

  void _unbindConnectionState() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectionBoundSession = null;
    _stuckDisconnectTimer?.cancel();
    _stuckDisconnectTimer = null;
    _disconnectedSince = null;
  }

  bool _sameBootstrapConfig(
    HealthMessengerBootstrapConfig a,
    HealthMessengerBootstrapConfig b,
  ) {
    return a.apiBaseUrl == b.apiBaseUrl &&
        a.socketUrl == b.socketUrl &&
        a.apiKey == b.apiKey &&
        a.externalTenantId == b.externalTenantId &&
        a.externalUserId == b.externalUserId &&
        a.externalUserRole == b.externalUserRole &&
        a.email == b.email &&
        a.displayName == b.displayName &&
        a.profile == b.profile;
  }

  Future<void> _setupPushAfterBootstrap(ChatSession session) async {
    await _teardownPushIntegration();
    final sessionAuth = session.sessionAuth;
    if (sessionAuth == null) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        state = state.copyWith(pushIntegrationReady: false);
        _log('Push bridge skipped (Firebase not initialized).');
        return;
      }

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final push = HealthMessengerPush.instance;
      await push.startListening();
      await _pushEventsSubscription?.cancel();
      _pushEventsSubscription = push.events.listen(_pushEventsController.add);

      await push.syncNativePushConfig(
        config: session.client.config,
        auth: sessionAuth,
      );

      await _pushFirebaseBinding?.detach();
      final binding = MessengerPushFirebaseBinding(
        gate: const MessengerPushGate(),
      );
      await binding.attachForeground(
        chatClient: session.client,
        chatAuth: sessionAuth,
      );
      _pushFirebaseBinding = binding;

      unawaited(push.drainNativeAckQueue());
      state = state.copyWith(pushIntegrationReady: true);
      _log('Push bridge ready');
    } catch (error, stackTrace) {
      state = state.copyWith(pushIntegrationReady: false);
      _log('Push bridge not active', data: {'error': error.toString()});
      debugPrintStack(stackTrace: stackTrace, maxFrames: 12);
    }
  }

  Future<void> _teardownPushIntegration() async {
    await _pushEventsSubscription?.cancel();
    _pushEventsSubscription = null;
    await _pushFirebaseBinding?.detach();
    _pushFirebaseBinding = null;
    await HealthMessengerPush.instance.stopListening();
  }

  void _onDispose() {
    _recoverFuture = null;
    _stopRecoveryWatch();
    _unbindConnectionState();
    _unregisterLifecycleObserver();
    unawaited(_teardownPushIntegration());
    if (!_pushEventsController.isClosed) {
      _pushEventsController.close();
    }
  }

  void _log(String message, {Object? data}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[HealthMessengerSession] $message${data == null ? '' : ' :: $data'}',
    );
  }
}
