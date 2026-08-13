import 'client_shared_models.dart';

class ClientListItemModel {
  const ClientListItemModel({
    required this.id,
    this.clientType,
    this.name,
    this.companyName,
    this.contactFirstName,
    this.contactLastName,
    this.dateOfBirth,
    this.metadata,
    this.contact,
    this.address,
    this.joinedAt,
  });

  final String id;
  final String? clientType;
  final ClientNameModel? name;
  final String? companyName;
  final String? contactFirstName;
  final String? contactLastName;
  final String? dateOfBirth;
  final Map<String, dynamic>? metadata;
  final ClientContactModel? contact;
  final ClientAddressModel? address;
  final String? joinedAt;

  bool get isGroup => clientType?.toUpperCase() == 'GROUP';

  factory ClientListItemModel.fromJson(Map<String, dynamic> json) {
    final clientType = json['clientType']?.toString();
    final nameRaw = json['name'];
    final isGroup = clientType?.toUpperCase() == 'GROUP';

    ClientNameModel? name;
    String? companyName = json['companyName']?.toString();
    String? contactFirstName = json['contactFirstName']?.toString();
    String? contactLastName = json['contactLastName']?.toString();

    if (nameRaw is Map<String, dynamic>) {
      if (isGroup || nameRaw.containsKey('companyName')) {
        companyName ??= nameRaw['companyName']?.toString();
        contactFirstName ??= nameRaw['contactFirstName']?.toString();
        contactLastName ??= nameRaw['contactLastName']?.toString();
      } else {
        name = ClientNameModel.fromJson(nameRaw);
      }
    } else if (nameRaw is String && isGroup) {
      companyName ??= nameRaw.trim();
    }

    final contactRaw = json['contact'];
    ClientContactModel? contact;
    if (contactRaw is Map<String, dynamic>) {
      contact = ClientContactModel.fromJson(contactRaw);
      contactFirstName ??= contactRaw['firstName']?.toString();
      contactLastName ??= contactRaw['lastName']?.toString();
    }

    return ClientListItemModel(
      id: json['id']?.toString() ?? '',
      clientType: clientType,
      name: name,
      companyName: companyName,
      contactFirstName: contactFirstName,
      contactLastName: contactLastName,
      dateOfBirth: json['dateOfBirth']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      contact: contact,
      address: json['address'] is Map<String, dynamic>
          ? ClientAddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      joinedAt: json['joinedAt']?.toString(),
    );
  }
}
