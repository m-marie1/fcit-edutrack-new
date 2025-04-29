import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/models/assignment_model.dart';
import 'package:fci_edutrack/providers/assignment_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../style/my_app_colors.dart';
import '../../utils/date_formatter.dart';

class AssignmentSubmissionScreen extends StatefulWidget {
  static const String routeName = 'assignment_submission_screen';
  final Assignment assignment;
  // Optional submission for edit mode
  final AssignmentSubmission? existingSubmission;

  const AssignmentSubmissionScreen(
      {super.key, required this.assignment, this.existingSubmission});

  @override
  State<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _notes; // Used for submission notes
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  // Flag to determine if we're editing or creating new
  bool get _isEditMode => widget.existingSubmission != null;

  @override
  void initState() {
    super.initState();
    // Pre-populate notes if editing
    if (_isEditMode) {
      _notes = widget.existingSubmission!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Submission' : 'Submit Assignment'),
        backgroundColor: MyAppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment Info Card
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assignment.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        Text(
                          widget.assignment.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${DateFormatter.formatNonUtcDateString(widget.assignment.dueDate)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.score,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Max Points: ${widget.assignment.maxPoints}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        // If editing, show existing submission info
                        if (_isEditMode) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          Text(
                            'Editing submission from: ${DateFormatter.formatDateString(widget.existingSubmission!.submissionDate)}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue[700],
                            ),
                          ),
                          if (widget.existingSubmission!.graded)
                            Row(
                              children: [
                                const Icon(Icons.warning,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This submission has already been graded. Editing it will mark it as updated.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Submission Form Section
                Text(
                  'Your Submission',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Add any comments about your submission',
                  ),
                  initialValue: _notes,
                  maxLines: 3,
                  onSaved: (val) => _notes = val,
                ),

                const SizedBox(height: 24),

                // File Attachment Section
                _selectedFile == null
                    ? Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: InkWell(
                          onTap: _pickFile,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload,
                                  color: MyAppColors.primaryColor, size: 32),
                              SizedBox(height: 8),
                              Text('Click to upload file'),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file,
                              color: MyAppColors.primaryColor),
                          title: Text(_selectedFile!.name),
                          subtitle: Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                              });
                            },
                          ),
                        ),
                      ),

                // Show existing files if editing
                if (_isEditMode &&
                    widget.existingSubmission!.files != null &&
                    widget.existingSubmission!.files!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Currently attached file(s):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.existingSubmission!.files!
                      .map((file) => Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                file.contentType.startsWith('image/')
                                    ? Icons.image
                                    : Icons.insert_drive_file,
                                color: MyAppColors.primaryColor,
                              ),
                              title: Text(file.fileName),
                              subtitle: Text(
                                  '${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
                            ),
                          ))
                      .toList(),
                  Text(
                    'Note: Uploading a new file will replace the existing file.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyAppColors.primaryColor,
                          ),
                          onPressed: _submitAssignment,
                          child: Text(
                            _isEditMode
                                ? 'Update Submission'
                                : 'Submit Assignment',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null && !_isEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please attach a file.')));
        return;
      }

      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);

      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      final Map<String, dynamic> result;

      if (_isEditMode) {
        // Edit existing submission
        result = await provider.editSubmission(
          widget.existingSubmission!.id,
          _notes,
          _selectedFile != null ? [_selectedFile!] : [],
          assignmentId: widget.assignment.id,
        );
      } else {
        // Create new submission
        result = await provider
            .submitAssignment(widget.assignment.id, _notes, [_selectedFile!]);
      }

      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')));
      }
    }
  }
}
