class AssignmentModel {
  String subjectName;

  final String topicName;

  final String assignDate;

  final String lastDate;

  final String status;

  AssignmentModel({
    required this.subjectName,
    required this.topicName,
    required this.assignDate,
    required this.lastDate,
    required this.status,
  });
}

List<AssignmentModel> assignments = [
  AssignmentModel(
    subjectName: 'Software Security',
    topicName: 'SQL Injection',
    assignDate: '1-2-2025',
    lastDate: '7-2-2025',
    status: 'pending',
  ),
  AssignmentModel(
    subjectName: 'Software Security',
    topicName: 'SQL Injection',
    assignDate: '1-2-2025',
    lastDate: '7-2-2025',
    status: 'Not Submitted',
  ),
  AssignmentModel(
    subjectName: 'Software Security',
    topicName: 'SQL Injection',
    assignDate: '1-2-2025',
    lastDate: '7-2-2025',
    status: 'Submitted',
  ),
  AssignmentModel(
    subjectName: 'Software Security',
    topicName: 'SQL Injection',
    assignDate: '1-2-2025',
    lastDate: '7-2-2025',
    status: 'pending',
  ),
];
