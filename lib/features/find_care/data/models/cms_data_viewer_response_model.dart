class CmsDataViewerResponseModel {
  const CmsDataViewerResponseModel({required this.headers, required this.data});

  factory CmsDataViewerResponseModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    final headers = meta is Map
        ? (meta['headers'] as List?)?.map((e) => e.toString()).toList() ?? []
        : <String>[];
    final rawData = json['data'];
    final data = rawData is List
        ? rawData
              .map(
                (row) => row is List
                    ? row.map((cell) => cell?.toString() ?? '').toList()
                    : <String>[],
              )
              .toList()
        : <List<String>>[];

    if (headers.isEmpty) {
      throw const FormatException('Unexpected CMS response');
    }

    return CmsDataViewerResponseModel(headers: headers, data: data);
  }

  final List<String> headers;
  final List<List<String>> data;
}
