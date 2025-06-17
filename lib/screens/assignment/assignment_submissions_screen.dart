import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:fci_edutrack/config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../style/my_app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  static const String routeName = 'assignment_submissions_screen';
  final int assignmentId;
  const AssignmentSubmissionsScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  bool _initialized = false;
  bool _showGradedOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      Provider.of<AssignmentProvider>(context, listen: false)
          .fetchAssignmentSubmissions(widget.assignmentId);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Assignment Submissions', style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: MyAppColors.whiteColor
        )),
        backgroundColor: MyAppColors.primaryColor,
        actions: [
          IconButton(
            icon: Icon(
                _showGradedOnly ? Icons.filter_list_off : Icons.filter_list,color: MyAppColors.whiteColor,),
            tooltip:
                _showGradedOnly ? 'Show all submissions' : 'Show graded only',
            onPressed: () {
              setState(() {
                _showGradedOnly = !_showGradedOnly;
              });
            },
          ),
        ],
        leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            }, icon: const Icon(Icons.arrow_back_ios,color: MyAppColors.whiteColor,)),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final submissions = provider.assignmentSubmissions;

          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions found.'));
          }

          // Apply filter if needed
          final filteredSubmissions = _showGradedOnly
              ? submissions.where((s) => s.graded).toList()
              : submissions;

          if (filteredSubmissions.isEmpty) {
            return const Center(child: Text('No graded submissions found.'));
          }

          return ListView.builder(
            itemCount: filteredSubmissions.length,
            itemBuilder: (context, index) {
              final submission = filteredSubmissions[index];

              // Check if submission was edited after grading
              bool editedAfterGrading = false;
              if (submission.graded) {
                // Compare submission date with graded date
                final submissionDate =
                    DateTime.parse(submission.submissionDate);
                final gradedDate = submission.gradedDate != null
                    ? DateTime.parse(submission.gradedDate!)
                    : null;
                if (gradedDate != null && submissionDate.isAfter(gradedDate)) {
                  editedAfterGrading = true;
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: editedAfterGrading
                        ? Colors.blue
                            .shade300 // Blue border for edited after grading
                        : (submission.graded
                            ? Colors.green.shade200
                            : Colors.orange.shade200),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      'assignment_grading_screen',
                      arguments: submission,
                    ).then((refreshed) {
                      if (refreshed == true) {
                        Provider.of<AssignmentProvider>(context, listen: false)
                            .fetchAssignmentSubmissions(widget.assignmentId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  MyAppColors.primaryColor.withOpacity(0.2),
                              child: Text(
                                (submission.studentName?.isNotEmpty == true)
                                    ? submission.studentName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: MyAppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    submission.studentName ?? 'Unknown Student',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Submitted: ${DateFormatter.formatDateString(submission.submissionDate)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (editedAfterGrading) // Add indicator for edited after grading
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'EDITED',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (submission.late)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LATE',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (submission.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Notes: ${submission.notes}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (submission.files != null &&
                            submission.files!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: submission.files!.map((file) {
                              bool isImage =
                                  file.contentType.startsWith('image/');

                              return Chip(
                                backgroundColor: Colors.grey[100],
                                avatar: Icon(
                                  isImage ? Icons.image : Icons.attach_file,
                                  size: 16,
                                  color:
                                      isImage ? Colors.blue : Colors.grey[700],
                                ),
                                label: GestureDetector(
                                  onTap: () async {
                                    final apiService = ApiService();
                                    final url = file.fileUrl;
                                    print(
                                        'Opening file: ${Config.getFileUrl(url)}');

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Opening ${file.fileName}...')),
                                    );

                                    if (isImage) {
                                      // For images, we'll load with authentication and show in a dialog
                                      final response = await apiService
                                          .openFile(url, isImage: true);

                                      if (response['success'] &&
                                          response['bytes'] != null) {
                                        final Uint8List imageBytes =
                                            response['bytes'];

                                        if (!mounted) return;

                                        // Show image in dialog
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AppBar(
                                                  title: Text(file.fileName),
                                                  automaticallyImplyLeading:
                                                      false,
                                                  actions: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.close),
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(),
                                                    )
                                                  ],
                                                ),
                                                InteractiveViewer(
                                                  panEnabled: true,
                                                  boundaryMargin:
                                                      const EdgeInsets.all(20),
                                                  minScale: 0.5,
                                                  maxScale: 4,
                                                  child: Image.memory(
                                                    imageBytes,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error displaying image: $error');
                                                      return const Center(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.error,
                                                                color:
                                                                    Colors.red,
                                                                size: 48),
                                                            SizedBox(
                                                                height: 16),
                                                            Text(
                                                                'Could not display image'),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                // Add button to open in external app
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                      Icons.open_in_new),
                                                  label: const Text(
                                                      'Open in external app'),
                                                  onPressed: () async {
                                                    try {
                                                      // Save to temporary file
                                                      final tempDir =
                                                          await getTemporaryDirectory();
                                                      final fileName = file
                                                              .fileName
                                                              .isNotEmpty
                                                          ? file.fileName
                                                          : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                                      final tempFile = File(
                                                          '${tempDir.path}/$fileName');
                                                      await tempFile
                                                          .writeAsBytes(
                                                              imageBytes);

                                                      Navigator.of(ctx)
                                                          .pop(); // Close dialog

                                                      // Open file
                                                      final result =
                                                          await OpenFile.open(
                                                              tempFile.path);
                                                      if (result.type !=
                                                          ResultType.done) {
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Could not open file: ${result.message}')),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      print(
                                                          'Error opening image in external app: $e');
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Error opening image: $e')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  response['message'] ??
                                                      'Could not load image')),
                                        );
                                      }
                                    } else {
                                      // For non-images, open the file
                                      final response =
                                          await apiService.openFile(url);

                                      if (!response['success']) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  response['message'] ??
                                                      'Could not open file')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    file.fileName.length > 20
                                        ? '${file.fileName.substring(0, 17)}...'
                                        : file.fileName,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (submission.graded)
                              Text(
                                'Score: ${submission.score}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              )
                            else
                              Text(
                                'Not Graded',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orange[800],
                                ),
                              ),
                            Icon(
                              submission.graded
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: submission.graded
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
