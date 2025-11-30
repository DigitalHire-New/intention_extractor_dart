import 'dart:async';
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
/// Features:
/// - In-memory caching for instant results on repeated queries
/// - Automatic debouncing (300ms) to reduce API calls
/// - Smart concurrency management
///
/// Example:
/// ```dart
/// final classifier = IntentClassifier();
/// final result = await classifier.classify('Hire Software Engineer');
/// print(result.intent); // Intent.jobPost
/// ```
class IntentClassifier {
  final OpenAIService _openai;

  // Cache for instant responses on repeated queries
  final Map<String, ClassificationResult> _cache = {};
  static const int _maxCacheSize = 100;

  // Debouncing to reduce API calls
  Timer? _debounceTimer;
  static const int _debounceDurationMs = 300;
  String? _lastQuery;
  Completer<ClassificationResult>? _debounceCompleter;

  IntentClassifier({String? apiKey}) : _openai = OpenAIService(apiKey ?? openaiApiKey);

  /// Classify user intent using GPT-3.5-turbo
  ///
  /// Features:
  /// - Instant cache hits (<1ms for repeated queries)
  /// - Automatic 300ms debouncing for real-time search
  /// - Smart concurrency management (max 3 concurrent requests)
  ///
  /// Returns ClassificationResult with:
  /// - intent: JOB_POST, INTERVIEW, CANDIDATE_SEARCH, or null
  /// - fields: Extracted information (job title, location, etc.)
  /// - confidence: 0.0 to 1.0
  /// - tier: 'cache', 'gpt', or 'failed'
  /// - responseTimeMs: Processing time in milliseconds
  Future<ClassificationResult> classify(String message, {bool useDebounce = true}) async {
    if (message.trim().isEmpty) {
      return ClassificationResult(
        intent: null,
        fields: {},
        confidence: 0.0,
        tier: 'empty',
        responseTimeMs: 0,
      );
    }

    final normalizedMessage = message.trim().toLowerCase();

    // Check cache first - instant response!
    if (_cache.containsKey(normalizedMessage)) {
      final cached = _cache[normalizedMessage]!;
      return ClassificationResult(
        intent: cached.intent,
        fields: cached.fields,
        confidence: cached.confidence,
        tier: 'cache',
        responseTimeMs: 0, // Instant!
      );
    }

    // Use debouncing for real-time search
    if (useDebounce) {
      return _classifyWithDebounce(message, normalizedMessage);
    }

    // Direct API call without debounce
    return _classifyAndCache(message, normalizedMessage);
  }

  Future<ClassificationResult> _classifyWithDebounce(String message, String normalizedMessage) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    _debounceCompleter?.completeError('Cancelled by new request');

    // Create new completer for this request
    _debounceCompleter = Completer<ClassificationResult>();
    _lastQuery = normalizedMessage;

    // Wait 300ms before making API call
    _debounceTimer = Timer(Duration(milliseconds: _debounceDurationMs), () async {
      if (_lastQuery == normalizedMessage) {
        try {
          final result = await _classifyAndCache(message, normalizedMessage);
          if (!_debounceCompleter!.isCompleted) {
            _debounceCompleter!.complete(result);
          }
        } catch (e) {
          if (!_debounceCompleter!.isCompleted) {
            _debounceCompleter!.completeError(e);
          }
        }
      }
    });

    return _debounceCompleter!.future;
  }

  Future<ClassificationResult> _classifyAndCache(String message, String normalizedMessage) async {
    final result = await _openai.classify(message);

    // Cache successful results
    if (result.intent != null) {
      _cache[normalizedMessage] = result;

      // Limit cache size
      if (_cache.length > _maxCacheSize) {
        final firstKey = _cache.keys.first;
        _cache.remove(firstKey);
      }
    }

    return result;
  }

  /// Batch classify multiple messages (without debouncing)
  Future<List<ClassificationResult>> classifyBatch(List<String> messages) async {
    final results = <ClassificationResult>[];
    for (var message in messages) {
      results.add(await classify(message, useDebounce: false));
    }
    return results;
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'hitRate': _cache.isNotEmpty ? '${(_cache.length / _maxCacheSize * 100).toStringAsFixed(1)}%' : '0%',
    };
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _cache.clear();
    _openai.dispose();
  }
}
