import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/utils/date_formatter.dart';
import '../../services/api_service.dart';
import '../../providers/assignment_provider.dart';

import '../../themes/theme_provider.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool isProfessor;
  final bool isDraft;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.isProfessor,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          'assignment_details',
          arguments: assignment,
        );
      },
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.024),
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
        decoration: BoxDecoration(
            border: Border.all(
                color: isDraft
                    ? Colors.purple.shade300
                    : (Provider.of<ThemeProvider>(context).isDark()
                        ? Colors.blue.shade800
                        : Colors.grey.shade300),
                width: 2),
            borderRadius: BorderRadius.circular(15)),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Assignment title with draft badge if applicable
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.019),
                    decoration: BoxDecoration(
                        color: MyAppColors.whiteColor,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: MyAppColors.darkBlueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
                if (isDraft)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            // Display creation date if available
            if (assignment.creationDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Created: ${DateFormatter.formatDateString(assignment.creationDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            // Description with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Provider.of<ThemeProvider>(context).isDark()
                            ? MyAppColors.lightBlueColor
                            : MyAppColors.blackColor),
                  ),
                ),
              ],
            ),
            // Due date and max points with icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_available,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Due: ${DateFormatter.formatNonUtcDateString(assignment.dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Max: ${assignment.maxPoints}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            // Files icon and counter
            if (assignment.files != null && assignment.files!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${assignment.files!.length} file(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: assignment.files!
                          .map((f) => TextButton(
                                onPressed: () {
                                  _openFile(context, f);
                                },
                                child: Text(f.fileName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        decoration: TextDecoration.underline)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            // Role-specific actions
            Align(
              alignment: Alignment.bottomRight,
              child: isProfessor
                  ? (isDraft
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.publish),
                          label: const Text('Publish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _publishAssignment(context);
                          },
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit Assignment',
                              color: Colors.blue,
                              onPressed: () {
                                _editAssignment(context);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_turned_in),
                              label: const Text('View Submissions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyAppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  'assignment_submissions_screen',
                                  arguments: assignment.id,
                                );
                              },
                            ),
                          ],
                        ))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyAppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Check if student already has a submission for this assignment
                        final apiService = ApiService();
                        final response =
                            await apiService.getStudentSubmissions();

                        if (response['success'] && response['data'] != null) {
                          List<dynamic> allSubmissions = response['data'];

                          // Look for an existing submission for this assignment
                          final existingSubmissions = allSubmissions
                              .map(
                                  (json) => AssignmentSubmission.fromJson(json))
                              .where((submission) =>
                                  submission.assignmentId == assignment.id)
                              .toList();

                          if (existingSubmissions.isNotEmpty) {
                            // Found existing submission - open in edit mode
                            final result = await Navigator.pushNamed(
                              context,
                              'assignment_submission_screen',
                              arguments: {
                                'assignment': assignment,
                                'existingSubmission': existingSubmissions.first,
                              },
                            );

                            if (result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Assignment updated successfully')));
                            }
                            return;
                          }
                        }

                        // No existing submission, proceed as normal
                        final result = await Navigator.pushNamed(
                          context,
                          'assignment_submission_screen',
                          arguments: assignment,
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Assignment submitted successfully')));
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to open files
  void _openFile(BuildContext context, AssignmentFile file) {
    // Navigate to assignment details instead of handling the file directly
    Navigator.pushNamed(
      context,
      'assignment_details',
      arguments: assignment,
    );
  }

  // Helper method to publish a draft assignment
  void _publishAssignment(BuildContext context) async {
    try {
      // Create a copy of the assignment data
      final Map<String, dynamic> assignmentData = {
        'title': assignment.title,
        'description': assignment.description,
        'dueDate': assignment.dueDate,
        'maxPoints': assignment.maxPoints,
      };

      // Get the assignment provider
      final provider = Provider.of<AssignmentProvider>(context, listen: false);

      // Get any existing files from the assignment
      final files = assignment.files != null
          ? assignment.files!
              .map((f) => {
                    'fileName': f.fileName,
                    'fileUrl': f.fileUrl,
                    'contentType': f.contentType,
                    'fileSize': f.fileSize,
                  })
              .toList()
          : [];

      // Include files in the update data
      assignmentData['files'] = files;

      // Update the assignment
      final result =
          await provider.editAssignment(assignment.id, assignmentData, []);

      if (result['success']) {
        // Refresh the assignments list
        await provider.fetchProfessorAssignments();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment published successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to publish assignment: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing assignment: $e')),
        );
      }
    }
  }

  // Helper method to allow professors to edit assignments
  void _editAssignment(BuildContext context) async {
    try {
      // Navigate to the create assignment screen but pass the existing assignment for editing
      final result = await Navigator.pushNamed(
        context,
        'assignment_create_screen',
        arguments: assignment, // Pass the existing assignment
      );

      if (result == true) {
        // Refresh the assignments list
        final provider =
            Provider.of<AssignmentProvider>(context, listen: false);
        await provider.fetchProfessorAssignments();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment updated successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error editing assignment: $e')),
        );
      }
    }
  }
}
