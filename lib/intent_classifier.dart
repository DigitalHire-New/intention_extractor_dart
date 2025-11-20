import 'models/classification_result.dart';
import 'rules/rule_based_classifier.dart';
import 'services/gemini_service.dart';

/// Hybrid Intent Classifier
///
/// Uses a three-tier approach for optimal performance:
/// - Tier 1: Rule-based classifier (fast, <10ms, 70% coverage)
/// - Tier 2: ML model (medium, ~150ms, reserved for future)
/// - Tier 3: Gemini API (accurate, ~500ms, fallback for complex cases)
class IntentClassifier {
  final RuleBasedClassifier _ruleClassifier;
  final GeminiService? _geminiService;

  // Configuration
  final double tier1ConfidenceThreshold;
  final bool enableApiFailback;

  IntentClassifier({
    String? geminiApiKey,
    this.tier1ConfidenceThreshold = 0.5,
    this.enableApiFailback = true,
  })  : _ruleClassifier = RuleBasedClassifier(),
        _geminiService = geminiApiKey != null ? GeminiService(apiKey: geminiApiKey) : null;

  /// Classify user message and extract fields
  ///
  /// Returns ClassificationResult with:
  /// - intent: JOB_POST, INTERVIEW, or null
  /// - fields: Extracted information (job title, location, etc.)
  /// - confidence: 0.0 to 1.0
  /// - tier: Which classifier was used
  /// - responseTimeMs: Processing time in milliseconds
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

    // Tier 1: Try rule-based classifier (fast)
    final ruleResult = _ruleClassifier.classify(message);

    // If confidence is high enough, return immediately
    if (ruleResult.confidence >= tier1ConfidenceThreshold) {
      return ruleResult;
    }

    // Tier 2: ML model (reserved for future implementation)
    // TODO: Add TFLite model here

    // Tier 3: Fallback to Gemini API for complex cases
    if (enableApiFailback && _geminiService != null) {
      try {
        final apiResult = await _geminiService!.classify(message);

        // If API provides a better result, use it
        if (apiResult.intent != null || apiResult.confidence > ruleResult.confidence) {
          return apiResult;
        }
      } catch (e) {
        // If API fails, fall back to rule-based result
        print('Gemini API failed: $e');
      }
    }

    // Return rule-based result as final fallback
    return ruleResult;
  }

  /// Batch classify multiple messages (for efficiency)
  Future<List<ClassificationResult>> classifyBatch(List<String> messages) async {
    final results = <ClassificationResult>[];

    for (var message in messages) {
      final result = await classify(message);
      results.add(result);
    }

    return results;
  }

  /// Classify without API fallback (always fast, under 10ms)
  ClassificationResult classifyFast(String message) {
    return _ruleClassifier.classify(message);
  }
}
