class ResultModel {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double percentage;
  final List<AnswerRecord> answers;
  final DateTime takenAt;

  ResultModel({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.answers,
    required this.takenAt,
  });
}

class AnswerRecord {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? selectedAnswer;

  bool get isCorrect => selectedAnswer == correctAnswer;

  AnswerRecord({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.selectedAnswer,
  });
}
