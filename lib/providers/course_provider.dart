import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Course> _courses = [];
  List<Course> _currentCourses = [];
  List<Course> _enrolledCourses = [];
  final ApiService _apiService = ApiService();

  bool get isLoading => _isLoading;
  List<Course> get courses => _courses;
  List<Course> get currentCourses => _currentCourses;
  List<Course> get enrolledCourses => _enrolledCourses;

  // Fetch all courses
  Future<void> fetchCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getCourses();

      if (response['success'] && response['data'] != null) {
        final List<dynamic> coursesData = response['data'];
        _courses = coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

        // If no courses were found, try to create sample courses
        if (_courses.isEmpty) {
          await createSampleCourses();
          // Fetch courses again after creating samples
          await fetchCourses();
          return;
        }
      }
    } catch (e) {
      print('Error fetching courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch current active courses
  Future<void> fetchCurrentCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      print(
          "Fetching current courses (based on schedule - potentially deprecated)");
      final response = await _apiService
          .getCurrentCourses(); // Keep this for now if needed elsewhere
      print("Current courses API response: ${response['success']}");

      if (response['success'] && response['data'] != null) {
        final List<dynamic> coursesData = response['data'];
        print("Received ${coursesData.length} current courses");

        _currentCourses = coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

        print("Mapped current courses: ${_currentCourses.length} courses");
        if (_currentCourses.isEmpty) {
          print("Warning: No current courses found for the user");
        }
      } else {
        print("Failed to fetch current courses: ${response['message']}");
      }
    } catch (e) {
      print('Error fetching current courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch enrolled courses
  Future<void> fetchEnrolledCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("Fetching enrolled courses for the user");
      final response = await _apiService.getEnrolledCourses();
      print("Enrolled courses API response: ${response['success']}");

      if (response['success'] && response['data'] != null) {
        final List<dynamic> coursesData = response['data'];
        print("Received ${coursesData.length} enrolled courses");

        _enrolledCourses = coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

        print("Mapped enrolled courses: ${_enrolledCourses.length} courses");
        if (_enrolledCourses.isEmpty) {
          print("Warning: No enrolled courses found for the user");
        }
      } else {
        print("Failed to fetch enrolled courses: ${response['message']}");
      }
    } catch (e) {
      print('Error fetching enrolled courses: $e');
      _enrolledCourses = []; // Ensure list is empty on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to specifically fetch enrolled courses if not already loaded
  Future<void> ensureEnrolledCoursesFetched() async {
    // Avoid fetching if already loaded and not loading
    if (_enrolledCourses.isNotEmpty || _isLoading) {
      print("Skipping fetch for enrolled courses (already loaded or loading).");
      return;
    }
    print("ensureEnrolledCoursesFetched: Fetching enrolled courses...");
    await fetchEnrolledCourses(); // Call the existing fetch method
  }

  // Enroll in a course
  Future<Map<String, dynamic>> enrollInCourse(int courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.enrollInCourse(courseId);

      if (response['success']) {
        // Refresh the courses list
        await fetchEnrolledCourses();
      }

      return response;
    } catch (e) {
      print('Error enrolling in course: $e');
      return {
        'success': false,
        'message': 'Network error, please try again later',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create sample courses
  Future<void> createSampleCourses() async {
    try {
      await _apiService.createSampleCourses();
    } catch (e) {
      print('Error creating sample courses: $e');
    }
  }
}
