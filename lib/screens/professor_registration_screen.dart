import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../config.dart';

class ProfessorRegistrationScreen extends StatefulWidget {
  const ProfessorRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<ProfessorRegistrationScreen> createState() =>
      _ProfessorRegistrationScreenState();
}

class _ProfessorRegistrationScreenState
    extends State<ProfessorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  final _apiService = ApiService();

  File? _selectedFile;
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _uploadedFileUrl;

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _uploadedFileUrl = null; // Reset uploaded URL when new file is selected
      });

      // Auto-upload when file is selected
      _uploadFile();
    }
  }

  Future<void> _uploadFile() async {
    try {
      if (_selectedFile == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Use the fileType parameter to indicate this is a professor ID
      // Use 'professor-id' to match the backend's expected value
      final response = await _apiService.uploadFile(_selectedFile!,
          fileType: 'professor-id');

      if (response != null &&
          response['success'] &&
          response['data'] != null &&
          response['data']['fileUrl'] != null) {
        setState(() {
          _uploadedFileUrl = response['data']['fileUrl'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID image uploaded successfully')),
        );
      } else {
        String errorMsg = response != null && response['message'] != null
            ? response['message']
            : 'Failed to upload ID image';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      print('Error uploading ID image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading ID image: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your ID card image')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.submitProfessorRequest(
        _fullNameController.text,
        _emailController.text,
        _departmentController.text,
        _uploadedFileUrl!,
        _additionalInfoController.text,
      );

      if (response != null && response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Request submitted successfully. We will review your application soon.')),
        );
        Navigator.pop(context); // Go back after successful submission
      } else {
        String errorMsg = response != null && response['message'] != null
            ? response['message']
            : 'Failed to submit request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      print('Error submitting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply to become a professor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your department';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Upload your ID card image',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Column(
                  children: [
                    if (_selectedFile != null || _uploadedFileUrl != null)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: _uploadedFileUrl != null
                            ? FutureBuilder<Map<String, dynamic>>(
                                future: _apiService.openFile(_uploadedFileUrl!,
                                    isImage: true),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data!['success'] == true &&
                                      snapshot.data!['bytes'] != null) {
                                    // Display the image from bytes
                                    return Image.memory(
                                      snapshot.data!['bytes'],
                                      fit: BoxFit.cover,
                                    );
                                  }

                                  // Error state
                                  return const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.error,
                                            color: Colors.red, size: 36),
                                        SizedBox(height: 8),
                                        Text(
                                          'Error loading image',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                _selectedFile!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    const SizedBox(height: 16.0),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_isUploading
                          ? 'Uploading...'
                          : (_uploadedFileUrl != null
                              ? 'Change ID Image'
                              : 'Upload ID Image')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _additionalInfoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Information (Optional)',
                  border: OutlineInputBorder(),
                  hintText:
                      'Add any information that might help us review your application',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isSubmitting || _isUploading) ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child:
                      Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
