class ContactSupportResultModel {
  const ContactSupportResultModel({required this.type});

  final String type;

  factory ContactSupportResultModel.fromJson(Map<String, dynamic> json) {
    return ContactSupportResultModel(type: json['type']?.toString() ?? '');
  }
}
