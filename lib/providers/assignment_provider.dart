import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/assignment_model.dart';
import '../services/api_service.dart';
import 'course_provider.dart';

class AssignmentProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Assignment> _professorAssignments = [];
  List<Assignment> _studentAssignments = [];
  List<AssignmentSubmission> _assignmentSubmissions = [];
  final ApiService _apiService = ApiService();
  CourseProvider? _courseProvider;

  // Add local drafts storage
  Map<String, dynamic> _localDraft = {};
  List<PlatformFile> _localDraftFiles = [];

  bool get isLoading => _isLoading;
  List<Assignment> get professorAssignments => _professorAssignments;
  List<Assignment> get studentAssignments => _studentAssignments;
  List<AssignmentSubmission> get assignmentSubmissions =>
      _assignmentSubmissions;

  // Add getters for local draft
  Map<String, dynamic> get localDraft => _localDraft;
  List<PlatformFile> get localDraftFiles => _localDraftFiles;
  bool get hasDraft => _localDraft.isNotEmpty;

  void updateCourseProvider(CourseProvider courseProvider) {
    _courseProvider = courseProvider;
  }

  // Add methods for local draft management
  void saveLocalDraft(
      Map<String, dynamic> draftData, List<PlatformFile> files) {
    _localDraft = draftData;
    _localDraftFiles = files;
    notifyListeners();
  }

  void clearLocalDraft() {
    _localDraft = {};
    _localDraftFiles = [];
    notifyListeners();
  }

  // Publish local draft
  Future<Map<String, dynamic>> publishLocalDraft() async {
    if (!hasDraft) {
      return {
        'success': false,
        'message': 'No draft available to publish',
      };
    }

    return await createAssignment(_localDraft, _localDraftFiles);
  }

  // Fetch all assignments for professor's enrolled courses (not just active)
  Future<void> fetchProfessorAssignments() async {
    _isLoading = true;
    _professorAssignments = [];
    notifyListeners();
    try {
      if (_courseProvider == null) {
        print("AssignmentProvider: CourseProvider not available yet.");
        return;
      }
      await _courseProvider!.fetchEnrolledCourses();
      final courses = _courseProvider!.enrolledCourses;
      if (courses.isEmpty) {
        print("AssignmentProvider: No courses found for professor.");
        return;
      }
      List<Assignment> allAssignments = [];
      for (var course in courses) {
        final response = await _apiService.getAllAssignments(course.id);
        if (response['success'] && response['data'] != null) {
          final List<dynamic> assignmentsData = response['data'];
          allAssignments.addAll(assignmentsData
              .map((json) => Assignment.fromJson(json))
              .toList());
        } else {
          print(
              "AssignmentProvider: Failed to fetch assignments for course ${course.id}: ${response['message']}");
        }
      }
      _professorAssignments = allAssignments;
    } catch (e) {
      _professorAssignments = [];
      print('AssignmentProvider: Error fetching professor assignments: $e');
    } finally {
      // Sort assignments by creation date (most recent first)
      _professorAssignments.sort((a, b) {
        // Handle empty creation dates or null values
        if (a.creationDate.isEmpty && b.creationDate.isEmpty) return 0;
        if (a.creationDate.isEmpty) return 1;
        if (b.creationDate.isEmpty) return -1;

        try {
          // Parse dates and compare them
          DateTime dateA = DateTime.parse(a.creationDate.endsWith('Z')
              ? a.creationDate
              : a.creationDate + 'Z');
          DateTime dateB = DateTime.parse(b.creationDate.endsWith('Z')
              ? b.creationDate
              : b.creationDate + 'Z');
          return dateB.compareTo(dateA); // Most recent first
        } catch (e) {
          print('Error comparing dates: $e');
          return 0;
        }
      });

      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch active assignments for student's enrolled courses
  Future<void> fetchStudentAssignments() async {
    _isLoading = true;
    _studentAssignments = [];
    notifyListeners();
    try {
      if (_courseProvider == null) {
        print("AssignmentProvider: CourseProvider not available yet.");
        return;
      }
      await _courseProvider!.fetchEnrolledCourses();
      final courses = _courseProvider!.enrolledCourses;
      if (courses.isEmpty) {
        print("AssignmentProvider: No courses found for student.");
        return;
      }
      List<Assignment> assignments = [];
      for (var course in courses) {
        final response = await _apiService.getActiveAssignments(course.id);
        if (response['success'] && response['data'] != null) {
          final List<dynamic> assignmentsData = response['data'];
          assignments.addAll(assignmentsData
              .map((json) => Assignment.fromJson(json))
              .toList());
        } else {
          print(
              "AssignmentProvider: Failed to fetch assignments for course ${course.id}: ${response['message']}");
        }
      }
      _studentAssignments = assignments;
    } catch (e) {
      print('AssignmentProvider: Error fetching student assignments: $e');
    } finally {
      // Sort assignments by creation date (most recent first)
      _studentAssignments.sort((a, b) {
        // Handle empty creation dates or null values
        if (a.creationDate.isEmpty && b.creationDate.isEmpty) return 0;
        if (a.creationDate.isEmpty) return 1;
        if (b.creationDate.isEmpty) return -1;

        try {
          // Parse dates and compare them
          DateTime dateA = DateTime.parse(a.creationDate.endsWith('Z')
              ? a.creationDate
              : a.creationDate + 'Z');
          DateTime dateB = DateTime.parse(b.creationDate.endsWith('Z')
              ? b.creationDate
              : b.creationDate + 'Z');
          return dateB.compareTo(dateA); // Most recent first
        } catch (e) {
          print('Error comparing dates: $e');
          return 0;
        }
      });

      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new assignment with file upload
  Future<Map<String, dynamic>> createAssignment(
      Map<String, dynamic> assignmentData, List<PlatformFile> files) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Upload files first using the new method
      List<Map<String, dynamic>> uploadedFilesInfo = [];
      for (var file in files) {
        // Use uploadFileToServer with requiresAuth: true for authenticated uploads
        final uploadResult = await _apiService.uploadFileToServer(
          File(file.path!),
          requiresAuth: true,
        );

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // The 'data' field contains the FileInfo map from the backend
          uploadedFilesInfo.add(uploadResult['data']);
        } else {
          // If any file upload fails, return an error immediately
          print(
              'AssignmentProvider: File upload failed for ${file.name}: ${uploadResult['message']}');
          return {
            'success': false,
            'message':
                'Failed to upload file ${file.name}: ${uploadResult['message']}',
          };
        }
      }
      // Add the list of uploaded FileInfo maps to the assignment data
      assignmentData['files'] = uploadedFilesInfo;

      // Remove any isDraft reference before sending to backend
      if (assignmentData.containsKey('isDraft')) {
        assignmentData.remove('isDraft');
      }

      final response = await _apiService.createAssignment(assignmentData);
      if (response['success']) {
        await fetchProfessorAssignments();
      }
      return response;
    } catch (e) {
      print('AssignmentProvider: Error creating assignment: $e');
      return {
        'success': false,
        'message': 'Failed to create assignment: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit assignment (student)
  Future<Map<String, dynamic>> submitAssignment(
      int assignmentId, String? notes, List<PlatformFile> files) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Upload files first using the new method
      List<Map<String, dynamic>> uploadedFilesInfo = [];
      for (var file in files) {
        // Use uploadFileToServer with requiresAuth: true for authenticated uploads
        final uploadResult = await _apiService.uploadFileToServer(
          File(file.path!),
          requiresAuth: true,
        );

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // The 'data' field contains the FileInfo map from the backend
          uploadedFilesInfo.add(uploadResult['data']);
        } else {
          // If any file upload fails, return an error immediately
          print(
              'AssignmentProvider: File upload failed for ${file.name}: ${uploadResult['message']}');
          return {
            'success': false,
            'message':
                'Failed to upload file ${file.name}: ${uploadResult['message']}',
          };
        }
      }
      // Prepare submission data with uploaded file info
      final submissionData = {
        'assignmentId': assignmentId,
        'notes': notes,
        'files': uploadedFilesInfo, // Use the list of uploaded FileInfo maps
      };
      final response =
          await _apiService.submitAssignment(assignmentId, submissionData);
      return response;
    } catch (e) {
      print('AssignmentProvider: Error submitting assignment: $e');
      return {
        'success': false,
        'message': 'Failed to submit assignment: ${e.toString()}',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Edit submission (student)
  Future<Map<String, dynamic>> editSubmission(
      int submissionId, String? notes, List<PlatformFile> files,
      {required int assignmentId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Upload files first using the new method
      List<Map<String, dynamic>> uploadedFilesInfo = [];
      for (var file in files) {
        // Use uploadFileToServer with requiresAuth: true for authenticated uploads
        final uploadResult = await _apiService.uploadFileToServer(
          File(file.path!),
          requiresAuth: true,
        );

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // The 'data' field contains the FileInfo map from the backend
          uploadedFilesInfo.add(uploadResult['data']);
        } else {
          // If any file upload fails, return an error immediately
          print(
              'AssignmentProvider: File upload failed for ${file.name}: ${uploadResult['message']}');
          return {
            'success': false,
            'message':
                'Failed to upload file ${file.name}: ${uploadResult['message']}',
          };
        }
      }
      // Prepare submission data with uploaded file info
      final submissionData = {
        'notes': notes,
        'files': uploadedFilesInfo, // Use the list of uploaded FileInfo maps
        'assignmentId': assignmentId,
      };
      final response =
          await _apiService.editSubmission(submissionId, submissionData);
      return response;
    } catch (e) {
      print('AssignmentProvider: Error editing submission: $e');
      return {
        'success': false,
        'message': 'Failed to edit submission: ${e.toString()}',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Edit assignment (professor)
  Future<Map<String, dynamic>> editAssignment(int assignmentId,
      Map<String, dynamic> assignmentData, List<PlatformFile> files) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Upload files first using the new method
      List<Map<String, dynamic>> uploadedFilesInfo = [];
      for (var file in files) {
        // Use uploadFileToServer with requiresAuth: true for authenticated uploads
        final uploadResult = await _apiService.uploadFileToServer(
          File(file.path!),
          requiresAuth: true,
        );

        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          // The 'data' field contains the FileInfo map from the backend
          uploadedFilesInfo.add(uploadResult['data']);
        } else {
          // If any file upload fails, return an error immediately
          print(
              'AssignmentProvider: File upload failed for ${file.name}: ${uploadResult['message']}');
          return {
            'success': false,
            'message':
                'Failed to upload file ${file.name}: ${uploadResult['message']}',
          };
        }
      }
      // Add the list of uploaded FileInfo maps to the assignment data
      assignmentData['files'] = uploadedFilesInfo;
      final response =
          await _apiService.editAssignment(assignmentId, assignmentData);
      if (response['success']) {
        await fetchProfessorAssignments();
      }
      return response;
    } catch (e) {
      print('AssignmentProvider: Error editing assignment: $e');
      return {
        'success': false,
        'message': 'Failed to edit assignment: ${e.toString()}',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch submissions for a specific assignment
  Future<void> fetchAssignmentSubmissions(int assignmentId) async {
    _isLoading = true;
    _assignmentSubmissions = [];
    notifyListeners();
    try {
      final response = await _apiService.getAssignmentSubmissions(assignmentId);
      if (response['success'] && response['data'] != null) {
        final List<dynamic> submissionsData = response['data'];
        // Map raw submissions
        final rawSubs = submissionsData
            .map((json) => AssignmentSubmission.fromJson(json))
            .toList();

        // Show all submissions without filtering for the new requirement
        _assignmentSubmissions = rawSubs;

        // Sort by date descending (newest first)
        _assignmentSubmissions.sort((a, b) => DateTime.parse(b.submissionDate)
            .compareTo(DateTime.parse(a.submissionDate)));
      } else {
        print(
            "AssignmentProvider: Failed to fetch submissions: ${response['message']}");
        _assignmentSubmissions = [];
      }
    } catch (e) {
      _assignmentSubmissions = [];
      print('AssignmentProvider: Error fetching assignment submissions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Grade or provide feedback for a submission (if supported by backend)
  Future<Map<String, dynamic>> gradeSubmission(
      int submissionId, Map<String, dynamic> gradeData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response =
          await _apiService.gradeAssignmentSubmission(submissionId, gradeData);
      if (response['success']) {
        // Refresh submissions after grading
        final assignmentId = gradeData['assignmentId'];
        if (assignmentId != null) {
          await fetchAssignmentSubmissions(assignmentId);
        }
      }
      return response;
    } catch (e) {
      print('AssignmentProvider: Error grading submission: $e');
      return {
        'success': false,
        'message': 'Failed to grade submission: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// import 'package:flutter/foundation.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import '../models/assignment_model.dart';
// import '../services/api_service.dart';
// import 'course_provider.dart';

// class AssignmentProvider extends ChangeNotifier {
//   bool _isLoading = false;
//   List<Assignment> _professorAssignments = [];
//   List<Assignment> _studentAssignments = [];
//   List<AssignmentSubmission> _assignmentSubmissions = [];
//   final ApiService _apiService = ApiService();
//   CourseProvider? _courseProvider;

//   // Add local drafts storage
//   Map<String, dynamic> _localDraft = {};
//   List<PlatformFile> _localDraftFiles = [];

//   bool get isLoading => _isLoading;
//   List<Assignment> get professorAssignments => _professorAssignments;
//   List<Assignment> get studentAssignments => _studentAssignments;
//   List<AssignmentSubmission> get assignmentSubmissions =>
//       _assignmentSubmissions;

//   // Add getters for local draft
//   Map<String, dynamic> get localDraft => _localDraft;
//   List<PlatformFile> get localDraftFiles => _localDraftFiles;
//   bool get hasDraft => _localDraft.isNotEmpty;

//   void updateCourseProvider(CourseProvider courseProvider) {
//     _courseProvider = courseProvider;
//   }

//   // Add methods for local draft management
//   void saveLocalDraft(
//       Map<String, dynamic> draftData, List<PlatformFile> files) {
//     _localDraft = draftData;
//     _localDraftFiles = files;
//     notifyListeners();
//   }

//   void clearLocalDraft() {
//     _localDraft = {};
//     _localDraftFiles = [];
//     notifyListeners();
//   }

//   // Publish local draft
//   Future<Map<String, dynamic>> publishLocalDraft() async {
//     if (!hasDraft) {
//       return {
//         'success': false,
//         'message': 'No draft available to publish',
//       };
//     }

//     return await createAssignment(_localDraft, _localDraftFiles);
//   }

//   // Fetch all assignments for professor's enrolled courses (not just active)
//   Future<void> fetchProfessorAssignments() async {
//     _isLoading = true;
//     _professorAssignments = [];
//     notifyListeners();
//     try {
//       if (_courseProvider == null) {
//         print("AssignmentProvider: CourseProvider not available yet.");
//         return;
//       }
//       await _courseProvider!.fetchEnrolledCourses();
//       final courses = _courseProvider!.enrolledCourses;
//       if (courses.isEmpty) {
//         print("AssignmentProvider: No courses found for professor.");
//         return;
//       }
//       List<Assignment> allAssignments = [];
//       for (var course in courses) {
//         final response = await _apiService.getAllAssignments(course.id);
//         if (response['success'] && response['data'] != null) {
//           final List<dynamic> assignmentsData = response['data'];
//           allAssignments.addAll(assignmentsData
//               .map((json) => Assignment.fromJson(json))
//               .toList());
//         } else {
//           print(
//               "AssignmentProvider: Failed to fetch assignments for course ${course.id}: ${response['message']}");
//         }
//       }
//       _professorAssignments = allAssignments;
//     } catch (e) {
//       _professorAssignments = [];
//       print('AssignmentProvider: Error fetching professor assignments: $e');
//     } finally {
//       // Sort assignments by creation date (most recent first)
//       _professorAssignments.sort((a, b) {
//         // Handle empty creation dates or null values
//         if (a.creationDate.isEmpty && b.creationDate.isEmpty) return 0;
//         if (a.creationDate.isEmpty) return 1;
//         if (b.creationDate.isEmpty) return -1;

//         try {
//           // Parse dates and compare them
//           DateTime dateA = DateTime.parse(a.creationDate.endsWith('Z')
//               ? a.creationDate
//               : '${a.creationDate}Z');
//           DateTime dateB = DateTime.parse(b.creationDate.endsWith('Z')
//               ? b.creationDate
//               : '${b.creationDate}Z');
//           return dateB.compareTo(dateA); // Most recent first
//         } catch (e) {
//           print('Error comparing dates: $e');
//           return 0;
//         }
//       });

//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Fetch active assignments for student's enrolled courses
//   Future<void> fetchStudentAssignments() async {
//     _isLoading = true;
//     _studentAssignments = [];
//     notifyListeners();
//     try {
//       if (_courseProvider == null) {
//         print("AssignmentProvider: CourseProvider not available yet.");
//         return;
//       }
//       await _courseProvider!.fetchEnrolledCourses();
//       final courses = _courseProvider!.enrolledCourses;
//       if (courses.isEmpty) {
//         print("AssignmentProvider: No courses found for student.");
//         return;
//       }
//       List<Assignment> assignments = [];
//       for (var course in courses) {
//         final response = await _apiService.getActiveAssignments(course.id);
//         if (response['success'] && response['data'] != null) {
//           final List<dynamic> assignmentsData = response['data'];
//           assignments.addAll(assignmentsData
//               .map((json) => Assignment.fromJson(json))
//               .toList());
//         } else {
//           print(
//               "AssignmentProvider: Failed to fetch assignments for course ${course.id}: ${response['message']}");
//         }
//       }
//       _studentAssignments = assignments;
//     } catch (e) {
//       print('AssignmentProvider: Error fetching student assignments: $e');
//     } finally {
//       // Sort assignments by creation date (most recent first)
//       _studentAssignments.sort((a, b) {
//         // Handle empty creation dates or null values
//         if (a.creationDate.isEmpty && b.creationDate.isEmpty) return 0;
//         if (a.creationDate.isEmpty) return 1;
//         if (b.creationDate.isEmpty) return -1;

//         try {
//           // Parse dates and compare them
//           DateTime dateA = DateTime.parse(a.creationDate.endsWith('Z')
//               ? a.creationDate
//               : '${a.creationDate}Z');
//           DateTime dateB = DateTime.parse(b.creationDate.endsWith('Z')
//               ? b.creationDate
//               : '${b.creationDate}Z');
//           return dateB.compareTo(dateA); // Most recent first
//         } catch (e) {
//           print('Error comparing dates: $e');
//           return 0;
//         }
//       });

//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Create a new assignment with file upload
//   Future<Map<String, dynamic>> createAssignment(
//       Map<String, dynamic> assignmentData, List<PlatformFile> files) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       // Upload files first
//       List<Map<String, dynamic>> uploadedFiles = [];
//       for (var file in files) {
//         final uploadResult = await _apiService.uploadFile(File(file.path!));
//         if (uploadResult['success'] == true && uploadResult['data'] != null) {
//           final fileData = uploadResult['data'];
//           uploadedFiles.add({
//             'fileName': fileData['fileName'] ?? file.name,
//             'fileUrl': fileData['fileUrl'],
//             'contentType': fileData['contentType'] ?? '',
//             'fileSize': fileData['fileSize'] ?? file.size
//           });
//         } else {
//           print(
//               'AssignmentProvider: File upload failed: ${uploadResult['message']}');
//         }
//       }
//       assignmentData['files'] = uploadedFiles;

//       // Remove any isDraft reference before sending to backend
//       if (assignmentData.containsKey('isDraft')) {
//         assignmentData.remove('isDraft');
//       }

//       final response = await _apiService.createAssignment(assignmentData);
//       if (response['success']) {
//         await fetchProfessorAssignments();
//       }
//       return response;
//     } catch (e) {
//       print('AssignmentProvider: Error creating assignment: $e');
//       return {
//         'success': false,
//         'message': 'Failed to create assignment: $e',
//       };
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Submit assignment (student)
//   Future<Map<String, dynamic>> submitAssignment(
//       int assignmentId, String? notes, List<PlatformFile> files) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       List<Map<String, dynamic>> uploadedFiles = [];
//       for (var file in files) {
//         final uploadResult = await _apiService.uploadFile(File(file.path!));
//         if (uploadResult['success'] == true && uploadResult['data'] != null) {
//           final fileData = uploadResult['data'];
//           uploadedFiles.add({
//             'fileName': fileData['fileName'] ?? file.name,
//             'fileUrl': fileData['fileUrl'],
//             'contentType': fileData['contentType'] ?? '',
//             'fileSize': fileData['fileSize'] ?? file.size
//           });
//         } else {
//           print(
//               'AssignmentProvider: File upload failed: ${uploadResult['message']}');
//         }
//       }
//       final submissionData = {
//         'assignmentId': assignmentId,
//         'notes': notes,
//         'files': uploadedFiles,
//       };
//       final response =
//           await _apiService.submitAssignment(assignmentId, submissionData);
//       return response;
//     } catch (e) {
//       print('AssignmentProvider: Error submitting assignment: $e');
//       return {
//         'success': false,
//         'message': 'Failed to submit assignment: $e',
//       };
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Edit submission (student)
//   Future<Map<String, dynamic>> editSubmission(
//       int submissionId, String? notes, List<PlatformFile> files,
//       {required int assignmentId}) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       List<Map<String, dynamic>> uploadedFiles = [];
//       for (var file in files) {
//         final uploadResult = await _apiService.uploadFile(File(file.path!));
//         if (uploadResult['success'] == true && uploadResult['data'] != null) {
//           final fileData = uploadResult['data'];
//           uploadedFiles.add({
//             'fileName': fileData['fileName'] ?? file.name,
//             'fileUrl': fileData['fileUrl'],
//             'contentType': fileData['contentType'] ?? '',
//             'fileSize': fileData['fileSize'] ?? file.size
//           });
//         } else {
//           print(
//               'AssignmentProvider: File upload failed: ${uploadResult['message']}');
//         }
//       }
//       final submissionData = {
//         'notes': notes,
//         'files': uploadedFiles,
//         'assignmentId': assignmentId,
//       };
//       final response =
//           await _apiService.editSubmission(submissionId, submissionData);
//       return response;
//     } catch (e) {
//       print('AssignmentProvider: Error editing submission: $e');
//       return {
//         'success': false,
//         'message': 'Failed to edit submission: $e',
//       };
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Edit assignment (professor)
//   Future<Map<String, dynamic>> editAssignment(int assignmentId,
//       Map<String, dynamic> assignmentData, List<PlatformFile> files) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       // Upload files first
//       List<Map<String, dynamic>> uploadedFiles = [];
//       for (var file in files) {
//         final uploadResult = await _apiService.uploadFile(File(file.path!));
//         if (uploadResult['success'] == true && uploadResult['data'] != null) {
//           final fileData = uploadResult['data'];
//           uploadedFiles.add({
//             'fileName': fileData['fileName'] ?? file.name,
//             'fileUrl': fileData['fileUrl'],
//             'contentType': fileData['contentType'] ?? '',
//             'fileSize': fileData['fileSize'] ?? file.size
//           });
//         } else {
//           print(
//               'AssignmentProvider: File upload failed: ${uploadResult['message']}');
//         }
//       }
//       assignmentData['files'] = uploadedFiles;
//       final response =
//           await _apiService.editAssignment(assignmentId, assignmentData);
//       if (response['success']) {
//         await fetchProfessorAssignments();
//       }
//       return response;
//     } catch (e) {
//       print('AssignmentProvider: Error editing assignment: $e');
//       return {
//         'success': false,
//         'message': 'Failed to edit assignment: $e',
//       };
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Fetch submissions for a specific assignment
//   Future<void> fetchAssignmentSubmissions(int assignmentId) async {
//     _isLoading = true;
//     _assignmentSubmissions = [];
//     notifyListeners();
//     try {
//       final response = await _apiService.getAssignmentSubmissions(assignmentId);
//       if (response['success'] && response['data'] != null) {
//         final List<dynamic> submissionsData = response['data'];
//         // Map raw submissions
//         final rawSubs = submissionsData
//             .map((json) => AssignmentSubmission.fromJson(json))
//             .toList();

//         // Show all submissions without filtering for the new requirement
//         _assignmentSubmissions = rawSubs;

//         // Sort by date descending (newest first)
//         _assignmentSubmissions.sort((a, b) => DateTime.parse(b.submissionDate)
//             .compareTo(DateTime.parse(a.submissionDate)));
//       } else {
//         print(
//             "AssignmentProvider: Failed to fetch submissions: ${response['message']}");
//         _assignmentSubmissions = [];
//       }
//     } catch (e) {
//       _assignmentSubmissions = [];
//       print('AssignmentProvider: Error fetching assignment submissions: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Grade or provide feedback for a submission (if supported by backend)
//   Future<Map<String, dynamic>> gradeSubmission(
//       int submissionId, Map<String, dynamic> gradeData) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       final response =
//           await _apiService.gradeAssignmentSubmission(submissionId, gradeData);
//       if (response['success']) {
//         // Refresh submissions after grading
//         final assignmentId = gradeData['assignmentId'];
//         if (assignmentId != null) {
//           await fetchAssignmentSubmissions(assignmentId);
//         }
//       }
//       return response;
//     } catch (e) {
//       print('AssignmentProvider: Error grading submission: $e');
//       return {
//         'success': false,
//         'message': 'Failed to grade submission: $e',
//       };
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
