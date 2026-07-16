class MedicareProviderLookupRowModel {
  const MedicareProviderLookupRowModel({
    required this.firstName,
    required this.lastOrOrgName,
    required this.state,
    required this.npi,
    required this.city,
    required this.zip5,
    required this.providerType,
    required this.entityCode,
    required this.street1,
    required this.street2,
    required this.raw,
  });

  factory MedicareProviderLookupRowModel.fromArrays(
    List<String> headers,
    List<String> row,
  ) {
    String get(String key) {
      final index = headers.indexOf(key);
      if (index < 0) return '';
      return index < row.length ? row[index].trim() : '';
    }

    final raw = <String, String>{
      for (var i = 0; i < headers.length; i++)
        headers[i]: i < row.length ? row[i].trim() : '',
    };

    return MedicareProviderLookupRowModel(
      firstName: get('Rndrng_Prvdr_First_Name'),
      lastOrOrgName: get('Rndrng_Prvdr_Last_Org_Name'),
      state: get('Rndrng_Prvdr_State_Abrvtn'),
      npi: get('Rndrng_NPI'),
      city: get('Rndrng_Prvdr_City'),
      zip5: get('Rndrng_Prvdr_Zip5'),
      providerType: get('Rndrng_Prvdr_Type'),
      entityCode: get('Rndrng_Prvdr_Ent_Cd'),
      street1: get('Rndrng_Prvdr_St1'),
      street2: get('Rndrng_Prvdr_St2'),
      raw: raw,
    );
  }

  final String firstName;
  final String lastOrOrgName;
  final String state;
  final String npi;
  final String city;
  final String zip5;
  final String providerType;
  final String entityCode;
  final String street1;
  final String street2;
  final Map<String, String> raw;
}
