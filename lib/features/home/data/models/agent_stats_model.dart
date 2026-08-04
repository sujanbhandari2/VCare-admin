class AgentStatsModel {
  const AgentStatsModel({
    required this.totalClients,
    this.totalSales,
    this.totalCommission,
  });

  final int totalClients;
  final double? totalSales;
  final double? totalCommission;

  factory AgentStatsModel.fromJson(Map<String, dynamic> json) {
    final clientsRaw = json['totalClients'];
    final clients = switch (clientsRaw) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    return AgentStatsModel(
      totalClients: clients,
      totalSales: _asDouble(json['totalSales']),
      totalCommission: _asDouble(json['totalCommission']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
