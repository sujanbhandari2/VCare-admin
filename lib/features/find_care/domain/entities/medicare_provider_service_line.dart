class MedicareProviderServiceLine {
  const MedicareProviderServiceLine({
    required this.hcpcsCode,
    required this.hcpcsDescription,
    required this.placeOfService,
    required this.drugIndicator,
    required this.totalServices,
    required this.totalBeneficiaries,
    required this.averageMedicarePaymentAmount,
    this.raw = const {},
  });

  final String hcpcsCode;
  final String hcpcsDescription;
  final String placeOfService;
  final String drugIndicator;
  final String totalServices;
  final String totalBeneficiaries;
  final String averageMedicarePaymentAmount;
  final Map<String, String> raw;
}
