class ResultModel {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double percentage;
  final List<AnswerRecord> answers;
  final DateTime takenAt;

  final String examContext;
  final String? subjectContext;

  ResultModel({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.answers,
    required this.takenAt,
    this.examContext = '',
    this.subjectContext,
  });
}

class AnswerRecord {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? selectedAnswer;
  final bool isCorrect;

  AnswerRecord({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.isCorrect,
    this.selectedAnswer,
  });
}
