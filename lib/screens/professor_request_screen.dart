import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/modules/custom_text_formfield.dart';
import 'package:fci_edutrack/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfessorRequestScreen extends StatefulWidget {
  static const String routeName = 'professor_request_screen';

  const ProfessorRequestScreen({Key? key}) : super(key: key);

  @override
  State<ProfessorRequestScreen> createState() => _ProfessorRequestScreenState();
}

class _ProfessorRequestScreenState extends State<ProfessorRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _additionalInfoController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _idImage;
  String? _uploadedImageUrl;

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Reduce image quality for smaller file size
      maxWidth: 800, // Limit image width
      maxHeight: 800, // Limit image height
    );

    if (image != null) {
      setState(() {
        _idImage = File(image.path);
      });

      // Upload the image
      await _uploadImage();
    }
  }

  // Method to upload image to server
  Future<void> _uploadImage() async {
    if (_idImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      print("Uploading ID image: ${_idImage!.path}");

      // Use the new uploadFileToServer method for public upload
      final response = await apiService.uploadFileToServer(
        _idImage!,
        requiresAuth: false, // This is a public upload endpoint
      );

      print("Upload response: $response");

      if (response['success'] == true && response['data'] != null) {
        // Extract the fileUrl from the 'data' field in the response
        _uploadedImageUrl = response['data']['fileUrl'];
        setState(() {
          _successMessage = "ID image uploaded successfully";
          _errorMessage = null; // Clear any previous error message
        });
        print("ID image uploaded successfully: $_uploadedImageUrl");
      } else {
        // Handle upload failure
        setState(() {
          _errorMessage = response['message'] ?? "Failed to upload ID image";
          _successMessage = null; // Clear any previous success message
        });
        print("Failed to upload ID image: $_errorMessage");
      }
    } catch (e) {
      // Handle exceptions during upload
      setState(() {
        _errorMessage =
            "An error occurred during image upload: ${e.toString()}";
        _successMessage = null; // Clear any previous success message
      });
      print("Exception during ID image upload: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to submit professor request
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      setState(() {
        _errorMessage = "Please upload an ID image first";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.submitProfessorRequest(
        _fullNameController.text,
        _emailController.text,
        _departmentController.text,
        _uploadedImageUrl!,
        _additionalInfoController.text,
      );

      if (response['success']) {
        setState(() {
          _successMessage =
              "Your professor request has been submitted successfully. You will receive an email when it's reviewed.";
          _fullNameController.clear();
          _emailController.clear();
          _departmentController.clear();
          _additionalInfoController.clear();
          _idImage = null;
          _uploadedImageUrl = null;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? "Failed to submit request";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to submit request: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();

    return Scaffold(
      backgroundColor:
          isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Professor Access Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Professor Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? MyAppColors.whiteColor
                        : MyAppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete this form to request a professor account. The request will be reviewed by an administrator.',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomTextFormField(
                  label: 'Full Name',
                  preIcon: Icons.person,
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  label: 'Email',
                  preIcon: Icons.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                CustomTextFormField(
                  label: 'Department',
                  preIcon: Icons.business,
                  controller: _departmentController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? MyAppColors.whiteColor
                        : MyAppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _additionalInfoController,
                  decoration: InputDecoration(
                    hintText:
                        'Provide any additional information that may help with your request',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: MyAppColors.primaryColor,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    return null; // Optional field
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'ID Image/Document',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? MyAppColors.whiteColor
                        : MyAppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _idImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _idImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  // Edit button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.white),
                                      onPressed: _pickImage,
                                      tooltip: 'Change image',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _idImage = null;
                                          _uploadedImageUrl = null;
                                        });
                                      },
                                      tooltip: 'Remove image',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Add click handler to change image
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyAppColors.primaryColor,
                                ),
                                child: const Text('Upload ID Image'),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyAppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(fontSize: 16),
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
}

// import 'package:flutter/material.dart';
// import 'package:fci_edutrack/style/my_app_colors.dart';
// import 'package:fci_edutrack/themes/theme_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:fci_edutrack/modules/custom_text_formfield.dart';
// import 'package:fci_edutrack/services/api_service.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class ProfessorRequestScreen extends StatefulWidget {
//   static const String routeName = 'professor_request_screen';

//   const ProfessorRequestScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfessorRequestScreen> createState() => _ProfessorRequestScreenState();
// }

// class _ProfessorRequestScreenState extends State<ProfessorRequestScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _departmentController = TextEditingController();
//   final TextEditingController _additionalInfoController =
//       TextEditingController();

//   bool _isLoading = false;
//   String? _errorMessage;
//   String? _successMessage;
//   File? _idImage;
//   String? _uploadedImageUrl;

//   // Method to pick image from gallery
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 70, // Reduce image quality for smaller file size
//       maxWidth: 800, // Limit image width
//       maxHeight: 800, // Limit image height
//     );

//     if (image != null) {
//       setState(() {
//         _idImage = File(image.path);
//       });

//       // Upload the image
//       await _uploadImage();
//     }
//   }

//   // Method to upload image to server
//   Future<void> _uploadImage() async {
//     if (_idImage == null) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final apiService = ApiService();
//       print("Uploading image: ${_idImage!.path}");

//       // Check file extension to help debug content type issues
//       String fileExtension = _idImage!.path.split('.').last.toLowerCase();
//       print("File extension: $fileExtension");

//       final response = await apiService.uploadFile(_idImage!);
//       print("Upload response: $response");

//       if (response['success'] == true && response['data'] != null) {
//         _uploadedImageUrl = response['data']['fileUrl'];
//         setState(() {
//           _successMessage = "ID image uploaded successfully";
//         });
//         print("Image uploaded successfully: $_uploadedImageUrl");
//       } else {
//         setState(() {
//           _errorMessage = response['message'] ?? "Failed to upload image";
//         });
//         print("Failed to upload image: $_errorMessage");
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Failed to upload image: ${e.toString()}";
//       });
//       print("Exception during image upload: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // Method to submit professor request
//   Future<void> _submitRequest() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_uploadedImageUrl == null) {
//       setState(() {
//         _errorMessage = "Please upload an ID image first";
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       _successMessage = null;
//     });

//     try {
//       final apiService = ApiService();
//       final response = await apiService.submitProfessorRequest(
//         _fullNameController.text,
//         _emailController.text,
//         _departmentController.text,
//         _uploadedImageUrl!,
//         _additionalInfoController.text,
//       );

//       if (response['success']) {
//         setState(() {
//           _successMessage =
//               "Your professor request has been submitted successfully. You will receive an email when it's reviewed.";
//           _fullNameController.clear();
//           _emailController.clear();
//           _departmentController.clear();
//           _additionalInfoController.clear();
//           _idImage = null;
//           _uploadedImageUrl = null;
//         });
//       } else {
//         setState(() {
//           _errorMessage = response['message'] ?? "Failed to submit request";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Failed to submit request: ${e.toString()}";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Provider.of<ThemeProvider>(context).isDark();

//     return Scaffold(
//       backgroundColor:
//           isDark ? MyAppColors.primaryDarkColor : MyAppColors.whiteColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           'Professor Access Request',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
//           ),
//         ),
//         iconTheme: IconThemeData(
//           color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Request Professor Account',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? MyAppColors.whiteColor
//                         : MyAppColors.blackColor,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Please complete this form to request a professor account. The request will be reviewed by an administrator.',
//                   style: TextStyle(
//                     color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 if (_errorMessage != null)
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       borderRadius: BorderRadius.circular(5),
//                       border: Border.all(color: Colors.red.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.error_outline, color: Colors.red),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             _errorMessage!,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 if (_successMessage != null)
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(5),
//                       border: Border.all(color: Colors.green.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.check_circle_outline,
//                             color: Colors.green),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             _successMessage!,
//                             style: const TextStyle(color: Colors.green),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 CustomTextFormField(
//                   label: 'Full Name',
//                   preIcon: Icons.person,
//                   controller: _fullNameController,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your full name';
//                     }
//                     return null;
//                   },
//                 ),
//                 CustomTextFormField(
//                   label: 'Email',
//                   preIcon: Icons.email,
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 CustomTextFormField(
//                   label: 'Department',
//                   preIcon: Icons.business,
//                   controller: _departmentController,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your department';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 15),
//                 Text(
//                   'Additional Information',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? MyAppColors.whiteColor
//                         : MyAppColors.blackColor,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _additionalInfoController,
//                   decoration: InputDecoration(
//                     hintText:
//                         'Provide any additional information that may help with your request',
//                     prefixIcon: const Icon(Icons.description),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide(
//                         color: isDark
//                             ? Colors.grey.shade700
//                             : Colors.grey.shade300,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(
//                         color: MyAppColors.primaryColor,
//                       ),
//                     ),
//                     filled: true,
//                     fillColor:
//                         isDark ? Colors.grey.shade800 : Colors.grey.shade100,
//                   ),
//                   maxLines: 3,
//                   validator: (value) {
//                     return null; // Optional field
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'ID Image/Document',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: isDark
//                         ? MyAppColors.whiteColor
//                         : MyAppColors.blackColor,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   height: 150,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color:
//                           isDark ? Colors.grey.shade700 : Colors.grey.shade300,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: _idImage != null
//                       ? Stack(
//                           children: [
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: Image.file(
//                                 _idImage!,
//                                 fit: BoxFit.cover,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                               ),
//                             ),
//                             Positioned(
//                               top: 8,
//                               right: 8,
//                               child: Row(
//                                 children: [
//                                   // Edit button
//                                   Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withOpacity(0.6),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: IconButton(
//                                       icon: const Icon(Icons.edit,
//                                           color: Colors.white),
//                                       onPressed: _pickImage,
//                                       tooltip: 'Change image',
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   // Delete button
//                                   Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.black.withOpacity(0.6),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: IconButton(
//                                       icon: const Icon(Icons.delete,
//                                           color: Colors.red),
//                                       onPressed: () {
//                                         setState(() {
//                                           _idImage = null;
//                                           _uploadedImageUrl = null;
//                                         });
//                                       },
//                                       tooltip: 'Remove image',
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             // Add click handler to change image
//                             Positioned.fill(
//                               child: Material(
//                                 color: Colors.transparent,
//                                 child: InkWell(
//                                   onTap: _pickImage,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         )
//                       : Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.add_photo_alternate,
//                                 size: 48,
//                                 color: isDark
//                                     ? Colors.grey.shade400
//                                     : Colors.grey.shade600,
//                               ),
//                               const SizedBox(height: 8),
//                               ElevatedButton(
//                                 onPressed: _pickImage,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: MyAppColors.primaryColor,
//                                 ),
//                                 child: const Text('Upload ID Image'),
//                               ),
//                             ],
//                           ),
//                         ),
//                 ),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitRequest,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: MyAppColors.primaryColor,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : const Text(
//                             'Submit Request',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
