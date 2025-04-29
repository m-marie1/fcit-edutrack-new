import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/quiz_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:intl/intl.dart';
import 'package:fci_edutrack/screens/professor/quiz_creation_screen.dart';

class QuizDraftsScreen extends StatefulWidget {
  static const String routeName = 'quiz_drafts_screen';

  const QuizDraftsScreen({Key? key}) : super(key: key);

  @override
  State<QuizDraftsScreen> createState() => _QuizDraftsScreenState();
}

class _QuizDraftsScreenState extends State<QuizDraftsScreen> {
  String? _courseName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseNameForDraft();
    });
  }

  void _loadCourseNameForDraft() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    if (!quizProvider.hasDraft) return;

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final draftData = quizProvider.localDraft;

    if (draftData['courseId'] != null) {
      try {
        final course = courseProvider.enrolledCourses
            .firstWhere((course) => course.id == draftData['courseId']);
        setState(() {
          _courseName = course.courseName;
        });
      } catch (e) {
        setState(() {
          _courseName = 'Unknown Course';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Drafts'),
        backgroundColor: MyAppColors.primaryColor,
      ),
      body: !quizProvider.hasDraft
          ? const Center(
              child: Text('No drafts available'),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.purple.shade300, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  quizProvider.localDraft['title'] ??
                                      'Untitled Draft',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DRAFT',
                                  style: TextStyle(
                                    color: Colors.purple.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _courseName ?? 'Loading course...',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quizProvider.localDraft['description'] ??
                                'No description',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Start: ${quizProvider.localDraft['startDate'] != null ? DateFormat.yMd().add_jm().format(DateTime.parse(quizProvider.localDraft['startDate'])) : 'Not set'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.event,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'End: ${quizProvider.localDraft['endDate'] != null ? DateFormat.yMd().add_jm().format(DateTime.parse(quizProvider.localDraft['endDate'])) : 'Not set'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Duration: ${quizProvider.localDraft['durationMinutes'] ?? 0} minutes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          if (quizProvider.localDraft['questions'] != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${(quizProvider.localDraft['questions'] as List?)?.length ?? 0} questions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MyAppColors.primaryColor,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context,
                                            QuizCreationScreen.routeName)
                                        .then((_) {
                                      setState(() {});
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.publish),
                                  label: const Text('Publish'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    final result =
                                        await quizProvider.publishLocalDraft();
                                    if (result['success']) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Quiz published successfully')),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context, true);
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(result['message'] ??
                                                'Failed to publish')),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  _confirmDeleteDraft(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmDeleteDraft(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text(
            'Are you sure you want to delete this draft? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final quizProvider =
                  Provider.of<QuizProvider>(context, listen: false);
              quizProvider.clearLocalDraft();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
