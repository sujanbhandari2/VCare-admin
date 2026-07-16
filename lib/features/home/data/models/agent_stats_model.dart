class AgentStatsModel {
  const AgentStatsModel({
    required this.totalClients,
    this.totalSales,
    this.totalCommission,
  });

  final int totalClients;
  final String? totalSales;
  final String? totalCommission;

  factory AgentStatsModel.fromJson(Map<String, dynamic> json) {
    final clientsRaw = json['totalClients'];
    final clients = switch (clientsRaw) {
      final int value => value,
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    return AgentStatsModel(
      totalClients: clients,
      totalSales: json['totalSales']?.toString(),
      totalCommission: json['totalCommission']?.toString(),
    );
  }
}
