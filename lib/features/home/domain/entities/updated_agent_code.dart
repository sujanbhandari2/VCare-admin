/// Result of `PATCH agents/agent-code`.
class UpdatedAgentCode {
  const UpdatedAgentCode({
    required this.agentCode,
    this.referralLink,
  });

  final String agentCode;
  final String? referralLink;
}
