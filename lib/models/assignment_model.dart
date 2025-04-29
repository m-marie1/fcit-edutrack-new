class Assignment {
  final int id;
  final String title;
  final String description;
  final String dueDate;
  final int maxPoints;
  final List<AssignmentFile>? files;
  final String creationDate;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxPoints,
    this.files,
    this.creationDate = '',
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] ?? '',
      maxPoints: json['maxPoints'] ?? 0,
      files: json['files'] != null
          ? (json['files'] as List)
              .map((f) => AssignmentFile.fromJson(f))
              .toList()
          : null,
      creationDate: json['creationDate'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'maxPoints': maxPoints,
      'files': files?.map((f) => f.toJson()).toList(),
      if (creationDate.isNotEmpty) 'creationDate': creationDate,
    };
  }
}

class AssignmentFile {
  final String fileName;
  final String fileUrl;
  final String contentType;
  final int fileSize;

  AssignmentFile({
    required this.fileName,
    required this.fileUrl,
    required this.contentType,
    required this.fileSize,
  });

  factory AssignmentFile.fromJson(Map<String, dynamic> json) {
    return AssignmentFile(
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      contentType: json['contentType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'contentType': contentType,
      'fileSize': fileSize,
    };
  }
}

class AssignmentSubmission {
  final int id;
  final int studentId;
  final String? studentName;
  final String? assignmentTitle;
  final int assignmentId;
  final String notes;
  final String submissionDate;
  final bool graded;
  final bool late;
  final int? score;
  final String? feedback;
  final String? gradedDate;
  final List<AssignmentFile>? files;

  AssignmentSubmission({
    required this.id,
    required this.studentId,
    this.studentName,
    this.assignmentTitle,
    required this.assignmentId,
    required this.notes,
    required this.submissionDate,
    required this.graded,
    required this.late,
    this.score,
    this.feedback,
    this.gradedDate,
    this.files,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    // Parse student info
    final studentNode = json['student'];
    final int parsedStudentId =
        (studentNode is Map<String, dynamic> && studentNode['id'] != null)
            ? studentNode['id']
            : (json['student'] ?? (json['studentId'] ?? 0));
    final String? parsedStudentName = json['studentName'] != null
        ? json['studentName'] as String?
        : (studentNode is Map<String, dynamic>
            ? studentNode['fullName'] as String?
            : null);
    // Handle API responses without nested 'assignment' object
    final assignmentNode = json['assignment'];
    final parsedAssignmentId =
        (assignmentNode is Map<String, dynamic> && assignmentNode['id'] != null)
            ? assignmentNode['id']
            : (json['assignmentId'] ?? 0);
    final String? parsedAssignmentTitle =
        (assignmentNode is Map<String, dynamic>)
            ? assignmentNode['title'] as String?
            : null;
    return AssignmentSubmission(
      id: json['id'] ?? 0,
      studentId: parsedStudentId,
      studentName: parsedStudentName,
      assignmentTitle: parsedAssignmentTitle,
      assignmentId: parsedAssignmentId,
      notes: json['notes'] ?? '',
      submissionDate: json['submissionDate'] ?? '',
      graded: json['graded'] ?? false,
      late: json['late'] ?? false,
      score: json['score'],
      feedback: json['feedback'],
      gradedDate: json['gradedDate'],
      files: json['files'] != null
          ? (json['files'] as List)
              .map((f) => AssignmentFile.fromJson(f))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      if (assignmentTitle != null) 'assignmentTitle': assignmentTitle,
      'assignmentId': assignmentId,
      'notes': notes,
      'submissionDate': submissionDate,
      'graded': graded,
      'late': late,
      'score': score,
      'feedback': feedback,
      if (gradedDate != null) 'gradedDate': gradedDate,
      'files': files?.map((f) => f.toJson()).toList(),
    };
  }
}
