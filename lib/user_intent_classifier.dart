/// User Intent Classifier Library
///
/// A high-performance intent classification system for hiring platforms.
/// Classifies user messages into JOB_POST or INTERVIEW intents and extracts
/// relevant fields like job title, location, experience, etc.
///
/// Features:
/// - 3-tier hybrid architecture (rules, ML, API)
/// - <500ms response time (90%+ requests under 10ms)
/// - Handles 10,000+ requests per day
/// - Automatic field extraction
///
/// Example:
/// ```dart
/// final classifier = IntentClassifier(geminiApiKey: 'your-api-key');
/// final result = await classifier.classify('Help me find candidates for a Software Engineer role');
/// print(result.intent); // Intent.jobPost
/// print(result.fields); // {JOB_TITLE: Software Engineer}
/// ```

library;

export 'models/intent.dart';
export 'models/classification_result.dart';
export 'intent_classifier.dart';
