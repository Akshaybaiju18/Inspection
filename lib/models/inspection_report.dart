class InspectionReport {
  final String id;
  final String region;
  final String serialNo;
  final String report;

  InspectionReport({
    required this.id,
    required this.region,
    required this.serialNo,
    required this.report,
  });

  /// Convert a JSON Map into an InspectionReport instance.
  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    return InspectionReport(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      region: json['region'] as String? ?? '',
      serialNo: json['serialNo'] as String? ?? '',
      report: json['report'] as String? ?? '',
    );
  }

  /// Convert an InspectionReport instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'serialNo': serialNo,
      'report': report,
    };
  }

  /// Create a copy of this report with modified fields.
  InspectionReport copyWith({
    String? region,
    String? serialNo,
    String? report,
  }) {
    return InspectionReport(
      id: id,
      region: region ?? this.region,
      serialNo: serialNo ?? this.serialNo,
      report: report ?? this.report,
    );
  }
}
