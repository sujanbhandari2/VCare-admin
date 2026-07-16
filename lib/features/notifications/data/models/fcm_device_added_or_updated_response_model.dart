class FcmDeviceAddedOrUpdatedResponseModel {
  FcmDeviceAddedOrUpdatedResponseModel({
    this.id,
    this.name,
    this.registrationId,
    this.deviceId,
    this.active,
    this.dateCreated,
    this.type,
  });

  final int? id;
  final String? name;
  final String? registrationId;
  final String? deviceId;
  final bool? active;
  final DateTime? dateCreated;
  final String? type;
  FcmDeviceAddedOrUpdatedResponseModel copyWith({
    int? id,
    String? name,
    String? registrationId,
    String? deviceId,
    bool? active,
    DateTime? dateCreated,
    String? type,
  }) {
    return FcmDeviceAddedOrUpdatedResponseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationId: registrationId ?? this.registrationId,
      deviceId: deviceId ?? this.deviceId,
      active: active ?? this.active,
      dateCreated: dateCreated ?? this.dateCreated,
      type: type ?? this.type,
    );
  }

  factory FcmDeviceAddedOrUpdatedResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FcmDeviceAddedOrUpdatedResponseModel(
      id: json["id"],
      name: json["name"],
      registrationId: json["registration_id"],
      deviceId: json["device_id"],
      active: json["active"],
      dateCreated: DateTime.tryParse(json["date_created"] ?? ""),
      type: json["type"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "registration_id": registrationId,
    "device_id": deviceId,
    "active": active,
    "date_created": dateCreated?.toIso8601String(),
    "type": type,
  };

  @override
  String toString() {
    return "$id, $name, $registrationId, $deviceId, $active, $dateCreated, $type, ";
  }
}
