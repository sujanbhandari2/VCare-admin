import 'client.dart';

/// Memberships payload from `GET agents/clients/:id/memberships`.
class ClientMembershipsResult {
  const ClientMembershipsResult({
    required this.clientId,
    required this.memberships,
    required this.totalGroup,
  });

  final String clientId;
  final List<ClientMembership> memberships;
  final int totalGroup;
}
