import 'config/api_keys.dart';
import 'models/classification_result.dart';
import 'services/openai_service.dart';

/// Simple Intent Classifier using GPT-3.5-turbo
///
/// Classifies user messages into:
/// - JOB_POST (hiring/recruiting)
/// - INTERVIEW (scheduling/conducting interviews)
/// - CANDIDATE_SEARCH (finding/browsing candidates)
///
/// Example:
/// ```dart
/// final classifier = IntentClassifier();
/// final result = await classifier.classify('Hire Software Engineer');
/// print(result.intent); // Intent.jobPost
/// ```
class IntentClassifier {
  final OpenAIService _openai;

  IntentClassifier({String? apiKey}) : _openai = OpenAIService(apiKey ?? openaiApiKey);

  /// Classify user intent using GPT-3.5-turbo
  ///
  /// Returns ClassificationResult with:
  /// - intent: JOB_POST, INTERVIEW, CANDIDATE_SEARCH, or null
  /// - fields: Extracted information (job title, location, etc.)
  /// - confidence: 0.0 to 1.0
  /// - tier: 'gpt' or 'failed'
  /// - responseTimeMs: Processing time in milliseconds (target <250ms)
  Future<ClassificationResult> classify(String message) async {
    if (message.trim().isEmpty) {
      return ClassificationResult(
        intent: null,
        fields: {},
        confidence: 0.0,
        tier: 'empty',
        responseTimeMs: 0,
      );
    }

    return await _openai.classify(message);
  }

  /// Batch classify multiple messages
  Future<List<ClassificationResult>> classifyBatch(List<String> messages) async {
    final results = <ClassificationResult>[];
    for (var message in messages) {
      results.add(await classify(message));
    }
    return results;
  }
}
