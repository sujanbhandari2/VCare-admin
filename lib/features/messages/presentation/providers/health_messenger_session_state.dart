import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';

class HealthMessengerSessionState {
  const HealthMessengerSessionState({
    this.session,
    this.bootstrapConfig,
    this.isBootstrapping = false,
    this.bootstrapError,
    this.pushIntegrationReady = false,
    this.connectionState = ChatConnectionState.disconnected,
  });

  final ChatSession? session;
  final HealthMessengerBootstrapConfig? bootstrapConfig;
  final bool isBootstrapping;
  final Object? bootstrapError;
  final bool pushIntegrationReady;
  final ChatConnectionState connectionState;

  bool get isReady => session?.sessionAuth != null;

  HealthMessengerSessionState copyWith({
    ChatSession? session,
    HealthMessengerBootstrapConfig? bootstrapConfig,
    bool? isBootstrapping,
    Object? bootstrapError,
    bool clearSession = false,
    bool clearBootstrapConfig = false,
    bool clearBootstrapError = false,
    bool? pushIntegrationReady,
    ChatConnectionState? connectionState,
  }) {
    return HealthMessengerSessionState(
      session: clearSession ? null : session ?? this.session,
      bootstrapConfig: clearBootstrapConfig
          ? null
          : bootstrapConfig ?? this.bootstrapConfig,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      bootstrapError: clearBootstrapError
          ? null
          : bootstrapError ?? this.bootstrapError,
      pushIntegrationReady: pushIntegrationReady ?? this.pushIntegrationReady,
      connectionState: clearSession
          ? ChatConnectionState.disconnected
          : connectionState ?? this.connectionState,
    );
  }
}
