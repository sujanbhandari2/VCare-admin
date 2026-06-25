import 'client_shared_models.dart';

class ClientListItemModel {
  const ClientListItemModel({
    required this.id,
    this.clientType,
    this.name,
    this.dateOfBirth,
    this.metadata,
    this.contact,
    this.address,
    this.joinedAt,
  });

  final String id;
  final String? clientType;
  final ClientNameModel? name;
  final String? dateOfBirth;
  final Map<String, dynamic>? metadata;
  final ClientContactModel? contact;
  final ClientAddressModel? address;
  final String? joinedAt;

  factory ClientListItemModel.fromJson(Map<String, dynamic> json) {
    return ClientListItemModel(
      id: json['id']?.toString() ?? '',
      clientType: json['clientType']?.toString(),
      name: json['name'] is Map<String, dynamic>
          ? ClientNameModel.fromJson(json['name'] as Map<String, dynamic>)
          : null,
      dateOfBirth: json['dateOfBirth']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      contact: json['contact'] is Map<String, dynamic>
          ? ClientContactModel.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
      address: json['address'] is Map<String, dynamic>
          ? ClientAddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      joinedAt: json['joinedAt']?.toString(),
    );
  }
}
