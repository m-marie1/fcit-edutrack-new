class Attendance {
  final int id;
  final String studentName;
  final String studentId;
  final String courseCode;
  final String courseName;
  final String timestamp;
  final bool verified;
  final String verificationMethod;

  Attendance({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.courseCode,
    required this.courseName,
    required this.timestamp,
    required this.verified,
    required this.verificationMethod,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentName: json['studentName'] ?? '',
      studentId: json['studentId'] ?? '',
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      // Parse timestamp as UTC, then convert to local
      timestamp:
          DateTime.parse(json['timestamp']).toUtc().toLocal().toIso8601String(),
      verified: json['verified'] ?? false,
      verificationMethod: json['verificationMethod'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'studentId': studentId,
      'courseCode': courseCode,
      'courseName': courseName,
      'timestamp': timestamp,
      'verified': verified,
      'verificationMethod': verificationMethod,
    };
  }
}
