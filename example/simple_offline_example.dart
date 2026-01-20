import 'package:intent_classifier/intent_classifier.dart';

/// Simple example showing OFFLINE mode usage
/// Same API, just don't provide an apiKey!
void main() async {
  // Initialize classifier WITHOUT API key = OFFLINE mode!
  // ✅ No API key needed
  // ✅ Completely FREE
  // ✅ Instant response
  // ✅ Works offline
  final classifier = IntentClassifier();

  print('🚀 Testing OFFLINE Intent Classifier\n');
  print('=' * 60);

  // Test various job postings
  final testCases = [
    'Need Python developer in Karachi with 5 years experience',
    'React developer required in Lahore for fintech startup',
    'Senior Flutter developer, remote, salary 200k, with 10 years exp',
    'Full stack engineer with JavaScript, Node.js, MongoDB, and AWS',
    'Data scientist with machine learning and Python skills',
    'DevOps engineer needed with Docker and Kubernetes',
    'Android developer in Islamabad with Kotlin experience',
    'Need software engineer',
  ];

  for (final query in testCases) {
    print('\n📝 Query: "$query"');

    final startTime = DateTime.now();
    final result = await classifier.classify(query);
    final duration = DateTime.now().difference(startTime);

    print('⚡ Response time: ${duration.inMilliseconds}ms');
    print('✅ Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
    print('📊 Fields extracted:');

    if (result.fields.isEmpty) {
      print('   ⚠️  No specific fields detected');
    } else {
      result.fields.forEach((key, value) {
        if (value is List) {
          print('   • $key: ${value.join(", ")}');
        } else {
          print('   • $key: $value');
        }
      });
    }

    print('-' * 60);
  }

  print('\n✨ Benefits of Offline Mode:');
  print('   • FREE forever (no API costs)');
  print('   • Instant response (<5ms)');
  print('   • No internet required');
  print('   • Privacy-friendly (no data sent anywhere)');
  print('   • No API key management');
  print('   • Perfect for development & testing');
}
