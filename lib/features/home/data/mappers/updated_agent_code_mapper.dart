import 'package:vcare_admin/features/home/data/models/updated_agent_code_model.dart';
import 'package:vcare_admin/features/home/domain/entities/updated_agent_code.dart';

extension UpdatedAgentCodeModelMapper on UpdatedAgentCodeModel {
  UpdatedAgentCode toEntity() {
    return UpdatedAgentCode(
      agentCode: agentCode,
      referralLink: referralLink,
    );
  }
}
