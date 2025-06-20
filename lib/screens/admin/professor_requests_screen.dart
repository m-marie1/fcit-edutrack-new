import 'package:flutter/material.dart';
import 'package:fci_edutrack/style/my_app_colors.dart';
import 'package:fci_edutrack/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:fci_edutrack/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fci_edutrack/config.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ProfessorRequestsScreen extends StatefulWidget {
  static const String routeName = 'admin_professor_requests_screen';

  const ProfessorRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ProfessorRequestsScreen> createState() =>
      _ProfessorRequestsScreenState();
}

class _ProfessorRequestsScreenState extends State<ProfessorRequestsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _requests = [];
  // Map to store loaded image bytes
  final Map<String, Uint8List> _loadedImages = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("Fetching pending professor requests...");
      final response = await _apiService.getPendingProfessorRequests();
      print("Pending requests response: $response");

      if (response['success'] && response['data'] != null) {
        setState(() {
          _requests = response['data'];
        });
        print("Found ${_requests.length} pending requests");
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? "Failed to fetch pending requests";
        });
        print("Failed to fetch pending requests: $_errorMessage");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
      print("Exception fetching pending requests: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewRequest(String requestId, bool isApproved,
      {String? rejectionReason}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
          "Attempting to review request $requestId with approval=$isApproved");
      final response = await _apiService.reviewProfessorRequest(
          requestId, isApproved,
          rejectionReason: rejectionReason);
      print("Review response: $response");

      if (response['success']) {
        // Refresh the list after successful review
        await _fetchPendingRequests();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved
                ? "Request approved successfully"
                : "Request rejected successfully"),
            backgroundColor: isApproved ? Colors.green : Colors.orange,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? "Failed to review request";
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load an image with authentication
  Future<bool> _loadImageWithAuth(String imageUrl, String requestId) async {
    try {
      // Check if already loaded
      if (_loadedImages.containsKey(requestId)) {
        return true;
      }

      final response = await _apiService.openFile(imageUrl, isImage: true);

      if (response['success'] && response['bytes'] != null) {
        setState(() {
          _loadedImages[requestId] = response['bytes'];
        });
        return true;
      }
      return false;
    } catch (e) {
      print("Error loading image with auth: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark();

    return Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Professor Requests',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? MyAppColors.primaryColor : MyAppColors.darkBlueColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,color: MyAppColors.darkBlueColor,),
            onPressed: _fetchPendingRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPendingRequests,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _requests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending professor requests found',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _requests.length,
                      padding: const EdgeInsets.all(16.0),
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _buildRequestCard(request, isDark);
                      },
                    ),
    );
  }

  Widget _buildRequestCard(dynamic request, bool isDark) {
    // Get the image URL and request ID
    String imageUrl = request['idImageUrl'] ?? '';
    String requestId = request['id']?.toString() ?? '';

    // Print for debugging
    print("ID Image URL: $imageUrl");

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? MyAppColors.secondaryDarkColor : MyAppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['fullName'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? MyAppColors.whiteColor
                          : MyAppColors.blackColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['email'] ?? 'No email provided',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request['department'] ?? 'No department provided',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (request['additionalInfo'] != null &&
                request['additionalInfo'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Additional Information:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request['additionalInfo'],
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ID Verification:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<bool>(
                  future: _loadImageWithAuth(imageUrl, requestId),
                  builder: (context, snapshot) {
                    // If image is successfully loaded
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data == true &&
                        _loadedImages.containsKey(requestId)) {
                      return GestureDetector(
                        onTap: () {
                          _showFullScreenImage(
                              request['fullName'] ?? 'ID Image',
                              _loadedImages[requestId]!);
                        },
                        child: Image.memory(
                          _loadedImages[requestId]!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Error displaying image from memory: $error");
                            return _buildImageErrorWidget(
                                isDark, "Failed to display image: $error");
                          },
                        ),
                      );
                    }

                    // If loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(
                          color: MyAppColors.primaryColor,
                        )),
                      );
                    }

                    // If error or no data
                    return _buildImageErrorWidget(
                      isDark,
                      snapshot.error?.toString() ?? "Failed to load image",
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showRejectDialog(request['id'].toString()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:  Text('Approve Request',style: TextStyle(
                            color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                          ),),
                          backgroundColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
                          content: const Text(
                            'Are you sure you want to approve this professor request? '
                            'This will create a new professor account with access to the system.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',style: TextStyle(
                                color: MyAppColors.primaryColor
                              ),),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyAppColors.primaryColor,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _reviewRequest(request['id'].toString(), true);
                              },
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyAppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the error widget for images
  Widget _buildImageErrorWidget(bool isDark, String errorMessage) {
    return Container(
      height: 120,
      width: double.infinity,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, size: 40),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text('Reject Request',style: TextStyle(
          color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.primaryColor:MyAppColors.darkBlueColor
        ),),
        backgroundColor: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to reject this professor request?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                cursorColor: MyAppColors.primaryColor,
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection (optional)',
                  labelStyle: TextStyle(
                    color: MyAppColors.primaryColor
                  ),
                  hintText: 'Enter reason for rejection',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: MyAppColors.primaryColor
                    )
                  )
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',style: TextStyle(
              color: MyAppColors.primaryColor
            ),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _reviewRequest(requestId, false,
                  rejectionReason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Method to show image in full screen dialog
  void _showFullScreenImage(String title, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title),
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
                    final fileName =
                        'id_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final tempFile = File('${tempDir.path}/$fileName');
                    await tempFile.writeAsBytes(imageBytes);
          
                    Navigator.of(ctx).pop(); // Close dialog
          
                    // Open file
                    final result = await OpenFile.open(tempFile.path);
                    if (result.type != ResultType.done) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Could not open file: ${result.message}')),
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
      ),
    );
  }
}
