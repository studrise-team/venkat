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
    return QuestionModel(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
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
