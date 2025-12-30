/// Represents the user's intent when searching for jobs
enum UserIntent {
  searchJob,
  findSimilar,
  jobDescription,
  boolean,
  selectManually,
  unknown,
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
    // Parse intent
    UserIntent? intent;
    final intentStr = json['intent']?.toString().toLowerCase();
    if (intentStr != null) {
      switch (intentStr) {
        case 'search_job':
        case 'searchjob':
          intent = UserIntent.searchJob;
          break;
        case 'find_similar':
        case 'findsimilar':
          intent = UserIntent.findSimilar;
          break;
        case 'job_description':
        case 'jobdescription':
          intent = UserIntent.jobDescription;
          break;
        case 'boolean':
          intent = UserIntent.boolean;
          break;
        case 'select_manually':
        case 'selectmanually':
          intent = UserIntent.selectManually;
          break;
        default:
          intent = UserIntent.unknown;
      }
    }

    return ClassificationResult(
      intent: intent,
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
