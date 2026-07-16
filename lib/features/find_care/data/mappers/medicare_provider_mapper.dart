import 'package:vcare_admin/features/find_care/data/models/medicare_provider_lookup_row_model.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_service_line.dart';

extension MedicareProviderLookupRowModelMapper on MedicareProviderLookupRowModel {
  MedicareProviderLookupRow toEntity() {
    return MedicareProviderLookupRow(
      npi: npi,
      firstName: firstName,
      lastOrOrgName: lastOrOrgName,
      providerType: providerType,
      entityCode: entityCode,
      street1: street1,
      street2: street2.isEmpty ? null : street2,
      city: city,
      state: state,
      zip5: zip5,
    );
  }

  MedicareProviderListItem toListItem() {
    return MedicareProviderListItem(row: toEntity(), raw: raw);
  }
}

MedicareProviderServiceLine medicareProviderServiceLineFromRaw(
  Map<String, String> raw,
) {
  String get(String key) => raw[key]?.trim() ?? '';

  return MedicareProviderServiceLine(
    hcpcsCode: get('HCPCS_Cd'),
    hcpcsDescription: get('HCPCS_Desc'),
    placeOfService: get('Place_Of_Srvc'),
    drugIndicator: get('HCPCS_Drug_Ind'),
    totalServices: get('Tot_Srvcs'),
    totalBeneficiaries: get('Tot_Benes'),
    averageMedicarePaymentAmount: get('Avg_Mdcr_Pymt_Amt'),
    raw: raw,
  );
}

Map<String, String> rawRowFromArrays(List<String> headers, List<String> row) {
  return {
    for (var i = 0; i < headers.length; i++)
      headers[i]: i < row.length ? row[i].trim() : '',
  };
}
