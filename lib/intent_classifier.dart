/// A Dart package for intelligent job search intent classification
///
/// This library provides accurate NLP-based detection of job search intents and
/// extraction of structured fields (title, location, experience, skills, salary, industry)
/// from natural language queries.
///
/// The [IntentClassifier] automatically switches between:
/// - OFFLINE mode: When no API key provided (instant, free, regex-based)
/// - ONLINE mode: When API key provided (accurate, OpenAI GPT-based)
///
/// Example:
/// ```dart
/// // Offline mode (no API key needed!)
/// final classifier = IntentClassifier();
/// final result = await classifier.classify('Python developer in NYC');
///
/// // Online mode (for better accuracy)
/// final classifier = IntentClassifier(apiKey: 'sk-...');
/// final result = await classifier.classify('Python developer in NYC');
/// ```
library intent_classifier;

export 'src/intent_classifier.dart';
export 'src/models.dart';
