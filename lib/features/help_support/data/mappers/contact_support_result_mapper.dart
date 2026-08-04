import 'package:vcare_admin/features/help_support/data/models/contact_support_result_model.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_result.dart';

extension ContactSupportResultModelMapper on ContactSupportResultModel {
  ContactSupportResult toEntity() {
    return ContactSupportResult(type: type);
  }
}
