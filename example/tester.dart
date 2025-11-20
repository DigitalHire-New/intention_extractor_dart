import 'dart:io';
import 'package:user_intent_classifier/user_intent_classifier.dart';

void main(List<String> args) async {
  // Check if input is provided
  if (args.isEmpty) {
    print('Usage: dart tester.dart "your message here"');
    print('Example: dart tester.dart "i want to interview a sales person"');
    exit(1);
  }

  // Get the input message (join all args in case quotes were missed)
  final message = args.join(' ');

  print('🔍 Classifying: "$message"\n');

  // Initialize classifier
  final classifier = IntentClassifier();

  // Classify the message
  final result = await classifier.classify(message);

  // Print results
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 CLASSIFICATION RESULT');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Intent:     ${result.intent?.value ?? "NULL"}');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  print('Time:       ${result.responseTimeMs}ms');
  print('Tier:       ${result.tier}');

  if (result.fields.isNotEmpty) {
    print('\n📋 EXTRACTED FIELDS:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    result.fields.forEach((key, value) {
      if (value is List) {
        print('$key: ${value.join(", ")}');
      } else {
        print('$key: $value');
      }
    });
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}
