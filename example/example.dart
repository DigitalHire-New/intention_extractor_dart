import 'package:user_intent_classifier/user_intent_classifier.dart';

void main() async {
  print('=== User Intent Classifier Example ===\n');

  // Initialize classifier (uses API key from lib/config/api_keys.dart)
  final classifier = IntentClassifier();

  // Example 1: Job Posting
  print('Example 1: Job Posting');
  var result = await classifier.classify(
    'I need to hire a Senior Flutter Developer in San Francisco with 5 years experience, salary \$120k-\$150k',
  );
  printResult(result);

  // Example 2: Simple Job Title
  print('\nExample 2: Simple Job Title');
  result = await classifier.classify('Software Engineer jobs in New York');
  printResult(result);

  // Example 3: Interview Scheduling
  print('\nExample 3: Interview Scheduling');
  result = await classifier.classify(
    'Schedule an interview with John tomorrow at 2 PM',
  );
  printResult(result);

  // Example 4: Entry Level Position
  print('\nExample 4: Entry Level Position');
  result = await classifier.classify(
    'Entry Level Customer Service jobs - Remote',
  );
  printResult(result);

  // Example 5: Healthcare Position
  print('\nExample 5: Healthcare Position');
  result = await classifier.classify('RN Pediatric Residency Clinic');
  printResult(result);

  // Example 6: Technical Position
  print('\nExample 6: Technical Position');
  result = await classifier.classify('Technical Recruiter - Denver Office');
  printResult(result);

  // Example 7: Null Intent
  print('\nExample 7: Unrelated Message (Null Intent)');
  result = await classifier.classify('What is the weather today?');
  printResult(result);

  // Example 8: Batch Classification
  print('\n=== Batch Classification ===');
  final messages = [
    'Need Python developer',
    'Schedule interview',
    'Marketing Manager in Chicago',
  ];

  final results = await classifier.classifyBatch(messages);
  for (var i = 0; i < messages.length; i++) {
    print('\nMessage ${i + 1}: "${messages[i]}"');
    printResult(results[i]);
  }

  print('\n=== Done! ===');
}

void printResult(ClassificationResult result) {
  print('  Intent: ${result.intent?.value ?? "NULL"}');
  print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  print('  Response Time: ${result.responseTimeMs}ms');
  print('  Tier: ${result.tier}');

  if (result.fields.isNotEmpty) {
    print('  Fields:');
    result.fields.forEach((key, value) {
      if (value is List) {
        print('    $key: ${value.join(", ")}');
      } else {
        print('    $key: $value');
      }
    });
  }
}
