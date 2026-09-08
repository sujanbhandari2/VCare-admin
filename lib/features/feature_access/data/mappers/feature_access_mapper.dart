import 'package:vcare_admin/features/feature_access/data/models/feature_access_model.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';

extension FeatureAccessModelMapper on FeatureAccessModel {
  FeatureAccess toEntity() {
    return FeatureAccess(
      caseManagement: caseManagement,
      healthChat: healthChat,
      membership: membership,
    );
  }
}

extension FeatureAccessEntityMapper on FeatureAccess {
  FeatureAccessModel toModel() {
    return FeatureAccessModel(
      caseManagement: caseManagement,
      healthChat: healthChat,
      membership: membership,
    );
  }
}
