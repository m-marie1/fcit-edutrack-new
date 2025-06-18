import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../style/my_app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/date_formatter.dart';
import '../assignment/assignment_submission_screen.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AssignmentDetails extends StatefulWidget {
  static const String routeName = 'assignment_details';

  const AssignmentDetails({super.key});

  @override
  State<AssignmentDetails> createState() => _AssignmentDetailsState();
}

class _AssignmentDetailsState extends State<AssignmentDetails> {
  bool isFilePicked = false;
  PlatformFile? selectedFile;
  bool _isLoading = false;
  late ApiService _apiService;
  late Assignment assignment;

  // Fetch student submissions for this assignment
  List<AssignmentSubmission> studentSubmissions = [];
  bool isLoadingSubmissions = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Assignment) {
      assignment = args;

      // Check if user is a student, and if so, fetch their submissions
      Provider.of<AuthProvider>(context, listen: false)
          .isProfessor()
          .then((isProfessor) {
        if (!isProfessor) {
          fetchStudentSubmissions();
        }
      });
    }
  }

  Future<void> fetchStudentSubmissions() async {
    setState(() {
      isLoadingSubmissions = true;
    });

    final response = await _apiService.getStudentSubmissions();
    if (response['success'] && response['data'] != null) {
      setState(() {
        List<dynamic> allSubmissions = response['data'];

        // Filter submissions for this assignment only
        studentSubmissions = allSubmissions
            .map((json) => AssignmentSubmission.fromJson(json))
            .where((submission) => submission.assignmentId == assignment.id)
            .toList();

        // Sort by submission date (newest first)
        studentSubmissions.sort((a, b) => DateTime.parse(b.submissionDate)
            .compareTo(DateTime.parse(a.submissionDate)));

        isLoadingSubmissions = false;
      });
    } else {
      setState(() {
        studentSubmissions = [];
        isLoadingSubmissions = false;
      });
    }
  }

  Future<void> _openAssignmentFile(AssignmentFile file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool isImage = file.contentType.startsWith('image/');

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${file.fileName}...')),
      );

      if (isImage) {
        // Get image with authentication
        final response =
            await _apiService.openFile(file.fileUrl, isImage: true);

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        if (response['success'] && response['bytes'] != null) {
          final Uint8List imageBytes = response['bytes'];

          // Show image in dialog
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(file.fileName),
                    elevation: 0,
                    backgroundColor: MyAppColors.primaryColor,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  Flexible(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in external app'),
                    onPressed: () async {
                      try {
                        // Save to temporary file
                        final tempDir = await getTemporaryDirectory();
                        final fileName = file.fileName.isNotEmpty
                            ? file.fileName
                            : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final tempFile = File('${tempDir.path}/$fileName');
                        await tempFile.writeAsBytes(imageBytes);

                        Navigator.of(ctx).pop(); // Close dialog

                        // Open file
                        final result = await OpenFile.open(tempFile.path);
                        if (result.type != ResultType.done) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Could not open file: ${result.message}')),
                          );
                        }
                      } catch (e) {
                        print('Error opening image in external app: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error opening image: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Could not load image')),
          );
        }
      } else {
        // For non-images, open the file with authentication
        final response = await _apiService.openFile(file.fileUrl);

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        if (response['success']) {
          // Success handled by the API service (file opened externally)
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error opening file: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to handle editing a submission
  void editSubmission(AssignmentSubmission submission) {
    Navigator.pushNamed(
      context,
      'assignment_submission_screen',
      arguments: {
        'assignment': assignment,
        'existingSubmission': submission,
      },
    ).then((value) {
      if (value == true) {
        // Refresh my submissions
        fetchStudentSubmissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate if due date has passed
    final now = DateTime.now();
    final dueDate = DateTime.parse(assignment.dueDate);
    final dueDatePassed = now.isAfter(dueDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assignment.title,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: MyAppColors.whiteColor),
        ),
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft:
                Radius.circular(MediaQuery.of(context).size.width * 0.1),
            bottomRight:
                Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
        ),
        backgroundColor: MyAppColors.primaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios,color: MyAppColors.whiteColor,),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<bool>(
              future: Provider.of<AuthProvider>(context, listen: false)
                  .isProfessor(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final isProfessor = snapshot.data ?? false;

                return Padding(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assignment title
                        Container(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.019),
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            assignment.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        // Description
                        Text(
                          assignment.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: MyAppColors.lightBlueColor),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        // Due date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due date',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              DateFormatter.formatNonUtcDateString(
                                  assignment.dueDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        // Max Points
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Points',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              assignment.maxPoints.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        // Files
                        if (assignment.files != null &&
                            assignment.files!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Files:',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              ...assignment.files!.map((file) => ListTile(
                                    title: Text(file.fileName),
                                    subtitle: Text(
                                        '${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
                                    trailing: Icon(
                                      file.contentType.startsWith('image/')
                                          ? Icons.image
                                          : Icons.file_present,
                                      color:
                                          file.contentType.startsWith('image/')
                                              ? Colors.blue
                                              : Colors.grey[700],
                                    ),
                                    onTap: () {
                                      _openAssignmentFile(file);
                                    },
                                  )),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        isProfessor
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    'assignment_submissions_screen',
                                    arguments: assignment.id,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyAppColors.primaryColor,
                                ),
                                child: const Text('View Submissions'),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Submit button (show only if due date hasn't passed)
                                  if (!dueDatePassed)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            MyAppColors.primaryColor,
                                      ),
                                      onPressed: () {
                                        // If there's an existing submission, edit it instead of creating a new one
                                        if (studentSubmissions.isNotEmpty) {
                                          editSubmission(
                                              studentSubmissions.first);
                                        } else {
                                          Navigator.pushNamed(
                                            context,
                                            AssignmentSubmissionScreen
                                                .routeName,
                                            arguments: assignment,
                                          ).then((value) {
                                            if (value == true) {
                                              // Refresh my submissions
                                              fetchStudentSubmissions();
                                            }
                                          });
                                        }
                                      },
                                      child: Text(studentSubmissions.isNotEmpty
                                          ? 'Edit Submission'
                                          : 'Submit Assignment'),
                                    ),

                                  // My Submissions section
                                  if (isLoadingSubmissions)
                                    const Center(
                                        child: CircularProgressIndicator())
                                  else if (studentSubmissions.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'My Submissions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: studentSubmissions.length,
                                      itemBuilder: (context, index) {
                                        final submission =
                                            studentSubmissions[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: BorderSide(
                                              color: submission.graded
                                                  ? Colors.green.shade200
                                                  : Colors.orange.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Submission header - restructured to prevent overflow
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Submission date
                                                    Text(
                                                      'Submitted: ${DateFormatter.formatDateString(submission.submissionDate)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 8),

                                                    // Status badges and edit button
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            if (submission
                                                                .graded)
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                          .green[
                                                                      100],
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Text(
                                                                  'GRADED',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                            .green[
                                                                        800],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                            if (submission
                                                                .late) ...[
                                                              if (submission
                                                                  .graded)
                                                                const SizedBox(
                                                                    width: 8),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .red[100],
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Text(
                                                                  'LATE',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                            .red[
                                                                        800],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        // Add Edit button if due date hasn't passed
                                                        if (!dueDatePassed)
                                                          TextButton.icon(
                                                            icon: const Icon(
                                                                Icons.edit,
                                                                color: Colors
                                                                    .blue),
                                                            label: const Text(
                                                                'Edit',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .blue)),
                                                            onPressed: () {
                                                              editSubmission(
                                                                  submission);
                                                            },
                                                            style: TextButton
                                                                .styleFrom(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                if (submission
                                                    .notes.isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Notes: ${submission.notes}',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[700]),
                                                  ),
                                                ],
                                                if (submission.graded &&
                                                    submission.score !=
                                                        null) ...[
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Score: ${submission.score} / ${assignment.maxPoints}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ],
                                                if (submission.graded &&
                                                    submission.feedback !=
                                                        null) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Feedback: ${submission.feedback}',
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ],
                                                if (submission.files != null &&
                                                    submission
                                                        .files!.isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  const Text('Files:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  ...submission.files!
                                                      .map((file) => ListTile(
                                                            title: Text(
                                                                file.fileName),
                                                            subtitle: Text(
                                                                '${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
                                                            trailing: Icon(
                                                              file.contentType
                                                                      .startsWith(
                                                                          'image/')
                                                                  ? Icons.image
                                                                  : Icons
                                                                      .file_present,
                                                              color: file
                                                                      .contentType
                                                                      .startsWith(
                                                                          'image/')
                                                                  ? Colors.blue
                                                                  : Colors.grey[
                                                                      700],
                                                            ),
                                                            onTap: () {
                                                              _openAssignmentFile(
                                                                  file);
                                                            },
                                                          )),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
