import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:fci_edutrack/providers/course_provider.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:intl/intl.dart';
import 'package:fci_edutrack/screens/assignment/assignment_create_screen.dart';

class AssignmentDraftsScreen extends StatefulWidget {
  static const String routeName = 'assignment_drafts_screen';

  const AssignmentDraftsScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentDraftsScreen> createState() => _AssignmentDraftsScreenState();
}

class _AssignmentDraftsScreenState extends State<AssignmentDraftsScreen> {
  String? _courseName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseNameForDraft();
    });
  }

  void _loadCourseNameForDraft() {
    final assignmentProvider =
        Provider.of<AssignmentProvider>(context, listen: false);
    if (!assignmentProvider.hasDraft) return;

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final draftData = assignmentProvider.localDraft;

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
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title:  Text('Assignment Drafts',style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: MyAppColors.whiteColor
        ),),
        iconTheme: const IconThemeData(
          color: MyAppColors.whiteColor,
        ),
        backgroundColor: MyAppColors.primaryColor,
      ),
      body: !assignmentProvider.hasDraft
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
                                  assignmentProvider.localDraft['title'] ??
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
                            assignmentProvider.localDraft['description'] ??
                                'No description',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Due: ${assignmentProvider.localDraft['dueDate'] != null ? DateFormat.yMd().add_jm().format(DateTime.parse(assignmentProvider.localDraft['dueDate'])) : 'Not set'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Max: ${assignmentProvider.localDraft['maxPoints'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (assignmentProvider
                              .localDraftFiles.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Attached files:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: assignmentProvider.localDraftFiles
                                  .map((f) => Chip(
                                        label: Text(f.name),
                                        backgroundColor: Colors.grey[200],
                                      ))
                                  .toList(),
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
                                            AssignmentCreateScreen.routeName)
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
                                    final result = await assignmentProvider
                                        .publishLocalDraft();
                                    if (result['success']) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Assignment published successfully')),
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
              final assignmentProvider =
                  Provider.of<AssignmentProvider>(context, listen: false);
              assignmentProvider.clearLocalDraft();
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
