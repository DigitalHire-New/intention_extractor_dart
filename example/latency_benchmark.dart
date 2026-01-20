import 'package:intent_classifier/intent_classifier.dart';

/// LATENCY BENCHMARK - Measure exact performance
void main() async {
  final classifier = IntentClassifier(); // Offline mode

  print('⚡ LATENCY BENCHMARK - Exact Performance Measurement\n');
  print('=' * 70);

  final testQueries = [
    'Python developer in Karachi with 5 years experience',
    'Need React developer for startup',
    'Hiring doctor for hospital, salary 100k',
    'Sales executive required in Lahore',
    'Chef needed for restaurant',
    'Driver wanted with valid license',
    'Accountant needed with QuickBooks',
    'Teacher required for school',
    'Nurse hiring in Islamabad',
    'Engineer needed urgently',
  ];

  // Warmup (first query might be slower due to initialization)
  print('🔥 Warmup run...');
  await classifier.classify('warmup query');
  print('✅ Warmup complete\n');

  print('📊 Running benchmark with ${testQueries.length} queries...\n');

  final latencies = <int>[];

  for (var i = 0; i < testQueries.length; i++) {
    final query = testQueries[i];

    // Measure latency
    final startTime = DateTime.now();
    final result = await classifier.classify(query);
    final endTime = DateTime.now();

    final latencyMs = endTime.difference(startTime).inMicroseconds / 1000;
    latencies.add(latencyMs.round());

    print('Query ${i + 1}: ${latencyMs.toStringAsFixed(2)}ms');
    print('  Input: "$query"');
    print('  Output: ${result.fields['title'] ?? 'N/A'}');
    print('');
  }

  print('=' * 70);
  print('\n📈 LATENCY STATISTICS:\n');

  // Calculate stats
  latencies.sort();
  final sum = latencies.reduce((a, b) => a + b);
  final avg = sum / latencies.length;
  final min = latencies.first;
  final max = latencies.last;
  final p50 = latencies[(latencies.length * 0.5).floor()];
  final p95 = latencies[(latencies.length * 0.95).floor()];
  final p99 = latencies[(latencies.length * 0.99).floor()];

  print('   Minimum:    ${min}ms');
  print('   Maximum:    ${max}ms');
  print('   Average:    ${avg.toStringAsFixed(2)}ms');
  print('   Median:     ${p50}ms');
  print('   P95:        ${p95}ms');
  print('   P99:        ${p99}ms');

  print('\n🎯 PERFORMANCE RATING:\n');

  if (avg < 5) {
    print('   ⚡⚡⚡ BLAZING FAST (<5ms average)');
  } else if (avg < 10) {
    print('   ⚡⚡ VERY FAST (<10ms average)');
  } else if (avg < 50) {
    print('   ⚡ FAST (<50ms average)');
  } else {
    print('   ⏱️  ACCEPTABLE (>50ms average)');
  }

  print('\n💡 COMPARISON:\n');
  print('   Offline mode (this): ${avg.toStringAsFixed(2)}ms');
  print('   OpenAI GPT-4o-mini:  ~1,500ms (1.5 seconds)');
  print('   OpenAI GPT-4o:       ~2,500ms (2.5 seconds)');
  print('\n   🚀 You are ${(1500 / avg).toStringAsFixed(0)}x FASTER than GPT-4o-mini!');

  // Throughput calculation
  final queriesPerSecond = 1000 / avg;
  print('\n📊 THROUGHPUT:\n');
  print('   ~${queriesPerSecond.toStringAsFixed(0)} queries per second');
  print('   ~${(queriesPerSecond * 60).toStringAsFixed(0)} queries per minute');
  print('   ~${(queriesPerSecond * 3600).toStringAsFixed(0)} queries per hour');
}
