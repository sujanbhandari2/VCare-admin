class FcmDeviceAddedOrUpdatedResponse {
  FcmDeviceAddedOrUpdatedResponse({
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

  FcmDeviceAddedOrUpdatedResponse copyWith({
    int? id,
    String? name,
    String? registrationId,
    String? deviceId,
    bool? active,
    DateTime? dateCreated,
    String? type,
  }) {
    return FcmDeviceAddedOrUpdatedResponse(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationId: registrationId ?? this.registrationId,
      deviceId: deviceId ?? this.deviceId,
      active: active ?? this.active,
      dateCreated: dateCreated ?? this.dateCreated,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return "$id, $name, $registrationId, $deviceId, $active, $dateCreated, $type, ";
  }
}
