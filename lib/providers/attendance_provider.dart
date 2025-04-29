import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  // Store attendance records by course ID
  final Map<int, List<Attendance>> _attendanceRecordsByCourse = {};
  List<Map<String, dynamic>> _activeSessions = []; // Store raw map data for now
  final Map<int, List<Map<String, dynamic>>> _sessionAttendees =
      {}; // Store by session ID
  final Map<String, List<Map<String, dynamic>>> _dailyAttendees =
      {}; // Store by courseId-date key
  // Store total classes per course
  final Map<int, int> _totalClassesByCourse = {};

  final ApiService _apiService = ApiService();

  bool get isLoading => _isLoading;
  Map<int, List<Attendance>> get attendanceRecordsByCourse =>
      _attendanceRecordsByCourse;
  List<Attendance> getAttendanceForCourse(int courseId) =>
      _attendanceRecordsByCourse[courseId] ?? [];
  Map<int, int> get totalClassesByCourse => _totalClassesByCourse;
// Getters for new state variables
  List<Map<String, dynamic>> get activeSessions => _activeSessions;
  List<Map<String, dynamic>> getAttendeesForSession(int sessionId) =>
      _sessionAttendees[sessionId] ?? [];
  List<Map<String, dynamic>> getAttendeesForDay(int courseId, String date) =>
      _dailyAttendees['$courseId-$date'] ?? [];

  // Record attendance for a course
  Future<Map<String, dynamic>> recordAttendance(int courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Since wifi verification is disabled, we'll use a standard method
      final response = await _apiService.recordAttendance(courseId, "MANUAL");

      if (response['success'] && response['data'] != null) {
        // Add the new attendance record to the list for this course
        final newAttendance = Attendance.fromJson(response['data']);

        // Initialize the list if it doesn't exist
        _attendanceRecordsByCourse[courseId] ??= [];

        // Add the new record to this course's list
        _attendanceRecordsByCourse[courseId]!.add(newAttendance);
      }

      return response;
    } catch (e) {
      print('Error recording attendance: $e');
      return {
        'success': false,
        'message': 'Network error, please try again later',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record attendance using verification code
  Future<Map<String, dynamic>> recordAttendanceWithCode(
      int courseId, String verificationCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.recordAttendance(courseId, verificationCode);

      // Optionally update local state if needed, though fetching might be simpler
      // if (response['success'] && response['data'] != null) {
      //   final newAttendance = Attendance.fromJson(response['data']);
      //   _attendanceRecordsByCourse[courseId] ??= [];
      //   _attendanceRecordsByCourse[courseId]!.add(newAttendance);
      // }

      return response;
    } catch (e) {
      print('Error recording attendance with code: $e');
      return {
        'success': false,
        'message': 'Network error or failed to record attendance.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch attendance records for a user in a specific course
  Future<void> fetchUserAttendance(String userId, int courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use the current user endpoint instead of user ID
      final response = await _apiService.getCurrentUserAttendance(courseId);
      print("Response for course $courseId: ${response['success']}");

      if (response['success'] && response['data'] != null) {
        final List<dynamic> attendanceData = response['data'];
        final records = attendanceData
            .map((attendanceJson) => Attendance.fromJson(attendanceJson))
            .toList();

        // Store these records specifically for this course
        _attendanceRecordsByCourse[courseId] = records;
        print(
            "Loaded ${records.length} attendance records for course $courseId");
      } else {
        // If failed, initialize with empty list
        _attendanceRecordsByCourse[courseId] = [];
        print("No attendance records found for course $courseId");
      }
    } catch (e) {
      // If error, initialize with empty list
      _attendanceRecordsByCourse[courseId] = [];
      print('Error fetching attendance records for course $courseId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Active Sessions (Professor)
  Future<void> fetchActiveSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getActiveSessions();
      if (response['success'] && response['data'] != null) {
        _activeSessions = List<Map<String, dynamic>>.from(response['data']);
      } else {
        _activeSessions = [];
        print("Failed to fetch active sessions: ${response['message']}");
      }
    } catch (e) {
      _activeSessions = [];
      print('Error fetching active sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Session Attendees (Professor)
  Future<void> fetchSessionAttendees(int sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getSessionAttendees(sessionId);
      if (response['success'] && response['data'] != null) {
        _sessionAttendees[sessionId] =
            List<Map<String, dynamic>>.from(response['data']);
      } else {
        _sessionAttendees[sessionId] = [];
        print(
            "Failed to fetch attendees for session $sessionId: ${response['message']}");
      }
    } catch (e) {
      _sessionAttendees[sessionId] = [];
      print('Error fetching attendees for session $sessionId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Daily Attendees (Professor)
  Future<void> fetchDailyAttendees(int courseId, String date) async {
    _isLoading = true;
    notifyListeners();
    final key = '$courseId-$date';
    try {
      final response = await _apiService.getDailyAttendees(courseId, date);
      if (response['success'] && response['data'] != null) {
        _dailyAttendees[key] =
            List<Map<String, dynamic>>.from(response['data']);
      } else {
        _dailyAttendees[key] = [];
        print(
            "Failed to fetch daily attendees for $key: ${response['message']}");
      }
    } catch (e) {
      _dailyAttendees[key] = [];
      print('Error fetching daily attendees for $key: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch total classes for a course
  Future<void> fetchTotalClassesForCourse(int courseId) async {
    final total = await _apiService.getTotalClassesForCourse(courseId);
    if (total != null) {
      _totalClassesByCourse[courseId] = total;
      notifyListeners();
    }
  }

  // Download Attendance Spreadsheet (Professor)
  // Returns the API response directly (contains bytes or error message)
  Future<Map<String, dynamic>> downloadAttendanceSpreadsheet(
      int courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // ApiService method now returns a map with success status, bytes/filename or error
      final response =
          await _apiService.downloadAttendanceSpreadsheet(courseId);
      return response;
    } catch (e) {
      print('Error downloading spreadsheet in provider: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Attendance Session (Professor Only)
  Future<Map<String, dynamic>> createAttendanceSession(
      int courseId, int expiryMinutes) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.createAttendanceSession(courseId, expiryMinutes);

      // No local state update needed here, just return the response
      return response;
    } catch (e) {
      print('Error creating attendance session: $e');
      return {
        'success': false,
        'message': 'Network error or failed to create session.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all attendance records
  void clearAttendanceRecords() {
    _attendanceRecordsByCourse.clear();
    notifyListeners();
  }
}
