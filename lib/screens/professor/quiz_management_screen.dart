import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
// Keep if needed for permissions later
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import '../../providers/quiz_provider.dart'; // Import QuizProvider
import '../../models/quiz_models.dart';
import '../../models/course_model.dart'; // Import Course model
import '../../providers/course_provider.dart'; // Import CourseProvider
import '../../themes/theme_provider.dart';
import 'quiz_creation_screen.dart'; // Import the creation screen
import 'quiz_submissions_screen.dart'; // Import the submissions screen
import 'quiz_drafts_screen.dart'; // Import the drafts screen
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:timezone/timezone.dart' as tz; // Import timezone library

class QuizManagementScreen extends StatefulWidget {
  static const String routeName = 'quiz_management';

  const QuizManagementScreen({Key? key}) : super(key: key);

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuizzes();
    });
  }

  Future<void> _fetchQuizzes() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    await quizProvider.fetchProfessorQuizzes();
  }

  Future<void> _downloadSubmissions(Quiz quiz) async {
    // Request both read and write permissions
    var statusStorage = await Permission.storage.request();
    var statusExternal = await Permission.manageExternalStorage.request();

    if (statusStorage.isGranted || statusExternal.isGranted) {
      // 2. Permission Granted: Proceed with download
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(width: 16),
                Text('Downloading submissions...'),
              ],
            ),
            duration: Duration(seconds: 10), // Show longer for download
          ),
        );

        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final result = await quizProvider.downloadQuizSubmissions(quiz.id!);

        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Submissions downloaded successfully to ${result['filePath'] ?? 'Downloads'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Failed to download submissions'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar(); // Hide loading on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading submissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (statusStorage.isPermanentlyDenied ||
        statusExternal.isPermanentlyDenied) {
      // Permission Permanently Denied: Guide user to settings
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Storage permission is permanently denied. Please enable it in app settings.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    } else {
      // Permission Denied: Show info message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Storage permission is required to download files. Please grant the permission when requested.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _viewSubmissions(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSubmissionsScreen(
          quizId: quiz.id!,
          quizTitle: quiz.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row(
          children: [
            Icon(Icons.quiz_outlined,color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor,size: 30,),

            Text(
              ' Quiz Management',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: MyAppColors.primaryColor),
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quizProvider, _) {
              if (quizProvider.hasDraft) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Badge(
                    label: const Text("1"),
                    child: IconButton(
                      icon: const Icon(Icons.description),
                      tooltip: 'View Drafts',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          QuizDraftsScreen.routeName,
                        ).then((value) {
                          // Refresh the view when returning from drafts screen
                          if (value == true) {
                            quizProvider.fetchProfessorQuizzes();
                          }
                          // Force refresh to update UI based on draft status
                          setState(() {});
                        });
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading && quizProvider.professorQuizzes.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(
              color: MyAppColors.primaryColor,
            ));
          }
          if (!quizProvider.isLoading &&
              quizProvider.professorQuizzes.isEmpty) {
            return _buildEmptyState();
          }
          return Consumer<CourseProvider>(
            builder: (context, courseProvider, _) =>
                _buildQuizList(quizProvider, courseProvider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyAppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          Navigator.pushNamed(context, QuizCreationScreen.routeName)
              .then((value) {
            // Refresh UI when returning from quiz creation
            setState(() {});
          });
        },
        tooltip: 'Create Quiz',
        child: const Icon(
          Icons.add,
          color: MyAppColors.whiteColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No quizzes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first quiz by tapping the + button',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, QuizCreationScreen.routeName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyAppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Create Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList(
      QuizProvider quizProvider, CourseProvider courseProvider) {
    // Get the single sorted list from the provider
    final allQuizzes = quizProvider.professorQuizzes;
    // final now = DateTime.now(); // No longer needed for separation here

    // Display all quizzes in a single list using ListView.builder
    return RefreshIndicator(
      color: MyAppColors.primaryColor,
      onRefresh: () async {
        await _fetchQuizzes();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = allQuizzes[index];
          // Reuse the item building logic directly here
          final course = courseProvider.enrolledCourses.firstWhere(
            (c) => c.id == quiz.courseId,
            orElse: () => Course(
                // Default/fallback course object
                id: quiz.courseId, // Use the ID from the quiz
                courseCode: 'N/A',
                courseName: 'Unknown', // Keep it short
                description: '',
                startTime: '',
                endTime: '',
                days: []),
          );
          // Create a display string with name and ID
          final String courseNameDisplay =
              '${course.courseName ?? 'Unknown'} (ID: ${quiz.courseId})';

          return Card(
            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    quiz.title,
                    style:  TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.school,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          // Use Expanded to prevent overflow if course name is long
                          Expanded(
                            child: Text(
                              'Course: $courseNameDisplay', // Display name and ID
                              overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                               ),
                            ),
                          ), // Closing parenthesis for Expanded
                        ], // Closing bracket for Row children
                      ), // Closing parenthesis for Row
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.question_answer,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Questions: ${quiz.questions.length}',style: TextStyle(
                            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                          ),),
                          const SizedBox(width: 16),
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${quiz.durationMinutes} minutes',style: TextStyle(
                            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                          ),),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Ends: ${_formatDateTime(quiz.endDate)}',style: TextStyle(
                            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                          ),),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.visibility,
                          color: MyAppColors.primaryColor,
                        ),
                        label: const Text(
                          'Submissions',
                          style: TextStyle(color: MyAppColors.primaryColor),
                        ), // Shortened label
                        onPressed: () => _viewSubmissions(quiz),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.download,
                          color: MyAppColors.primaryColor,
                        ),
                        label: const Text(
                          'Download',
                          style: TextStyle(color: MyAppColors.primaryColor),
                        ), // Shortened label
                        onPressed: () => _downloadSubmissions(quiz),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: MyAppColors.primaryColor),
                        tooltip: 'Edit Quiz',
                        onPressed: () => _editQuiz(quiz),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

  void _showDeleteConfirmation(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Delete quiz "${quiz.title}" coming soon!')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editQuiz(Quiz quiz) {
    // Navigate to the QuizCreationScreen with the quiz to edit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCreationScreen(quizToEdit: quiz),
      ),
    ).then((value) {
      // Refresh the quiz list when returning from editing
      if (value == true) {
        _fetchQuizzes();
      }
    });
  }
}
