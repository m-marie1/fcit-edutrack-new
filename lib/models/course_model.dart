class Course {
  final int id;
  final String courseCode;
  final String courseName;
  final String description;
  final String startTime;
  final String endTime;
  final List<String> days;

  Course({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      description: json['description'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      days: (json['days'] as List<dynamic>?)
              ?.map((day) => day.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'days': days,
    };
  }
}
