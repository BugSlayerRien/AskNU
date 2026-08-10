class GeminiResponse {
  final List<Candidate>? candidates;
  final PromptFeedback? promptFeedback;
  final String? modelVersion;

  GeminiResponse({
    this.candidates,
    this.promptFeedback,
    this.modelVersion,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      candidates: json['candidates'] != null
          ? (json['candidates'] as List)
              .map((i) => Candidate.fromJson(i))
              .toList()
          : null,
      promptFeedback: json['promptFeedback'] != null
          ? PromptFeedback.fromJson(json['promptFeedback'])
          : null,
      modelVersion: json['modelVersion'],
    );
  }

  String? get text {
    if (candidates != null && candidates!.isNotEmpty) {
      final firstCandidate = candidates!.first;
      if (firstCandidate.content != null &&
          firstCandidate.content!.parts != null &&
          firstCandidate.content!.parts!.isNotEmpty) {
        return firstCandidate.content!.parts!.first.text;
      }
    }
    return null;
  }

  // Add this getter for compatibility
  String get description {
    return text ?? 'No description available';
  }
}

class Candidate {
  final Content? content;
  final String? finishReason;
  final int? index;
  final List<SafetyRating>? safetyRatings;

  Candidate({
    this.content,
    this.finishReason,
    this.index,
    this.safetyRatings,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      content: json['content'] != null
          ? Content.fromJson(json['content'])
          : null,
      finishReason: json['finishReason'],
      index: json['index'],
      safetyRatings: json['safetyRatings'] != null
          ? (json['safetyRatings'] as List)
              .map((i) => SafetyRating.fromJson(i))
              .toList()
          : null,
    );
  }
}

class Content {
  final List<Part>? parts;
  final String? role;

  Content({
    this.parts,
    this.role,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      parts: json['parts'] != null
          ? (json['parts'] as List).map((i) => Part.fromJson(i)).toList()
          : null,
      role: json['role'],
    );
  }
}

class Part {
  final String? text;

  Part({
    this.text,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      text: json['text'],
    );
  }
}

class SafetyRating {
  final String? category;
  final String? probability;

  SafetyRating({
    this.category,
    this.probability,
  });

  factory SafetyRating.fromJson(Map<String, dynamic> json) {
    return SafetyRating(
      category: json['category'],
      probability: json['probability'],
    );
  }
}

class PromptFeedback {
  final List<SafetyRating>? safetyRatings;

  PromptFeedback({
    this.safetyRatings,
  });

  factory PromptFeedback.fromJson(Map<String, dynamic> json) {
    return PromptFeedback(
      safetyRatings: json['safetyRatings'] != null
          ? (json['safetyRatings'] as List)
              .map((i) => SafetyRating.fromJson(i))
              .toList()
          : null,
    );
  }
}