import 'client.dart';

/// Client profile returned by `GET agents/clients/:id`.
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
    this.cardLast4,
    this.cardBrand,
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
  final String? cardLast4;
  final String? cardBrand;
}
