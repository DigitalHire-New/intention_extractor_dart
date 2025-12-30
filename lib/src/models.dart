/// Represents the user's intent when creating job posts
enum UserIntent {
  createJobPost,
}

/// Represents the classification result from the intent classifier
class ClassificationResult {
  /// The detected user intent
  final UserIntent? intent;

  /// Extracted fields with their values from the query
  final Map<String, dynamic> fields;

  /// Confidence score (0.0 to 1.0) for the classification
  final double confidence;

  /// Raw response from the API (for debugging)
  final String? rawResponse;

  ClassificationResult({
    required this.intent,
    required this.fields,
    this.confidence = 1.0,
    this.rawResponse,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    // Intent is always createJobPost
    return ClassificationResult(
      intent: UserIntent.createJobPost,
      fields: Map<String, dynamic>.from(json['fields'] ?? {}),
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      rawResponse: json['raw_response']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent?.toString().split('.').last,
      'fields': fields,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'ClassificationResult(intent: $intent, fields: $fields, confidence: $confidence)';
  }
}
