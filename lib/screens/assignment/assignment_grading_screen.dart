import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:fci_edutrack/config.dart';
import '../../style/my_app_colors.dart';
import '../../themes/theme_provider.dart';
import '../../utils/date_formatter.dart';
import '../../services/api_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class AssignmentGradingScreen extends StatefulWidget {
  static const String routeName = 'assignment_grading_screen';
  final AssignmentSubmission submission;

  const AssignmentGradingScreen({Key? key, required this.submission})
      : super(key: key);

  @override
  State<AssignmentGradingScreen> createState() =>
      _AssignmentGradingScreenState();
}

class _AssignmentGradingScreenState extends State<AssignmentGradingScreen> {
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _loading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.submission.score != null) {
      _scoreController.text = widget.submission.score.toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackController.text = widget.submission.feedback!;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    final int? score = int.tryParse(_scoreController.text);
    final String feedback = _feedbackController.text;
    if (score == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid score')));
      return;
    }
    setState(() => _loading = true);
    final gradeData = {
      'assignmentId': widget.submission.assignmentId,
      'score': score,
      'feedback': feedback,
    };
    final response =
        await Provider.of<AssignmentProvider>(context, listen: false)
            .gradeSubmission(widget.submission.id, gradeData);
    setState(() => _loading = false);
    if (response['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Grading successful')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Grading failed')));
    }
  }

  void _openFile(AssignmentFile file) async {
    final bool isImage = file.contentType.startsWith('image/');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${file.fileName}...')),
      );

      if (isImage) {
        // Get image with authentication
        final response =
            await _apiService.openFile(file.fileUrl, isImage: true);

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
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      )
                    ],
                  ),
                  InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
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

        if (!mounted) return;

        if (!response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Could not open file')),
          );
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;
    return Scaffold(
      appBar: AppBar(
        title:  Text('Grade Submission',style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: MyAppColors.whiteColor
        ),),
        centerTitle: true,
        backgroundColor: MyAppColors.primaryColor,
        leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            }, icon: const Icon(Icons.arrow_back_ios,color: MyAppColors.whiteColor,)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Submission by ${sub.studentName ?? "Unknown Student"}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                )),
            const SizedBox(height: 8),
            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(sub.notes),
            const SizedBox(height: 8),
            if (sub.files != null && sub.files!.isNotEmpty) ...[
              const Text('Files:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...sub.files!.map((file) {
                final bool isImage = file.contentType.startsWith('image/');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isImage ? Icons.image : Icons.attach_file,
                    color: isImage ? Colors.blue : Colors.grey[700],
                  ),
                  title: Text(
                    file.fileName,
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onTap: () => _openFile(file),
                );
              }),
              const SizedBox(height: 8),
            ],
            TextFormField(
              cursorColor: MyAppColors.primaryColor,
              controller: _scoreController,
              decoration: const InputDecoration(
                  labelText: 'Score',
                  labelStyle: TextStyle(
                    color: MyAppColors.primaryColor
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: MyAppColors.primaryColor
                    )
                  )
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              cursorColor: MyAppColors.primaryColor,
              controller: _feedbackController,
              decoration: const InputDecoration(
                  labelText: 'Feedback',
                  labelStyle: TextStyle(
                    color: MyAppColors.primaryColor
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: MyAppColors.primaryColor
                    )
                  )
              ),
              maxLines: 3,

            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitGrade,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: MyAppColors.primaryColor),
                    child: const Text('Submit Grade'),
                  ),
          ],
        ),
      ),
    );
  }
}
