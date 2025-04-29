class Quiz {
  final int id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final int durationMinutes;
  final List<QuizQuestion>? questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'durationMinutes': durationMinutes,
      'questions': questions?.map((q) => q.toJson()).toList(),
    };
  }
}

class QuizQuestion {
  final int id;
  final String text;
  final String type;
  final int points;
  final List<QuizOption>? options;
  final String? correctAnswer;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.points,
    this.options,
    this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      text: json['text'] ?? '',
      type: json['type'] ?? '',
      points: json['points'] ?? 0,
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => QuizOption.fromJson(o))
              .toList()
          : null,
      correctAnswer: json['correctAnswer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'points': points,
      'options': options?.map((o) => o.toJson()).toList(),
      'correctAnswer': correctAnswer,
    };
  }
}

class QuizOption {
  final int id;
  final String text;
  final bool? correct;

  QuizOption({
    required this.id,
    required this.text,
    this.correct,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      text: json['text'] ?? '',
      correct: json['correct'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'correct': correct,
    };
  }
}
