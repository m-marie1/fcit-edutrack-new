import 'dart:async'; // For Timer
import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_models.dart';
import '../../providers/quiz_provider.dart'; // Will need a provider method for submission
import '../../style/my_app_colors.dart';

// Model to hold student's answer for a question
class StudentAnswer {
  final int questionId;
  int? selectedOptionId; // For Multiple Choice
  String? textAnswer; // For Text Answer

  StudentAnswer(
      {required this.questionId, this.selectedOptionId, this.textAnswer});
}

class QuizTakingScreen extends StatefulWidget {
  static const String routeName = 'quiz_taking';
  final Quiz quiz; // The quiz object passed from the list screen

  const QuizTakingScreen({required this.quiz, Key? key}) : super(key: key);

  @override
  _QuizTakingScreenState createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  late Timer _timer;
  int _remainingSeconds = 0;
  bool _isLoading = true; // Start in loading state
  bool _startError = false; // Flag for start error
  String _startErrorMessage = ''; // Error message

  // Store student answers - Map question ID to StudentAnswer object
  final Map<int, StudentAnswer> _studentAnswers = {};

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    // Call startQuiz API first
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final response = await quizProvider.startQuiz(widget.quiz.id!);

    if (!mounted) return; // Check if widget is still in the tree

    if (response['success']) {
      // Start successful, initialize timer and answers
      setState(() {
        _remainingSeconds = widget.quiz.durationMinutes * 60;
        _isLoading = false; // Stop loading
        _startError = false;
      });
      _startTimer();
      // Initialize answers map
      for (var question in widget.quiz.questions) {
        if (question.id != null) {
          _studentAnswers[question.id!] =
              StudentAnswer(questionId: question.id!);
        }
      }
    } else {
      // Start failed, show error and prevent quiz start
      setState(() {
        _isLoading = false;
        _startError = true;
        _startErrorMessage = response['message'] ?? 'Failed to start quiz.';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _submitQuiz(timeout: true); // Auto-submit on timeout
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Last question, prompt for submission
      _confirmSubmit();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _updateAnswer(StudentAnswer answer) {
    setState(() {
      _studentAnswers[answer.questionId] = answer;
    });
  }

  Future<void> _confirmSubmit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: MyAppColors.primaryColor),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (result == true) {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz({bool timeout = false}) async {
    _timer.cancel(); // Stop timer on submission
    setState(() => _isLoading = true);

    // Prepare submission data based on API documentation
    final List<Map<String, dynamic>> answersPayload = [];
    _studentAnswers.forEach((questionId, answer) {
      if (answer.selectedOptionId != null) {
        // Multiple Choice
        answersPayload.add({
          'questionId': questionId,
          'selectedOptionId': answer.selectedOptionId,
        });
      } else if (answer.textAnswer != null && answer.textAnswer!.isNotEmpty) {
        // Text Answer
        answersPayload.add({
          'questionId': questionId,
          'textAnswer': answer.textAnswer,
        });
      }
      // Implicitly, unanswered questions are not included in the payload
    });

    final submissionData = {
      'quizId': widget.quiz.id,
      'answers': answersPayload,
    };

    print(
        "Submitting Quiz Data: ${jsonEncode(submissionData)}"); // Log submission data

    // Call QuizProvider method to submit
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final response = await quizProvider.submitQuiz(
        widget.quiz.id!, answersPayload); // Use actual quiz ID and payload

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show result dialog or navigate away
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing during submission feedback
      builder: (context) => AlertDialog(
        title: Text(timeout ? 'Time Expired!' : 'Quiz Submitted'),
        content: Text(
            (response['message'] ?? // Ensure message is converted to String
                    (timeout
                        ? 'Your quiz was submitted automatically.'
                        : 'Submission failed.'))
                .toString()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to quiz list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final questionNumber = _currentQuestionIndex + 1;
    final totalQuestions = widget.quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title, overflow: TextOverflow.ellipsis),
        backgroundColor: MyAppColors.primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Time: ${_formatDuration(_remainingSeconds)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _startError // Show error message if start failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Error Starting Quiz',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _startErrorMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  // Only show quiz content if start was successful
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Indicator
                      Text(
                        'Question $questionNumber of $totalQuestions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: questionNumber / totalQuestions,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            MyAppColors.primaryColor),
                      ),
                      const SizedBox(height: 24),

                      // Question Text
                      Text(
                        '${currentQuestion.text} (${currentQuestion.points} points)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      // Answer Area (Dynamic based on type)
                      Expanded(
                        child: _buildAnswerArea(currentQuestion),
                      ),

                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _currentQuestionIndex > 0
                                ? _previousQuestion
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey),
                          ),
                          ElevatedButton.icon(
                            onPressed: _currentQuestionIndex <
                                    totalQuestions - 1
                                ? _nextQuestion
                                : _confirmSubmit, // Show submit on last question
                            icon: Icon(
                                _currentQuestionIndex < totalQuestions - 1
                                    ? Icons.arrow_forward
                                    : Icons.check_circle_outline),
                            label: Text(
                                _currentQuestionIndex < totalQuestions - 1
                                    ? 'Next'
                                    : 'Submit'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: MyAppColors.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAnswerArea(Question question) {
    StudentAnswer currentAnswer = _studentAnswers[question.id!] ??
        StudentAnswer(questionId: question.id!);

    switch (question.type) {
      case QuestionType.MULTIPLE_CHOICE:
        return _buildMultipleChoiceAnswerArea(question, currentAnswer);
      case QuestionType.TEXT_ANSWER:
        return _buildTextAnswerArea(question, currentAnswer);
      default:
        return const Text('Unsupported question type.');
    }
  }

  Widget _buildMultipleChoiceAnswerArea(
      Question question, StudentAnswer currentAnswer) {
    return ListView.builder(
      itemCount: question.options?.length ?? 0,
      itemBuilder: (context, index) {
        final option = question.options![index];
        return RadioListTile<int?>(
          title: Text(option.text),
          value: option.id, // Use option ID as the value
          groupValue: currentAnswer.selectedOptionId,
          onChanged: (value) {
            _updateAnswer(StudentAnswer(
                questionId: question.id!, selectedOptionId: value));
          },
          activeColor: MyAppColors.primaryColor,
        );
      },
    );
  }

  Widget _buildTextAnswerArea(Question question, StudentAnswer currentAnswer) {
    // Use a TextEditingController specific to this question instance if needed,
    // but for simplicity, we'll update the map directly on change.
    // Consider using a controller map if performance becomes an issue.
    return TextFormField(
      initialValue: currentAnswer.textAnswer,
      decoration: const InputDecoration(
        labelText: 'Your Answer',
        border: OutlineInputBorder(),
        hintText: 'Type your answer here...',
      ),
      maxLines: 5,
      onChanged: (value) {
        _updateAnswer(
            StudentAnswer(questionId: question.id!, textAnswer: value));
      },
    );
  }
}
