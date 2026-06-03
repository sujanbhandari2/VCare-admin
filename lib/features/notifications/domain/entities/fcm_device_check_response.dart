class FcmDeviceCheckResponse {
  FcmDeviceCheckResponse({
    this.hasFcmToken = false,
    this.fcmDeviceId,
    this.fcmRegistrationToken,
  });

  final bool hasFcmToken;
  final int? fcmDeviceId;
  final String? fcmRegistrationToken;

  FcmDeviceCheckResponse copyWith({
    bool? hasFcmToken,
    int? fcmDeviceId,
    String? fcmRegistrationToken,
  }) {
    return FcmDeviceCheckResponse(
      hasFcmToken: hasFcmToken ?? this.hasFcmToken,
      fcmDeviceId: fcmDeviceId ?? this.fcmDeviceId,
      fcmRegistrationToken: fcmRegistrationToken ?? this.fcmRegistrationToken,
    );
  }

  @override
  String toString() {
    return "$hasFcmToken, $fcmDeviceId, $fcmRegistrationToken, ";
  }
}
