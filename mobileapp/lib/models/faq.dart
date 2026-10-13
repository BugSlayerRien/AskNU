class FAQ {
  final String id;
  final String category;
  final String question;
  final String answer;
  final String description;
  final List<String> tags;

  FAQ({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.description,
    required this.tags,
  });

  factory FAQ.fromJson(Map<String, dynamic> j) => FAQ(
        id: j['id'] as String,
        category: j['category'] as String,
        question: j['question'] as String,
        answer: j['answer'] as String,
        description: (j['description'] ?? j['summaryHint'] ?? '').toString(),
        tags: List<String>.from(j['tags'] ?? <String>[]),
      );
}
