import 'package:user_intent_classifier/user_intent_classifier.dart';
import 'dart:io';

/// Example usage of the Intent Classifier
void main(List<String> arguments) async {
  print('=== User Intent Classifier Demo ===\n');

  // Initialize classifier
  // Option 1: Without API (fast rule-based only)
  final classifier = IntentClassifier();

  // Option 2: With Gemini API (for complex cases)
  // Uncomment and add your API key:
  // final classifier = IntentClassifier(geminiApiKey: 'YOUR_GEMINI_API_KEY');

  // Test messages
  final testMessages = [
    'Help me find candidates for a Software Engineer position',
    'I need to hire a Senior Python Developer with 5 years experience',
    'Looking for a Flutter developer in New York, salary \$120k',
    'Schedule an interview with John tomorrow at 3 PM',
    'Set up a call with the candidate for the backend role',
    'What is the weather today?', // Should return null
    'Post a job for React developer with AWS and Docker skills',
  ];

  print('Running classification tests...\n');

  for (var message in testMessages) {
    print('Message: "$message"');

    // Classify
    final result = await classifier.classify(message);

    // Display results
    print('  Intent: ${result.intent?.value ?? 'NULL'}');
    print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
    print('  Tier: ${result.tier}');
    print('  Response Time: ${result.responseTimeMs}ms');

    if (result.fields.isNotEmpty) {
      print('  Extracted Fields:');
      result.fields.forEach((key, value) {
        print('    $key: $value');
      });
    }

    print('');
  }

  // Interactive mode
  if (arguments.contains('--interactive')) {
    print('\n=== Interactive Mode ===');
    print('Enter messages to classify (type "exit" to quit):\n');

    while (true) {
      stdout.write('> ');
      final input = stdin.readLineSync();

      if (input == null || input.toLowerCase() == 'exit') {
        print('Goodbye!');
        break;
      }

      if (input.trim().isEmpty) continue;

      final result = await classifier.classify(input);
      print('\nResult: ${result.toJson()}\n');
    }
  }

  print('Demo completed!');
}
