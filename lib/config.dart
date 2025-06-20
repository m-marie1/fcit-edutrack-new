class Config {
  // Base URL for the backend API
  static const String baseUrl =
      'https://edutrack-backend-orms.onrender.com/api';

  // Base URL without the /api suffix for direct resource access
  static const String baseResourceUrl =
      'https://edutrack-backend-orms.onrender.com';

  // File access endpoints
  static const String filesUrl = '$baseUrl/api/files';
  static const String professorIdFilesUrl = '$baseUrl/api/files/professor-id';

  // Authentication endpoints
  static const String registerUrl = '$baseUrl/api/auth/register';
  static const String loginUrl = '$baseUrl/api/auth/login';

  // Password management endpoints
  static const String changePasswordUrl = '$baseUrl/api/auth/change-password';
  static const String resetPasswordUrl = '$baseUrl/api/auth/reset-password';
  static const String forgotPasswordUrl = '$baseUrl/api/auth/forgot-password';
  static const String verifyEmailUrl = '$baseUrl/api/auth/verify-email';
  static const String verifyResetCodeUrl =
      '$baseUrl/api/auth/verify-reset-code';

  // Course endpoints
  static const String coursesUrl = '$baseUrl/api/courses';
  static const String currentCoursesUrl = '$baseUrl/api/courses/current';
  static const String enrolledCoursesUrl = '$baseUrl/api/courses/enrolled';
  static const String sampleCoursesUrl = '$baseUrl/api/courses/sample';

  // Attendance endpoints
  static const String enrollUrl = '$baseUrl/api/attendance/enroll';
  static const String recordAttendanceUrl = '$baseUrl/api/attendance/record';
  static const String getUserAttendanceUrl = '$baseUrl/api/attendance/user';
  static const String getUserAttendanceByUsernameUrl =
      '$baseUrl/api/attendance/user/username';
  static const String getCurrentUserAttendanceUrl =
      '$baseUrl/api/attendance/user/current';
  static const String createSessionUrl =
      '$baseUrl/api/attendance/sessions/create';
  static const String activeSessionsUrl =
      '$baseUrl/api/attendance/sessions/active'; // Added
  static const String sessionAttendeesBaseUrl =
      '$baseUrl/api/attendance/sessions'; // Added (base for /sessionId/attendees)
  static const String dailyAttendeesBaseUrl =
      '$baseUrl/api/attendance/course'; // Added (base for /courseId/date/YYYY-MM-DD/attendees)
  static const String downloadSpreadsheetBaseUrl =
      '$baseUrl/api/attendance/course'; // Added (base for /courseId/spreadsheet)

  // Quiz endpoints
  static const String quizzesUrl = '$baseUrl/api/quizzes'; // Base for CRUD
  static const String availableQuizzesUrl =
      '$baseUrl/api/quizzes/available'; // Base URL for available quizzes (add ?courseId=X)
  static const String myQuizzesUrl =
      '$baseUrl/api/quizzes/my-quizzes'; // Base URL for professor's quizzes
  static const String quizSubmissionsUrl =
      '$baseUrl/api/quizzes'; // Base URL for /{quizId}/submissions
  static const String downloadQuizSubmissionsUrl =
      '$baseUrl/api/quizzes'; // Base URL for /{quizId}/submissions/download
  static const String quizSubmissionDetailsUrl =
      '$baseUrl/api/quizzes'; // Base URL for /{quizId}/submissions/{submissionId}
  // Note: Start and Submit use the base quizzesUrl + quizId + /action
  static const String startQuizBaseUrl =
      '$baseUrl/api/quizzes'; // Base for /<quizId>/start
  static const String submitQuizBaseUrl =
      '$baseUrl/api/quizzes'; // Base for /<quizId>/submit

  // Assignment endpoints
  static const String assignmentsUrl = '$baseUrl/api/assignments';

  // File upload endpoint
  static const String authenticatedFileUploadUrl =
      '$baseUrl/api/upload'; // Renamed for clarity
  static const String publicFileUploadUrl = '$baseUrl/api/upload/public';

  // Professor request endpoint
  static const String professorRequestUrl = '$baseUrl/api/professor-requests';

  // Allowed MAC address endpoints
  static const String allowedMacsUrl = '$baseUrl/api/allowed-mac-addresses';
  static const String allowedMacAdminUrl =
      '$baseUrl/api/admin/allowed-mac-addresses';

  // Helper method to get the full URL for a file path
  static String getFileUrl(String filePath) {
    // If the path already contains the full URL, return it as is
    if (filePath.startsWith('http')) {
      return filePath;
    }

    // If path starts with "/api/files/professor-id", use the professor ID files URL
    if (filePath.startsWith('/api/files/professor-id/')) {
      String fileName = filePath.substring('/api/files/professor-id/'.length);
      return '$professorIdFilesUrl/$fileName';
    }

    // For regular files that start with "/api/files/"
    if (filePath.startsWith('/api/files/')) {
      String fileName = filePath.substring('/api/files/'.length);
      return '$filesUrl/$fileName';
    }

    // For any other path, just append to base URL
    return '$baseResourceUrl$filePath';
  }

  // Get the file name from a file URL
  static String getFileNameFromUrl(String fileUrl) {
    Uri uri = Uri.parse(fileUrl);
    return uri.pathSegments.last;
  }
}
