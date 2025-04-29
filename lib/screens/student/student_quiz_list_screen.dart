import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz; // Import timezone library

import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/quiz_models.dart';
import '../../models/course_model.dart'; // Import Course model
import '../../style/my_app_colors.dart';
import 'quiz_taking_screen.dart'; // Import the Quiz Taking Screen

class StudentQuizListScreen extends StatefulWidget {
  static const String routeName = 'student_quiz_list';

  const StudentQuizListScreen({Key? key}) : super(key: key);

  @override
  _StudentQuizListScreenState createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch quizzes when the screen initializes
    // The QuizProvider needs the CourseProvider, which is handled by ChangeNotifierProxyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure courses are fetched first if needed, then fetch quizzes
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      courseProvider.ensureEnrolledCoursesFetched().then((_) {
        if (mounted) {
          // Fetch available quizzes specifically for the student
          quizProvider.fetchStudentAvailableQuizzes();
        }
      });
    });
  }

  Future<void> _refreshQuizzes() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    // Ensure courses are fetched before fetching quizzes on refresh
    await courseProvider.ensureEnrolledCoursesFetched();
    if (mounted) {
      await quizProvider.fetchStudentAvailableQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Quizzes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: MyAppColors.primaryColor,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          return RefreshIndicator(
            onRefresh: _refreshQuizzes,
            // Also consume CourseProvider here to pass it down
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, _) =>
                  _buildQuizList(quizProvider, courseProvider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizList(
      QuizProvider quizProvider, CourseProvider courseProvider) {
    // Use studentAvailableQuizzes list and check its loading state
    if (quizProvider.isLoading &&
        quizProvider.studentAvailableQuizzes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final quizzes = quizProvider.studentAvailableQuizzes;

    if (quizzes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No quizzes available for your enrolled courses at the moment.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    // TODO: Potentially group quizzes by course later if needed
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final Quiz quiz = quizzes[index];
        // Get course name from CourseProvider's enrolledCourses list
        final course = courseProvider.enrolledCourses.firstWhere(
          (c) => c.id == quiz.courseId,
          orElse: () => Course(
              id: 0,
              courseCode: 'N/A',
              courseName: 'Unknown Course',
              description: '',
              startTime: '',
              endTime: '',
              days: []), // Provide a default Course object
        );
        // Create a display string with name and ID
        final String courseNameDisplay =
            '${course.courseName ?? 'Unknown'} (ID: ${quiz.courseId})';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Course: $courseNameDisplay'), // Display name and ID
                const SizedBox(height: 4),
                Text('Description: ${quiz.description}'),
                const SizedBox(height: 4),
                Text('Questions: ${quiz.questions.length}'),
                const SizedBox(height: 4),
                Text('Duration: ${quiz.durationMinutes} minutes'),
                const SizedBox(height: 4),
                Text('Available until: ${_formatDateTime(quiz.endDate)}'),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyAppColors.secondaryBlueColor,
              ),
              onPressed: () {
                // Navigate to Quiz Taking Screen, passing the quiz object
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizTakingScreen(quiz: quiz),
                  ),
                );
              },
              child: const Text('Start Quiz'),
            ),
          ),
        );
      },
    );
  }

  // Helper function to format DateTime using timezone package
  String _formatDateTime(DateTime utcDate) {
    try {
      // Ensure the input date is treated as UTC if it's not already
      final DateTime ensuredUtcDate = utcDate.isUtc ? utcDate : utcDate.toUtc();

      // Get the location for Africa/Cairo
      final location = tz.getLocation('Africa/Cairo');

      // Convert the UTC DateTime to a TZDateTime in the target location
      final localDate = tz.TZDateTime.from(ensuredUtcDate, location);

      // Format the TZDateTime
      return DateFormat('MMM d, yyyy h:mm a').format(localDate);
    } catch (e) {
      print("Error formatting date with timezone: $e");
      // Fallback to local time display without UTC suffix
      return DateFormat('MMM d, yyyy h:mm a').format(utcDate.toLocal());
    }
  }
}
