import 'package:intl/intl.dart'; // For date parsing/formatting if needed directly

// Helper function to parse date strings as UTC
// Helper function to parse date strings reliably as UTC
DateTime _parseUtc(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    print(
        "Warning: Received null or empty date string. Defaulting to now UTC.");
    return DateTime.now().toUtc();
  }
  try {
    // Define the expected format from the API (without timezone info)
    // Handle potential milliseconds by making them optional in the format
    final format = DateFormat(
        "yyyy-MM-ddTHH:mm:ss"); // Adjust if milliseconds are present: "yyyy-MM-ddTHH:mm:ss.SSS"

    // Attempt to parse the string directly as UTC
    // The 'true' argument tells parse() to interpret the string as UTC.
    DateTime parsedUtc = format.parse(dateString, true);
    return parsedUtc; // Should already be a UTC DateTime object
  } catch (e) {
    print("Error parsing date string '$dateString' explicitly as UTC: $e");
    // Fallback: Try the previous method just in case format varies unexpectedly
    try {
      String processedString = dateString;
      if (processedString.contains('T') &&
          !processedString.endsWith('Z') &&
          !processedString.contains('+') &&
          !processedString.contains('-')) {
        if (processedString.contains('.')) {
          processedString =
              processedString.substring(0, processedString.indexOf('.'));
        }
        processedString += 'Z';
      }
      DateTime parsed = DateTime.parse(processedString);
      if (!parsed.isUtc) {
        print(
            "Fallback Warning: Date string '$dateString' (processed as '$processedString') was parsed as local. Converting to UTC instant.");
        return parsed.toUtc();
      }
      return parsed;
    } catch (e2) {
      print("Fallback parsing also failed for '$dateString': $e2");
      return DateTime.now().toUtc(); // Final fallback
    }
  }
}

// Enum for Question Type
enum QuestionType {
  MULTIPLE_CHOICE,
  TEXT_ANSWER,
  UNKNOWN // Default for safety
}

// Helper to convert String to QuestionType and vice-versa
QuestionType questionTypeFromString(String? type) {
  switch (type?.toUpperCase()) {
    case 'MULTIPLE_CHOICE':
      return QuestionType.MULTIPLE_CHOICE;
    case 'TEXT_ANSWER':
      return QuestionType.TEXT_ANSWER;
    default:
      print("Warning: Unknown QuestionType string '$type'");
      return QuestionType.UNKNOWN;
  }
}

String questionTypeToString(QuestionType type) {
  switch (type) {
    case QuestionType.MULTIPLE_CHOICE:
      return 'MULTIPLE_CHOICE';
    case QuestionType.TEXT_ANSWER:
      return 'TEXT_ANSWER';
    case QuestionType.UNKNOWN:
      return 'UNKNOWN'; // Or handle appropriately
  }
}

// Model for Quiz Option (for Multiple Choice questions)
class Option {
  final int? id;
  final String text;
  final bool isCorrect;

  Option({
    this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? json['correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      if (id != null)
        'id': id, // Include ID for existing options during updates
      'text': text,
      'correct': isCorrect, // Use 'correct' for the backend
    };
    return data;
  }
}

// Model for Quiz Question
class Question {
  final int? id; // Optional ID from backend response
  final String text;
  final QuestionType type;
  final int points;
  final List<Option>? options; // Nullable, only for MULTIPLE_CHOICE
  final String? correctAnswer; // Nullable, only for TEXT_ANSWER

  Question({
    this.id,
    required this.text,
    required this.type,
    required this.points,
    this.options,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var type = questionTypeFromString(json['type']);
    List<Option>? optionsList;
    if (type == QuestionType.MULTIPLE_CHOICE && json['options'] != null) {
      var optionsData = json['options'] as List;
      optionsList =
          optionsData.map((optJson) => Option.fromJson(optJson)).toList();
    }

    return Question(
      id: json['id'],
      text: json['text'] ?? '',
      type: type,
      points: json['points'] ?? 0,
      options: optionsList,
      correctAnswer: json['correctAnswer'], // Will be null if not TEXT_ANSWER
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      // Include 'id' when it exists (essential for updates)
      if (id != null) 'id': id,
      'text': text,
      'type': questionTypeToString(type),
      'points': points,
    };
    if (type == QuestionType.MULTIPLE_CHOICE && options != null) {
      data['options'] = options!.map((opt) => opt.toJson()).toList();
    }
    if (type == QuestionType.TEXT_ANSWER && correctAnswer != null) {
      data['correctAnswer'] = correctAnswer;
    }
    return data;
  }
}

// Model for Quiz
class Quiz {
  final int? id; // Optional ID from backend response
  final String title;
  final String description;
  final int courseId;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes;
  final List<Question> questions;
  final String? courseName; // Added field to hold course name
  // Add other fields if present in response, e.g., isPublished
  final bool? isPublished;

  Quiz({
    this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.questions,
    this.isPublished,
    this.courseName, // Added to constructor parameters
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    var questionsData = json['questions'] as List?;
    List<Question> questionsList = questionsData != null
        ? questionsData.map((qJson) => Question.fromJson(qJson)).toList()
        : [];

    return Quiz(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      // Use "course" key from API response logs, default to 0 if null/missing
      courseId:
          (json['course'] is int) ? json['course'] : (json['courseId'] ?? 0),
      // Parse dates using the helper function to ensure UTC
      startDate: _parseUtc(json['startDate']),
      endDate: _parseUtc(json['endDate']),
      durationMinutes: json['durationMinutes'] ?? 0,
      questions: questionsList,
      isPublished: json['isPublished'], // May be null
      // courseName is NOT expected from standard quiz JSON, will be populated later
    );
  }

  Map<String, dynamic> toJson() {
    // Format dates back to ISO 8601 string for the API
    final DateFormat formatter = DateFormat("yyyy-MM-ddTHH:mm:ss");

    return {
      // Don't include 'id' when sending for creation
      'title': title,
      'description': description,
      'courseId': courseId,
      'startDate':
          formatter.format(startDate.toUtc()), // Send as UTC ISO string
      'endDate': formatter.format(endDate.toUtc()), // Send as UTC ISO string
      'durationMinutes': durationMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
