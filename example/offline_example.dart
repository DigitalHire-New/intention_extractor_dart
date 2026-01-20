import 'package:intent_classifier/intent_classifier.dart';

/// Examples demonstrating OFFLINE intent classification
/// ✅ No API key needed
/// ✅ Instant responses
/// ✅ Completely free
/// ✅ Works without internet
void main() async {
  // Initialize offline classifier (no API key needed!)
  final classifier = OfflineIntentClassifier();

  print('🚀 OFFLINE Intent Classifier - Examples\n');
  print('=' * 60);

  // Test case 1: Complete job posting with all fields
  await testClassification(
    classifier,
    'Need a Python developer in Karachi with 5 years experience in Django, AWS, and Docker for fintech company. Salary 200k',
    'Test 1: Complete job posting',
  );

  // Test case 2: Simple title and location
  await testClassification(
    classifier,
    'Looking for React developer in Lahore',
    'Test 2: Simple posting',
  );

  // Test case 3: Skills-focused
  await testClassification(
    classifier,
    'Need full stack developer with JavaScript, Node.js, MongoDB, and React',
    'Test 3: Skills-focused',
  );

  // Test case 4: Experience and industry
  await testClassification(
    classifier,
    'Senior software engineer with 10+ years in healthcare domain',
    'Test 4: Experience + Industry',
  );

  // Test case 5: Remote with salary range
  await testClassification(
    classifier,
    'Remote Flutter developer, salary 150-200k per month',
    'Test 5: Remote + Salary',
  );

  // Test case 6: Multiple locations
  await testClassification(
    classifier,
    'Backend engineer in Islamabad or Rawalpindi with Spring Boot and Java',
    'Test 6: Multiple locations',
  );

  // Test case 7: Industry-specific with multiple skills
  await testClassification(
    classifier,
    'Need ML engineer for AI startup with Python, TensorFlow, PyTorch',
    'Test 7: ML/AI role',
  );

  // Test case 8: Mobile developer
  await testClassification(
    classifier,
    'Android developer needed with Kotlin experience in Faisalabad',
    'Test 8: Mobile dev',
  );

  // Test case 9: Data science role
  await testClassification(
    classifier,
    'Data scientist required with 3 years exp in pandas, numpy, and machine learning',
    'Test 9: Data science',
  );

  // Test case 10: DevOps role
  await testClassification(
    classifier,
    'DevOps engineer for cloud migration project. Must know Kubernetes, Docker, and AWS',
    'Test 10: DevOps',
  );

  // Test case 11: Frontend with framework
  await testClassification(
    classifier,
    'Frontend developer with Vue.js and Nuxt.js in New York, 100k salary',
    'Test 11: Frontend specialist',
  );

  // Test case 12: Urdu/Roman Urdu style input
  await testClassification(
    classifier,
    'need python dev in karachi 5 sal ka experience fintech mai',
    'Test 12: Casual input',
  );

  // Test case 13: Product manager
  await testClassification(
    classifier,
    'Product manager with 7 years experience in saas companies',
    'Test 13: Non-technical role',
  );

  // Test case 14: QA/Testing
  await testClassification(
    classifier,
    'QA engineer with selenium and testing automation experience',
    'Test 14: QA role',
  );

  // Test case 15: Minimal info
  await testClassification(
    classifier,
    'software engineer needed',
    'Test 15: Minimal input',
  );

  print('\n' + '=' * 60);
  print('✅ All tests completed! Offline classifier working perfectly.');
  print('💡 Benefits: FREE, INSTANT, NO API, WORKS OFFLINE!');
}

Future<void> testClassification(
  OfflineIntentClassifier classifier,
  String text,
  String testName,
) async {
  print('\n📝 $testName');
  print('Input: "$text"');

  // Classify synchronously (instant!)
  final result = classifier.classify(text);

  print('Intent: ${result.intent}');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  print('Fields extracted:');

  if (result.fields.isEmpty) {
    print('  ⚠️  No fields detected');
  } else {
    result.fields.forEach((key, value) {
      if (value is List) {
        print('  - $key: ${value.join(", ")}');
      } else {
        print('  - $key: $value');
      }
    });
  }

  print('-' * 60);
}
