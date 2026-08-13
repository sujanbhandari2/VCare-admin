import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:health_messenger_ui/lib/health_messenger_push.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
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
    return _ensureStartedFuture ??= _ensureStartedInternal();
  }

  Future<void> stopSession() => _stopSession();

  Future<void> _ensureStartedInternal() async {
    state = state.copyWith(
      isBootstrapping: true,
      clearBootstrapError: true,
    );

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
        return;
      }

      await _stopSession(clearInFlight: false);

      final socketLogger =
          SocketPrettyLogger(verboseData: kDebugMode).asChatLogger();
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

      unawaited(_setupPushAfterBootstrap(session));
    } catch (error, stackTrace) {
      _log(
        'Session bootstrap failed',
        data: {
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
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
      _ensureStartedFuture = null;
      state = state.copyWith(isBootstrapping: false);
    }
  }

  Future<void> _stopSession({bool clearInFlight = true}) async {
    if (clearInFlight) {
      _ensureStartedFuture = null;
    }
    _unregisterLifecycleObserver();
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
        data: {
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
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
      _log(
        'Push bridge not active',
        data: {'error': error.toString()},
      );
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
    debugPrint('[HealthMessengerSession] $message${data == null ? '' : ' :: $data'}');
  }
}
