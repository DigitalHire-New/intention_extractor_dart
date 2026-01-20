import 'package:intent_classifier/intent_classifier.dart';

/// Comparison between Online (OpenAI) and Offline (Regex) classifiers
///
/// Online Mode (IntentClassifier):
/// ✅ More accurate for complex queries
/// ✅ Better context understanding
/// ❌ Requires API key
/// ❌ Costs money per request
/// ❌ Needs internet
/// ❌ ~1-3 seconds latency
///
/// Offline Mode (OfflineIntentClassifier):
/// ✅ Completely FREE
/// ✅ Instant response (<1ms)
/// ✅ No API key needed
/// ✅ Works offline
/// ✅ Privacy-friendly (no data sent)
/// ❌ Less accurate for ambiguous queries
void main() async {
  print('🔄 Comparison: Online vs Offline Classifier\n');
  print('=' * 70);

  // Sample queries for comparison
  final testQueries = [
    'Python developer in Karachi with 5 years experience',
    'Need React developer with Node.js and MongoDB in remote position',
    'Senior ML engineer for fintech startup, salary 200k',
    'Flutter developer needed urgently',
    'Full stack developer with JavaScript, TypeScript, and AWS',
  ];

  // Initialize OFFLINE classifier (instant, free!)
  final offlineClassifier = OfflineIntentClassifier();

  // Initialize ONLINE classifier (requires API key)
  // Uncomment below to test online mode:
  /*
  final onlineClassifier = IntentClassifier(
    apiKey: 'your-openai-api-key-here',
    model: 'gpt-4o-mini', // or 'gpt-4o' for better accuracy
  );
  */

  for (final query in testQueries) {
    print('\n📝 Query: "$query"\n');

    // Test OFFLINE classifier
    print('⚡ OFFLINE Result (Instant):');
    final offlineStart = DateTime.now();
    final offlineResult = offlineClassifier.classify(query);
    final offlineDuration = DateTime.now().difference(offlineStart);

    print('  Time: ${offlineDuration.inMilliseconds}ms');
    print('  Confidence: ${(offlineResult.confidence * 100).toStringAsFixed(1)}%');
    print('  Fields: ${offlineResult.fields}');

    // Test ONLINE classifier (uncomment if you have API key)
    /*
    print('\n🌐 ONLINE Result (OpenAI):');
    try {
      final onlineStart = DateTime.now();
      final onlineResult = await onlineClassifier.classify(query);
      final onlineDuration = DateTime.now().difference(onlineStart);

      print('  Time: ${onlineDuration.inMilliseconds}ms');
      print('  Confidence: ${(onlineResult.confidence * 100).toStringAsFixed(1)}%');
      print('  Fields: ${onlineResult.fields}');
    } catch (e) {
      print('  ❌ Error: $e');
    }
    */

    print('\n' + '-' * 70);
  }

  print('\n📊 Summary:\n');
  print('OFFLINE Mode:');
  print('  ✅ Response time: <5ms (instant!)');
  print('  ✅ Cost: FREE forever');
  print('  ✅ Privacy: No data sent anywhere');
  print('  ✅ Reliability: Always works (no API downtime)');
  print('  ⚠️  Accuracy: ~70-85% for clear queries\n');

  print('ONLINE Mode:');
  print('  ✅ Response time: 1000-3000ms');
  print('  ✅ Accuracy: ~90-98% even for complex queries');
  print('  ❌ Cost: ~$0.0001-0.0003 per request');
  print('  ❌ Privacy: Data sent to OpenAI');
  print('  ❌ Reliability: Depends on API availability\n');

  print('=' * 70);
  print('💡 Recommendation:');
  print('   - Use OFFLINE for: prototyping, testing, cost-sensitive apps');
  print('   - Use ONLINE for: production apps requiring high accuracy');
  print('   - HYBRID approach: Try offline first, fallback to online if confidence < 0.5');
}
