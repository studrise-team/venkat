class QuestionModel {
  final String question;
  final List<String> options;
  final String answer;
  final String? explanation;
  final String? category;

  QuestionModel({
    required this.question,
    required this.options,
    required this.answer,
    this.explanation,
    this.category,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<String> rawOptions = List<String>.from(json['options'] ?? []);
    // Normalize options: remove leading "A) ", "1. ", "A. ", "A ) ", etc.
    List<String> cleanOptions = rawOptions.map((o) {
      String s = o.trim();
      // Remove patterns like "A) ", "a) ", "1. ", "A. ", "A ) ", "1 . ", "(A) ", "(1) "
      // Regex explanation: Start of string, optional bracket, letter/digit, optional spaces, closing bracket or dot, optional spaces.
      return s.replaceFirst(RegExp(r'^\(?[a-dA-D1-4]\s?[\.\)]\s?'), '').trim();
    }).toList();

    String rawAnswer = (json['answer'] ?? '').toString().trim();
    String normalizedAnswer = rawAnswer;

    // If answer is "A", "B", "C", "D", map it to the cleaned option text
    if (RegExp(r'^[a-dA-D1-4]$').hasMatch(rawAnswer)) {
      int index = -1;
      if (RegExp(r'^[A-D]$').hasMatch(rawAnswer)) index = rawAnswer.codeUnitAt(0) - 65;
      if (RegExp(r'^[a-d]$').hasMatch(rawAnswer)) index = rawAnswer.codeUnitAt(0) - 97;
      if (RegExp(r'^[1-4]$').hasMatch(rawAnswer)) index = int.parse(rawAnswer) - 1;

      if (index >= 0 && index < cleanOptions.length) {
        normalizedAnswer = cleanOptions[index];
      }
    }

    return QuestionModel(
      question: (json['question'] ?? '').toString().trim(),
      options: cleanOptions,
      answer: normalizedAnswer,
      explanation: json['explanation'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'category': category,
      };
}
