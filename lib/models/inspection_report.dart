class InspectionReport {
  final String id;
  final String region;
  final String serialNo;
  final String report;
  final String officerName;
  final String employeeCode;

  InspectionReport({
    required this.id,
    required this.region,
    required this.serialNo,
    required this.report,
    this.officerName = '',
    this.employeeCode = '',
  });

  /// Convert a JSON Map into an InspectionReport instance.
  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    return InspectionReport(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      region: json['region'] as String? ?? '',
      serialNo: json['serialNo'] as String? ?? '',
      report: json['report'] as String? ?? '',
      officerName: json['officerName'] as String? ?? json['inspectorName'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
    );
  }

  /// Convert an InspectionReport instance into a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'serialNo': serialNo,
      'report': report,
      'officerName': officerName,
      'employeeCode': employeeCode,
    };
  }

  /// Create a copy of this report with modified fields.
  InspectionReport copyWith({
    String? region,
    String? serialNo,
    String? report,
    String? officerName,
    String? employeeCode,
  }) {
    return InspectionReport(
      id: id,
      region: region ?? this.region,
      serialNo: serialNo ?? this.serialNo,
      report: report ?? this.report,
      officerName: officerName ?? this.officerName,
      employeeCode: employeeCode ?? this.employeeCode,
    );
  }
}
