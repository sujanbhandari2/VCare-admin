import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';

/// Client profile from `GET /clients/:id` or `GET /clients/groups/:id`.
class ClientDetail {
  const ClientDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.dob,
    required this.location,
    required this.gender,
    required this.ssn,
    required this.status,
    required this.allowTextNotification,
    this.clientType = ClientListType.individual,
    this.cardLast4,
    this.cardBrand,
    this.affiliateAgents = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String dob;
  final String location;
  final ClientGender gender;
  final String ssn;
  final String status;
  final bool allowTextNotification;
  final ClientListType clientType;
  final String? cardLast4;
  final String? cardBrand;
  final List<ClientAffiliateAgent> affiliateAgents;
}
