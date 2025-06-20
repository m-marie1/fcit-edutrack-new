import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import '../../style/my_app_colors.dart';
import '../../themes/theme_provider.dart';
import 'quiz_submission_details_screen.dart';

class QuizSubmissionsScreen extends StatefulWidget {
  static const String routeName = 'quiz_submissions_screen';
  final int quizId;
  final String quizTitle;

  const QuizSubmissionsScreen({
    Key? key,
    required this.quizId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  State<QuizSubmissionsScreen> createState() => _QuizSubmissionsScreenState();
}

class _QuizSubmissionsScreenState extends State<QuizSubmissionsScreen> {
  bool _isLoading = false;
  List<dynamic> _submissions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final response = await quizProvider.getQuizSubmissions(widget.quizId);

      if (response['success']) {
        setState(() {
          _submissions = response['data'];
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to fetch submissions';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadSubmissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final result = await quizProvider.downloadQuizSubmissions(widget.quizId);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submissions downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Failed to download submissions'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading submissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
       appBar: AppBar(
        backgroundColor: MyAppColors.primaryColor,
        elevation: 0,
        title: Text(
          'Submissions: ${widget.quizTitle}',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: MyAppColors.whiteColor
          ),
        ),
        iconTheme: const IconThemeData(
          color:  MyAppColors.whiteColor ,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isLoading ? null : _downloadSubmissions,
            tooltip: 'Download CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchSubmissions,
            tooltip: 'Refresh',
          ),
        ],
         leading: IconButton(
           onPressed: () {
             Navigator.pop(context);
           },
           icon: const Icon(Icons.arrow_back_ios, color: MyAppColors.whiteColor,),
         ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
        color: MyAppColors.primaryColor,
      ))
          : _errorMessage != null
              ? Center(
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
                        onPressed: _fetchSubmissions,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _submissions.isEmpty
                  ? const Center(
                      child: Text('No submissions yet'),
                    )
                  : ListView.builder(
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final submission = _submissions[index];
                        return Card(
                          color: isDark?MyAppColors.secondaryDarkColor:MyAppColors.whiteColor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                                submission['studentName'] ?? 'Unknown Student',style: TextStyle(
                              color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor
                            ),),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Score: ${submission['score']}/${submission['maxScore']}',style: TextStyle(
                                  color: isDark?MyAppColors.whiteColor:MyAppColors.blackColor
                                ),),
                                Text(
                                  'Percentage: ${((submission['score'] / submission['maxScore']) * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Provider.of<ThemeProvider>(context).isDark()?MyAppColors.whiteColor:MyAppColors.blackColor
                                  ),
                                ),
                                Text(
                                    'Submitted: ${submission['submissionDate']}',style: TextStyle(
                                  color: isDark?MyAppColors.whiteColor:MyAppColors.blackColor
                                ),),
                              ],
                            ),
                            trailing: IconButton(
                              icon:  Icon(Icons.visibility,color: isDark?MyAppColors.primaryColor:MyAppColors.darkBlueColor,),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuizSubmissionDetailsScreen(
                                      quizId: widget.quizId,
                                      submissionId: submission['id'],
                                      studentName: submission['studentName'] ??
                                          'Unknown Student',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
