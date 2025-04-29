import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import '../../style/my_app_colors.dart';
import '../../themes/theme_provider.dart';
import 'package:intl/intl.dart';

class QuizSubmissionDetailsScreen extends StatefulWidget {
  static const String routeName = 'quiz_submission_details_screen';
  final int quizId;
  final int submissionId;
  final String studentName;

  const QuizSubmissionDetailsScreen({
    Key? key,
    required this.quizId,
    required this.submissionId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<QuizSubmissionDetailsScreen> createState() =>
      _QuizSubmissionDetailsScreenState();
}

class _QuizSubmissionDetailsScreenState
    extends State<QuizSubmissionDetailsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _submissionDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubmissionDetails();
  }

  Future<void> _fetchSubmissionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final response = await quizProvider.getSubmissionDetails(
          widget.quizId, widget.submissionId);

      if (response['success']) {
        setState(() {
          _submissionDetails = response['data'];
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Failed to fetch submission details';
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

  Widget _buildAnswerCard(Map<String, dynamic> answer) {
    final questionText = answer['questionText'] ?? '';
    final questionType = answer['questionType'] ?? '';
    final points = answer['points'] ?? 0;
    final pointsAwarded = answer['pointsAwarded'] ?? 0;
    final isCorrect = pointsAwarded == points;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (questionType == 'MULTIPLE_CHOICE') ...[
              Text(
                'Selected: ${answer['selectedOption']?['text'] ?? 'No answer'}',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              Text(
                'Correct: ${answer['correctOption']?['text'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.green),
              ),
            ] else if (questionType == 'TEXT_ANSWER') ...[
              Text(
                'Student Answer: ${answer['studentAnswer'] ?? 'No answer'}',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              Text(
                'Correct Answer: ${answer['correctAnswer'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Points: $pointsAwarded/$points',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
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
          'Submission Details: ${widget.studentName}',
          style: TextStyle(
            color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? MyAppColors.whiteColor : MyAppColors.blackColor,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        onPressed: _fetchSubmissionDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _submissionDetails == null
                  ? const Center(child: Text('No details available'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Score: ${_submissionDetails!['score']}/${_submissionDetails!['maxScore']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Percentage: ${((_submissionDetails!['score'] / _submissionDetails!['maxScore']) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Submitted: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(_submissionDetails!['endTime']))}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Answers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...(_submissionDetails!['answers'] as List)
                              .map((answer) => _buildAnswerCard(
                                  answer as Map<String, dynamic>))
                              .toList(),
                        ],
                      ),
                    ),
    );
  }
}
