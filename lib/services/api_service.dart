import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Headers with content type
  Map<String, String> _headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token to shared preferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Clear token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Register user
  Future<Map<String, dynamic>> register(
      String username, String password, String fullName, String email) async {
    final response = await http.post(
      Uri.parse(Config.registerUrl),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await http.post(
      Uri.parse(Config.verifyEmailUrl),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['success'] && responseData['data']['token'] != null) {
      await saveToken(responseData['data']['token']);
    }

    return responseData;
  }

  // Login user
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(Config.loginUrl),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['success'] && responseData['data']['token'] != null) {
      await saveToken(responseData['data']['token']);
    }

    return responseData;
  }

  // Login with email
  Future<Map<String, dynamic>> loginWithEmail(
      String email, String password) async {
    final response = await http.post(
      Uri.parse(Config.loginUrl),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['success'] && responseData['data']['token'] != null) {
      await saveToken(responseData['data']['token']);
    }

    return responseData;
  }

  // Change password for authenticated user
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse(Config.changePasswordUrl),
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }

  // Initiate password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      // Uri.parse('${Config.baseUrl}/api/auth/forgot-password'),
      Uri.parse(Config.forgotPasswordUrl),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Reset password with code
  Future<Map<String, dynamic>> resetPassword(
      String email, String resetCode, String newPassword) async {
    final response = await http.post(
      Uri.parse(Config.resetPasswordUrl),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'resetCode': resetCode,
        'newPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }

  // Verify password reset code without changing password
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    final response = await http.post(
      Uri.parse(Config.verifyResetCodeUrl),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'resetCode': code,
      }),
    );

    return jsonDecode(response.body);
  }

  // Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/auth/resend-verification'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
      }),
    );

    return jsonDecode(response.body);
  }

  // Get all courses
  Future<Map<String, dynamic>> getCourses() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(Config.coursesUrl),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // Get current courses
  Future<Map<String, dynamic>> getCurrentCourses() async {
    final token = await _getToken();

    print("Getting current courses from URL: ${Config.currentCoursesUrl}");
    print(
        "Using authorization token: ${token != null ? 'Valid token' : 'No token'}");

    final response = await http.get(
      Uri.parse(Config.currentCoursesUrl),
      headers: _headers(token: token),
    );

    print("Current courses response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // Get enrolled courses
  Future<Map<String, dynamic>> getEnrolledCourses() async {
    final token = await _getToken();

    print("Getting enrolled courses from URL: ${Config.enrolledCoursesUrl}");
    print(
        "Using authorization token: ${token != null ? 'Valid token' : 'No token'}");

    final response = await http.get(
      Uri.parse(Config.enrolledCoursesUrl),
      headers: _headers(token: token),
    );

    print("Enrolled courses response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // Create sample courses
  Future<Map<String, dynamic>> createSampleCourses() async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(Config.sampleCoursesUrl),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // Enroll in a course
  Future<Map<String, dynamic>> enrollInCourse(int courseId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${Config.enrollUrl}/$courseId'),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // Record attendance
  Future<Map<String, dynamic>> recordAttendance(
      int courseId, String verificationCode) async {
    // Changed parameters
    final token = await _getToken();

    print(
        "Recording attendance for course $courseId with code $verificationCode"); // Added log

    final response = await http.post(
      Uri.parse(Config.recordAttendanceUrl),
      headers: _headers(token: token),
      body: jsonEncode({
        'courseId': courseId,
        'verificationCode': verificationCode, // Send verification code
        // 'networkIdentifier': networkIdentifier, // Removed
        // 'verificationMethod': verificationMethod, // Removed
      }),
    );

    return jsonDecode(response.body);
  }

  // Get user attendance for a course
  Future<Map<String, dynamic>> getUserAttendance(
      String userId, int courseId) async {
    final token = await _getToken();

    // If userId is empty or null, return an error
    if (userId.isEmpty) {
      print('Error: Cannot fetch attendance with empty user ID');
      return {
        'success': false,
        'message': 'User ID is required to fetch attendance',
      };
    }

    final response = await http.get(
      Uri.parse('${Config.getUserAttendanceUrl}/$userId/course/$courseId'),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // Get user attendance by username for a course
  Future<Map<String, dynamic>> getUserAttendanceByUsername(
      String username, int courseId) async {
    final token = await _getToken();

    // If username is empty or null, return an error
    if (username.isEmpty) {
      print('Error: Cannot fetch attendance with empty username');
      return {
        'success': false,
        'message': 'Username is required to fetch attendance',
      };
    }

    print("Getting attendance by username: $username for course: $courseId");
    final response = await http.get(
      Uri.parse(
          '${Config.getUserAttendanceByUsernameUrl}/$username/course/$courseId'),
      headers: _headers(token: token),
    );

    print("Response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // Get current user's attendance for a course
  Future<Map<String, dynamic>> getCurrentUserAttendance(int courseId) async {
    final token = await _getToken();

    print("Getting attendance for current user for course: $courseId");
    final response = await http.get(
      Uri.parse('${Config.getCurrentUserAttendanceUrl}/course/$courseId'),
      headers: _headers(token: token),
    );

    print("Response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // Create Attendance Session (Professor Only)
  Future<Map<String, dynamic>> createAttendanceSession(
      int courseId, int expiryMinutes) async {
    final token = await _getToken();

    print(
        "Creating attendance session for course $courseId with expiry $expiryMinutes minutes");

    final response = await http.post(
      Uri.parse(Config.createSessionUrl), // Ensure this URL is in Config
      headers: _headers(token: token),
      body: jsonEncode({
        'courseId': courseId,
        'expiryMinutes': expiryMinutes,
      }),
    );

    print("Create session response status: ${response.statusCode}");
    if (response.statusCode != 201) {
      // Expect 201 Created
      print("Error response body: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // Removed potentially duplicated method here

  // Get Active Sessions (Professor Only)
  Future<Map<String, dynamic>> getActiveSessions() async {
    final token = await _getToken();
    print("Getting active sessions from URL: ${Config.activeSessionsUrl}");
    final response = await http.get(
      Uri.parse(Config.activeSessionsUrl),
      headers: _headers(token: token),
    );
    print("Active sessions response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Get Daily Attendees for Course (Professor Only)
  Future<Map<String, dynamic>> getDailyAttendees(
      int courseId, String date) async {
    // date should be in YYYY-MM-DD format
    final token = await _getToken();
    final url =
        '${Config.dailyAttendeesBaseUrl}/$courseId/date/$date/attendees';
    print(
        "Getting daily attendees for course $courseId on $date from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Daily attendees response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Download Course Attendance Spreadsheet (Professor Only)
  // Returns raw response bytes on success, or a Map on error
  Future<dynamic> downloadAttendanceSpreadsheet(int courseId) async {
    final token = await _getToken();
    final url = '${Config.downloadSpreadsheetBaseUrl}/$courseId/spreadsheet';
    print("Downloading spreadsheet for course $courseId from URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/plain', // Important: Request plain text
        },
      );

      print("Download spreadsheet response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Success: Return the raw bytes
        print(
            "Spreadsheet downloaded successfully (${response.bodyBytes.length} bytes)");
        // Extract filename from Content-Disposition header if needed
        String? filename = response.headers['content-disposition']
            ?.split('filename=')
            .last
            .replaceAll('"', ''); // Basic extraction
        return {
          'success': true,
          'bytes': response.bodyBytes,
          'filename': filename
        };
      } else if (response.statusCode == 204) {
        // No content
        print("No attendance data found for spreadsheet download.");
        return {
          'success': false,
          'message': 'No attendance data found for this course.'
        };
      } else {
        // Other errors
        print("Error downloading spreadsheet: ${response.body}");
        // Try to decode as JSON error message if possible
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Failed to download spreadsheet',
            'statusCode': response.statusCode
          };
        } catch (_) {
          return {
            'success': false,
            'message':
                'Failed to download spreadsheet (Status: ${response.statusCode})',
            'statusCode': response.statusCode
          };
        }
      }
    } catch (e) {
      print("Exception during spreadsheet download: $e");
      return {'success': false, 'message': 'Network error during download.'};
    }
  }

  // Get Session Attendees (Professor Only)
  Future<Map<String, dynamic>> getSessionAttendees(int sessionId) async {
    final token = await _getToken();
    final url = '${Config.sessionAttendeesBaseUrl}/$sessionId/attendees';
    print("Getting attendees for session $sessionId from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Session attendees response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Get active assignments for a course
  Future<Map<String, dynamic>> getActiveAssignments(int courseId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${Config.assignmentsUrl}/active?courseId=$courseId'),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // Get all assignments for a course (Professor Only)
  Future<Map<String, dynamic>> getAllAssignments(int courseId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Config.assignmentsUrl}/all?courseId=$courseId'),
      headers: _headers(token: token),
    );
    return jsonDecode(response.body);
  }

  // Create a new assignment (Professor Only)
  Future<Map<String, dynamic>> createAssignment(
      Map<String, dynamic> assignmentData) async {
    final token = await _getToken();
    print("Creating assignment with data: $assignmentData");
    final response = await http.post(
      Uri.parse(Config.assignmentsUrl),
      headers: _headers(token: token),
      body: jsonEncode(assignmentData),
    );
    print("Create assignment response status: ${response.statusCode}");
    if (response.statusCode != 201) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Submit an assignment (Student Only)
  Future<Map<String, dynamic>> submitAssignment(
      int assignmentId, Map<String, dynamic> submissionData) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/$assignmentId/submit';
    print(
        "Submitting assignment $assignmentId to URL: $url with data: $submissionData");
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(submissionData),
    );
    print("Submit assignment response status: ${response.statusCode}");
    if (response.statusCode != 201) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Edit an assignment submission (Student Only)
  Future<Map<String, dynamic>> editSubmission(
      int submissionId, Map<String, dynamic> submissionData) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/submissions/$submissionId';
    print(
        "Editing submission $submissionId at URL: $url with data: $submissionData");
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(submissionData),
    );
    print("Edit submission response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Edit an assignment (Professor Only)
  Future<Map<String, dynamic>> editAssignment(
      int assignmentId, Map<String, dynamic> assignmentData) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/$assignmentId';
    print(
        "Editing assignment $assignmentId at URL: $url with data: $assignmentData");
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(assignmentData),
    );
    print("Edit assignment response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Fetch submissions for a specific assignment (Professor Only)
  Future<Map<String, dynamic>> getAssignmentSubmissions(
      int assignmentId) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/$assignmentId/submissions';
    print(
        "Getting assignment submissions for assignment $assignmentId from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Get assignment submissions response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // New method to fetch current student's submissions across all assignments
  Future<Map<String, dynamic>> getStudentSubmissions() async {
    final token = await _getToken();
    const url = '${Config.assignmentsUrl}/submissions/student';
    print("Getting current student submissions from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Get student submissions response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Get details for a specific assignment
  Future<Map<String, dynamic>> getAssignmentDetails(int assignmentId) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/$assignmentId';
    print("Getting assignment details for ID $assignmentId from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Get assignment details response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Grade an assignment submission (Professor Only)
  Future<Map<String, dynamic>> gradeAssignmentSubmission(
      int submissionId, Map<String, dynamic> gradeData) async {
    final token = await _getToken();
    final url = '${Config.assignmentsUrl}/submissions/$submissionId/grade';
    print("Grading assignment submission $submissionId with data: $gradeData");
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(gradeData),
    );
    print(
        "Grade assignment submission response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Submit professor request
  Future<dynamic> submitProfessorRequest(
    String fullName,
    String email,
    String department,
    String idImageUrl,
    String additionalInfo,
  ) async {
    try {
      // No token needed for professor requests
      final response = await http.post(
        Uri.parse(Config.professorRequestUrl),
        headers: _headers(), // No token
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'department': department,
          'idImageUrl': idImageUrl,
          'additionalInfo': additionalInfo,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Quiz Endpoints ---

  // Create Quiz (Professor Only)
  Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> quizData) async {
    final token = await _getToken();
    print("Creating quiz with data: $quizData");
    final response = await http.post(
      Uri.parse(Config.quizzesUrl), // Use the base quizzes URL for creation
      headers: _headers(token: token),
      body: jsonEncode(quizData),
    );
    print("Create quiz response status: ${response.statusCode}");
    if (response.statusCode != 201) {
      // Expect 201 Created
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Edit Quiz (Professor Only)
  Future<Map<String, dynamic>> editQuiz(
      int quizId, Map<String, dynamic> quizData) async {
    final token = await _getToken();
    final url = '${Config.quizzesUrl}/$quizId';
    print("Editing quiz $quizId at URL: $url with data: $quizData");
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(quizData),
    );
    print("Edit quiz response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Get Available Quizzes (Used by both Students and Professors)
  Future<Map<String, dynamic>> getAvailableQuizzes(int courseId) async {
    final token = await _getToken();
    // Use the correct config URL now
    final url =
        '${Config.availableQuizzesUrl}?courseId=$courseId'; // Add courseId as query param
    print("Getting available quizzes for course $courseId from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Get available quizzes response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Get Professor's Quizzes
  Future<Map<String, dynamic>> getProfessorQuizzes() async {
    final token = await _getToken();
    const url = Config.myQuizzesUrl; // Ensure this URL is defined in Config
    print("Getting professor's quizzes from URL: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    print("Get professor's quizzes response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Start Quiz (Student Only)
  Future<Map<String, dynamic>> startQuiz(int quizId) async {
    final token = await _getToken();
    final url = '${Config.startQuizBaseUrl}/$quizId/start';
    print("Starting quiz $quizId from URL: $url");
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token: token),
      // No body needed for start
    );
    print("Start quiz response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      // Expect 200 OK
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  // Submit Quiz (Student Only)
  Future<Map<String, dynamic>> submitQuiz(
      int quizId, List<Map<String, dynamic>> answers) async {
    final token = await _getToken();
    final url = '${Config.submitQuizBaseUrl}/$quizId/submit';
    print("Submitting quiz $quizId to URL: $url");
    final payload = {
      'quizId': quizId, // API might infer from URL, but include for clarity
      'answers': answers,
    };
    print("Submission payload: ${jsonEncode(payload)}");

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(payload),
    );
    print("Submit quiz response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      // Expect 200 OK
      print("Error response body: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> downloadQuizSubmissions(int quizId) async {
    try {
      final token = await _getToken();
      final url = '${Config.quizzesUrl}/$quizId/submissions/download';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/csv',
        },
      );

      if (response.statusCode == 200) {
        // Get the filename from the content-disposition header
        String? filename;
        String? disposition = response.headers['content-disposition'];
        if (disposition != null && disposition.contains('filename=')) {
          filename = disposition.split('filename=')[1].replaceAll('"', '');
        }
        filename ??= 'quiz_${quizId}_submissions.csv';

        // Save file to temporary directory (covered by FileProvider's cache-path)
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        final result = await OpenFile.open(file.path);
        if (result.type == ResultType.done) {
          return {
            'success': true,
            'message': 'File downloaded successfully',
            'filePath': file.path
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to open file: ${result.message}'
          };
        }
      }

      return _handleError(response);
    } catch (e) {
      print('Error downloading quiz submissions: $e');
      return {
        'success': false,
        'message': 'Failed to download submissions: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getQuizSubmissions(int quizId) async {
    try {
      final token = await _getToken();
      final url = '${Config.quizzesUrl}/$quizId/submissions';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return _handleError(response);
    } catch (e) {
      print('Error fetching quiz submissions: $e');
      return {
        'success': false,
        'message': 'Failed to fetch submissions: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getSubmissionDetails(
      int quizId, int submissionId) async {
    try {
      final token = await _getToken();
      final url = '${Config.quizzesUrl}/$quizId/submissions/$submissionId';

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return _handleError(response);
    } catch (e) {
      print('Error fetching submission details: $e');
      return {
        'success': false,
        'message': 'Failed to fetch submission details: $e',
      };
    }
  }

  // Helper method to handle error responses
  Map<String, dynamic> _handleError(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    }
  }

  // Get file data with authentication
  Future<http.Response> getFileWithAuth(String fileUrl) async {
    try {
      final token = await _getToken();

      // If the URL is already absolute, use it as is
      final url =
          fileUrl.startsWith('http') ? fileUrl : Config.getFileUrl(fileUrl);

      print("Getting file from URL with auth: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("File response status: ${response.statusCode}");
      return response;
    } catch (e) {
      print("Error getting file: $e");
      // Return a fake response with error status
      return http.Response('{"error": "$e"}', 500);
    }
  }

  // Open a file with proper authentication
  Future<Map<String, dynamic>> openFile(String fileUrl,
      {bool isImage = false}) async {
    try {
      final response = await getFileWithAuth(fileUrl);

      if (response.statusCode == 200) {
        // For images, we return the response with bytes for direct display
        if (isImage) {
          return {
            'success': true,
            'isImage': true,
            'bytes': response.bodyBytes,
            'contentType':
                response.headers['content-type'] ?? 'application/octet-stream',
          };
        }

        // For other files, save to temp directory and open
        final fileName = Config.getFileNameFromUrl(fileUrl);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        final result = await OpenFile.open(file.path);
        if (result.type == ResultType.done) {
          return {
            'success': true,
            'message': 'File opened successfully',
            'filePath': file.path
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to open file: ${result.message}'
          };
        }
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to access this file',
          'statusCode': 403
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve file (Status: ${response.statusCode})',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print("Exception opening file: $e");
      return {
        'success': false,
        'message': 'Error accessing file: $e',
      };
    }
  }

  // --- NEW File Upload Method ---

  /// Uploads a file to the backend server.
  ///
  /// Handles both authenticated (`/api/upload`) and public (`/api/upload/public`) endpoints.
  /// Returns a Map representing the FileInfo object on success, or an error map on failure.
  Future<Map<String, dynamic>> uploadFileToServer(File file,
      {bool requiresAuth = true}) async {
    final String uploadUrl = requiresAuth
        ? Config.authenticatedFileUploadUrl
        : Config.publicFileUploadUrl;
    final String? token = requiresAuth ? await _getToken() : null;

    if (requiresAuth && token == null) {
      print("Error: Authentication token required for upload but not found.");
      return {'success': false, 'message': 'Authentication required.'};
    }

    print("Uploading file to $uploadUrl");
    print("File path: ${file.path}");

    try {
      // Determine content type
      String extension = file.path.split('.').last.toLowerCase();
      String contentTypeString;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentTypeString = 'image/jpeg';
          break;
        case 'png':
          contentTypeString = 'image/png';
          break;
        case 'gif':
          contentTypeString = 'image/gif';
          break;
        case 'pdf':
          contentTypeString = 'application/pdf';
          break;
        case 'doc':
          contentTypeString = 'application/msword';
          break;
        case 'docx':
          contentTypeString =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentTypeString = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentTypeString =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'zip':
          contentTypeString = 'application/zip';
          break;
        // Add other common types as needed
        default:
          contentTypeString = 'application/octet-stream'; // Generic binary type
      }
      final contentType = MediaType.parse(contentTypeString);
      print("Determined content type: $contentTypeString");

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add auth header if needed
      if (requiresAuth && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the file
      final multipartFile = await http.MultipartFile.fromPath(
        'file', // Matches the @RequestParam("file") in the backend
        file.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      print("Sending multipart request...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload response status: ${response.statusCode}");
      print("Upload response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          print("Error: Empty response body from upload endpoint.");
          return {'success': false, 'message': 'Empty response from server'};
        }
        try {
          final decodedResponse = jsonDecode(response.body);
          // Check if the backend response indicates success and contains data
          if (decodedResponse is Map<String, dynamic> &&
              decodedResponse['success'] == true &&
              decodedResponse['data'] != null) {
            // Return the 'data' part which should be the FileInfo map
            return {
              'success': true,
              'data': decodedResponse['data']
                  as Map<String, dynamic> // Ensure data is a Map
            };
          } else {
            print("Error: Upload response indicates failure or missing data.");
            return {
              'success': false,
              'message': decodedResponse['message'] ??
                  'Upload failed: Invalid server response format.',
              'details': decodedResponse // Include full response for debugging
            };
          }
        } catch (e) {
          print("Error parsing upload JSON response: $e");
          return {
            'success': false,
            'message': 'Failed to parse server response.'
          };
        }
      } else {
        // Handle backend error response
        String errorMessage =
            'File upload failed (Status: ${response.statusCode})';
        try {
          final decodedError = jsonDecode(response.body);
          if (decodedError is Map<String, dynamic> &&
              decodedError['message'] != null) {
            errorMessage = decodedError['message'];
          }
        } catch (_) {
          // Ignore parsing error if body is not JSON
        }
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print("Exception during file upload: $e");
      return {
        'success': false,
        'message': 'An error occurred during upload: ${e.toString()}'
      };
    }
  }

  // --- Old Upload Method (kept for reference/potential other uses, but prefer uploadFileToServer) ---

  // Upload file with optional file type parameter
  Future<dynamic> uploadFile(File file, {String? fileType}) async {
    try {
      print(
          "[DEPRECATED] Uploading file to ${Config.publicFileUploadUrl}"); // Mark as deprecated
      print("File path: ${file.path}");
      if (fileType != null) {
        print("File type: $fileType");
      }

      // Determine content type based on file extension
      String extension = file.path.split('.').last.toLowerCase();
      String contentType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'image/jpeg'; // Default to jpeg if unknown
      }

      print("Determined content type: $contentType for extension: $extension");

      var request =
          http.MultipartRequest('POST', Uri.parse(Config.publicFileUploadUrl));

      // Add the file with explicit content type
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Add the file type if provided
      if (fileType != null) {
        request.fields['fileType'] = fileType;
      }

      print(
          "Created multipart request with file: ${multipartFile.filename}, contentType: ${multipartFile.contentType}");
      print("Sending file upload request...");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("File upload response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          print("Warning: Empty response body");
          return {'success': false, 'message': 'Empty response from server'};
        }

        try {
          return jsonDecode(response.body);
        } catch (parseError) {
          print("Error parsing JSON response: $parseError");
          print("Response body was: '${response.body}'");
          return {
            'success': false,
            'message': 'Failed to parse server response',
            'details': parseError.toString()
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server returned status code ${response.statusCode}',
          'details': response.body
        };
      }
    } catch (e) {
      print("Exception in file upload: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get pending professor requests (admin only)
  Future<dynamic> getPendingProfessorRequests() async {
    try {
      final token = await _getToken();
      print(
          "Getting pending professor requests from: ${Config.professorRequestUrl}");
      print("Token: ${token != null ? "Valid token present" : "No token"}");

      final response = await http.get(
        Uri.parse(Config.professorRequestUrl),
        headers: _headers(token: token),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Error fetching professor requests: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Review professor request (admin only)
  Future<dynamic> reviewProfessorRequest(String requestId, bool isApproved,
      {String? rejectionReason}) async {
    try {
      final token = await _getToken();

      print("Reviewing professor request: ID=$requestId, approved=$isApproved");
      print("Using URL: ${Config.professorRequestUrl}/$requestId/review");

      final payload = {
        'approved': isApproved,
        'reviewedBy': 'admin',
        'rejectionReason': rejectionReason,
      };

      print("Request payload: $payload");

      final response = await http.put(
        Uri.parse('${Config.professorRequestUrl}/$requestId/review'),
        headers: _headers(token: token),
        body: jsonEncode(payload),
      );

      print("Review request response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Error reviewing professor request: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Create a new course (admin only)
  Future<dynamic> createCourse(Map<String, dynamic> courseData) async {
    try {
      final token = await _getToken();

      print("Creating course with data: $courseData");
      print("Using URL: ${Config.coursesUrl}");

      final response = await http.post(
        Uri.parse(Config.coursesUrl),
        headers: _headers(token: token),
        body: jsonEncode(courseData),
      );

      print("Create course response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Error creating course: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update an existing course (admin only)
  Future<dynamic> updateCourse(
      int courseId, Map<String, dynamic> courseData) async {
    try {
      final token = await _getToken();

      print("Updating course $courseId with data: $courseData");
      print("Using URL: ${Config.coursesUrl}/$courseId");

      final response = await http.put(
        Uri.parse('${Config.coursesUrl}/$courseId'),
        headers: _headers(token: token),
        body: jsonEncode(courseData),
      );

      print("Update course response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Error updating course: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete a course (admin only)
  Future<dynamic> deleteCourse(int courseId) async {
    try {
      final token = await _getToken();

      print("Deleting course $courseId");
      print("Using URL: ${Config.coursesUrl}/$courseId");

      final response = await http.delete(
        Uri.parse('${Config.coursesUrl}/$courseId'),
        headers: _headers(token: token),
      );

      print("Delete course response status: ${response.statusCode}");
      if (response.statusCode == 204 || response.body.isEmpty) {
        return {'success': true, 'message': 'Course deleted successfully'};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("Error deleting course: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get total classes (number of held classes) for a course
  Future<int?> getTotalClassesForCourse(int courseId) async {
    final token = await _getToken();
    final url =
        '${Config.baseUrl}/api/attendance/sessions/class-days-count/$courseId';
    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] && data['data'] != null) {
        return data['data'] as int;
      }
    }
    return null;
  }
}
