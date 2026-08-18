class UserProfile {
  final String name;
  final String employeeCode;

  UserProfile({
    required this.name,
    required this.employeeCode,
  });

  /// Convert JSON map into UserProfile instance.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
    );
  }

  /// Convert UserProfile instance into JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employeeCode': employeeCode,
    };
  }

  /// Create a copy with modified fields.
  UserProfile copyWith({
    String? name,
    String? employeeCode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      employeeCode: employeeCode ?? this.employeeCode,
    );
  }

  /// Helper to check if profile has required values filled
  bool get isComplete => name.trim().isNotEmpty && employeeCode.trim().isNotEmpty;
}
