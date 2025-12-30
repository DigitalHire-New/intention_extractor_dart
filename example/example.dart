import 'package:intent_classifier/intent_classifier.dart';

void main() async {
  // Initialize the classifier with your OpenAI API key
  final classifier = IntentClassifier(
    apiKey: 'YOUR_OPENAI_API_KEY',
    // Optional: specify model (default is gpt-4o-mini)
    model: 'gpt-4o-mini',
  );

  // Example 1: Complex job posting description
  print('Example 1: Complex Job Posting');
  final result1 = await classifier.classify(
    'need python developer in new york with 10 years of experience and should be experienced with fintech',
  );
  print('Intent: ${result1.intent}'); // Always: UserIntent.createJobPost
  print('Fields: ${result1.fields}');
  print('Confidence: ${result1.confidence}');
  print('---\n');

  // Example 2: Simple job posting
  print('Example 2: Simple Job Posting');
  final result2 = await classifier.classify('senior react developer');
  print('Intent: ${result2.intent}'); // Always: UserIntent.createJobPost
  print('Fields: ${result2.fields}');
  print('---\n');

  // Example 3: With skills and location
  print('Example 3: Skills and Location');
  final result3 = await classifier.classify(
    'looking for java backend engineer in San Francisco with Spring Boot and AWS experience',
  );
  print('Intent: ${result3.intent}'); // Always: UserIntent.createJobPost
  print('Fields: ${result3.fields}');
  print('---\n');

  // Example 4: With salary
  print('Example 4: With Salary');
  final result4 = await classifier.classify(
    'DevOps engineer with 5 years experience, salary 150k, remote',
  );
  print('Intent: ${result4.intent}'); // Always: UserIntent.createJobPost
  print('Fields: ${result4.fields}');
  print('---\n');

  // Example 5: Industry-specific
  print('Example 5: Industry-Specific');
  final result5 = await classifier.classify(
    'data scientist in healthcare industry with machine learning experience',
  );
  print('Intent: ${result5.intent}'); // Always: UserIntent.createJobPost
  print('Fields: ${result5.fields}');
  print('---\n');
}
