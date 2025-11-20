import 'intent.dart';

/// Result of intent classification with extracted fields
class ClassificationResult {
  final Intent? intent;
  final Map<String, dynamic> fields;
  final double confidence;
  final String tier; // 'rules', 'ml', or 'api'
  final int responseTimeMs;

  ClassificationResult({
    this.intent,
    required this.fields,
    required this.confidence,
    required this.tier,
    required this.responseTimeMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'intent': intent?.value,
      'fields': fields,
      'confidence': confidence,
      'tier': tier,
      'responseTimeMs': responseTimeMs,
    };
  }

  @override
  String toString() {
    return 'ClassificationResult(intent: ${intent?.value}, fields: $fields, confidence: $confidence, tier: $tier, time: ${responseTimeMs}ms)';
  }
}
