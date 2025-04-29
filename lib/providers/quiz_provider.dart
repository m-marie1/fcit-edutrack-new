import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import '../models/quiz_models.dart'; // Import the quiz models
import '../services/api_service.dart';
import 'course_provider.dart'; // Import CourseProvider
// import 'course_provider.dart';

class QuizProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Quiz> _professorQuizzes = []; // Holds sorted list for professor view
  List<Quiz> _studentAvailableQuizzes =
      []; // Holds available quizzes for student view
  final ApiService _apiService = ApiService();
  CourseProvider? _courseProvider; // Needed again for student view

  // Add local drafts storage
  Map<String, dynamic> _localDraft = {};
  bool get hasDraft => _localDraft.isNotEmpty;
  Map<String, dynamic> get localDraft => _localDraft;

  bool get isLoading => _isLoading;
  List<Quiz> get professorQuizzes => _professorQuizzes;
  List<Quiz> get studentAvailableQuizzes => _studentAvailableQuizzes;

  // Method to update CourseProvider dependency (called by ProxyProvider in main.dart)
  void updateCourseProvider(CourseProvider courseProvider) {
    _courseProvider = courseProvider;
    // Optionally trigger fetch if needed, but usually done by the screen
  }

  // Save quiz as local draft
  void saveLocalDraft(Map<String, dynamic> quizData) {
    _localDraft = quizData;
    notifyListeners();
  }

  // Clear local draft
  void clearLocalDraft() {
    _localDraft = {};
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

    return await createQuiz(Quiz.fromJson(_localDraft));
  }

  // Fetch all quizzes created by the professor and sort them
  Future<void> fetchProfessorQuizzes() async {
    _isLoading = true;
    _professorQuizzes = []; // Clear previous quizzes
    notifyListeners();

    try {
      final response = await _apiService.getProfessorQuizzes();

      if (response['success'] && response['data'] != null) {
        final List<dynamic> quizzesData = response['data'];
        List<Quiz> allQuizzes =
            quizzesData.map((json) => Quiz.fromJson(json)).toList();

        // Sort all fetched quizzes, e.g., by end date descending
        allQuizzes.sort((a, b) {
          // Handle potential null dates if necessary, though API seems consistent
          return b.endDate.compareTo(a.endDate); // Descending order
        });

        _professorQuizzes = allQuizzes; // Assign the sorted list directly
        // This line is incorrect and should be removed as active/past separation was removed.

        print(
            "QuizProvider: Fetched and sorted ${_professorQuizzes.length} professor quizzes."); // Corrected print statement
      } else {
        print(
            "QuizProvider: Failed to fetch professor quizzes: ${response['message']}");
        _professorQuizzes = []; // Ensure list is empty on failure
      }
    } catch (e) {
      _professorQuizzes = []; // Clear list on error
      print('QuizProvider: Error fetching professor quizzes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch available quizzes for the student based on their enrolled courses
  Future<void> fetchStudentAvailableQuizzes() async {
    if (_courseProvider == null) {
      print("QuizProvider (Student): CourseProvider not available yet.");
      _studentAvailableQuizzes = [];
      notifyListeners();
      return;
    }
    // Ensure enrolled courses are loaded
    await _courseProvider!
        .ensureEnrolledCoursesFetched(); // Assuming this method exists and works

    final enrolledCourses = _courseProvider!.enrolledCourses;
    if (enrolledCourses.isEmpty) {
      print("QuizProvider (Student): No enrolled courses found.");
      _studentAvailableQuizzes = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _studentAvailableQuizzes = []; // Clear previous list
    notifyListeners();

    List<Quiz> availableQuizzes = [];
    Set<int> fetchedQuizIds =
        {}; // Avoid duplicates if a quiz is in multiple courses

    try {
      for (var course in enrolledCourses) {
        print(
            "QuizProvider (Student): Fetching available quizzes for course ${course.id}");
        final response = await _apiService.getAvailableQuizzes(course.id);

        if (response['success'] && response['data'] != null) {
          final List<dynamic> quizzesData = response['data'];
          for (var quizJson in quizzesData) {
            final quiz = Quiz.fromJson(quizJson);
            // Add only if not already added. The API /available endpoint handles the time check.
            if (quiz.id != null && !fetchedQuizIds.contains(quiz.id!)) {
              // Set the course name here since the API doesn't provide it directly
              final quizWithCourseName = Quiz(
                // Create a new instance with the name
                id: quiz.id,
                title: quiz.title,
                description: quiz.description,
                courseId:
                    quiz.courseId, // Keep original courseId if needed elsewhere
                startDate: quiz.startDate,
                endDate: quiz.endDate,
                durationMinutes: quiz.durationMinutes,
                questions: quiz.questions,
                isPublished: quiz.isPublished,
                courseName: course.courseName, // Set the name
              );
              availableQuizzes.add(quizWithCourseName);
              fetchedQuizIds.add(quiz.id!);
            }
          }
        } else {
          print(
              "QuizProvider (Student): Failed to fetch quizzes for course ${course.id}: ${response['message']}");
        }
      }
      // Sort available quizzes by end date ascending
      availableQuizzes.sort((a, b) {
        if (a.endDate == null && b.endDate == null) return 0;
        return a.endDate.compareTo(b.endDate);
      });

      _studentAvailableQuizzes = availableQuizzes;
      print(
          "QuizProvider (Student): Fetched ${_studentAvailableQuizzes.length} available quizzes.");
    } catch (e) {
      _studentAvailableQuizzes = [];
      print('QuizProvider (Student): Error fetching available quizzes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new quiz
  Future<Map<String, dynamic>> createQuiz(Quiz quiz) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Convert the Quiz object to JSON using its toJson method
      final quizData = quiz.toJson();

      // Remove any isDraft reference before sending to backend
      if (quizData.containsKey('isDraft')) {
        quizData.remove('isDraft');
      }

      final response = await _apiService.createQuiz(quizData);

      if (response['success']) {
        // Refresh the list of quizzes after successful creation
        await fetchProfessorQuizzes();
      }
      return response; // Return the full response map (includes success, message, data)
    } catch (e) {
      print('Error creating quiz: $e');
      return {
        'success': false,
        'message': 'Network error or failed to create quiz.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Edit an existing quiz
  Future<Map<String, dynamic>> editQuiz(int quizId, Quiz quiz) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create a safe version of the update data that won't disturb relationships
      final updateData = {
        'title': quiz.title,
        'description': quiz.description,
        'courseId': quiz.courseId,
        'startDate':
            DateFormat("yyyy-MM-ddTHH:mm:ss").format(quiz.startDate.toUtc()),
        'endDate':
            DateFormat("yyyy-MM-ddTHH:mm:ss").format(quiz.endDate.toUtc()),
        'durationMinutes': quiz.durationMinutes,
        // Omit questions from the update for now to avoid orphan deletion issues
      };

      // Try updating without touching questions
      final response = await _apiService.editQuiz(quizId, updateData);

      if (response['success']) {
        // Refresh the list of quizzes after successful edit
        await fetchProfessorQuizzes();
      }
      return response;
    } catch (e) {
      print('Error editing quiz: $e');
      return {
        'success': false,
        'message': 'Network error or failed to edit quiz: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit Quiz Answers (Student)
  Future<Map<String, dynamic>> submitQuiz(
      int quizId, List<Map<String, dynamic>> answers) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.submitQuiz(quizId, answers);
      // No local state update needed typically, just return response
      return response;
    } catch (e) {
      print('Error submitting quiz: $e');
      return {
        'success': false,
        'message': 'Network error or failed to submit quiz.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start Quiz (Student)
  Future<Map<String, dynamic>> startQuiz(int quizId) async {
    // No need to set loading state for starting, as it's usually a quick call
    // before navigating or enabling the UI. If it fails, we handle it in the UI.
    try {
      final response = await _apiService.startQuiz(quizId);
      // The response might contain the attempt details, which could be stored
      // if needed, but for now, just return the success/failure.
      return response;
    } catch (e) {
      print('Error starting quiz: $e');
      return {
        'success': false,
        'message': 'Network error or failed to start quiz.',
      };
    }
    // No notifyListeners needed here unless we store attempt state
  }

  // Get quiz submissions
  Future<Map<String, dynamic>> getQuizSubmissions(int quizId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getQuizSubmissions(quizId);
      return response;
    } catch (e) {
      print('Error fetching quiz submissions: $e');
      return {
        'success': false,
        'message': 'Failed to fetch submissions: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Download quiz submissions as CSV
  Future<Map<String, dynamic>> downloadQuizSubmissions(int quizId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.downloadQuizSubmissions(quizId);
      if (response['success']) {
        // File was downloaded and opened successfully
        return response;
      } else {
        // Handle specific error cases
        if (response['message']?.contains('No submissions') ?? false) {
          return {
            'success': false,
            'message': 'No submissions available to download.',
          };
        }
        return response;
      }
    } catch (e) {
      print('Error downloading quiz submissions: $e');
      return {
        'success': false,
        'message': 'Failed to download submissions: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get submission details
  Future<Map<String, dynamic>> getSubmissionDetails(
      int quizId, int submissionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.getSubmissionDetails(quizId, submissionId);
      return response;
    } catch (e) {
      print('Error fetching submission details: $e');
      return {
        'success': false,
        'message': 'Failed to fetch submission details: $e',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Add methods for updating, deleting, publishing/unpublishing quizzes if needed
}
