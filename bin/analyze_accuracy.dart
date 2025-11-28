/// Analyzes classifier accuracy and identifies improvement areas
///
/// Run: dart run bin/analyze_accuracy.dart

import 'dart:io';
import 'dart:math';
import 'package:user_intent_classifier/user_intent_classifier.dart';

void main() async {
  print('📊 Analyzing Classifier Accuracy & Identifying Gaps\n');

  // Load training data
  final file = File('training_data_100k.csv');
  if (!file.existsSync()) {
    print('❌ Please run generate_training_data.dart first!');
    return;
  }

  final lines = await file.readAsLines();
  final prompts = <TestCase>[];

  // Parse CSV (skip header)
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    final parts = _parseCSVLine(line);
    if (parts.length >= 2) {
      final text = parts[0];
      final intentStr = parts[1];
      Intent? intent;

      if (intentStr == 'JOB_POST') intent = Intent.jobPost;
      else if (intentStr == 'INTERVIEW') intent = Intent.interview;
      else if (intentStr == 'CANDIDATE_SEARCH') intent = Intent.candidateSearch;

      prompts.add(TestCase(text, intent));
    }
  }

  print('📁 Loaded ${prompts.length} test cases\n');

  // Sample for analysis (5000 prompts for detailed analysis)
  final random = Random(42);
  final sample = <TestCase>[];
  for (var i = 0; i < min(5000, prompts.length); i++) {
    sample.add(prompts[random.nextInt(prompts.length)]);
  }

  // Run classifier on sample
  print('🔍 Running classifier on ${sample.length} samples...\n');
  final classifier = IntentClassifier();

  final results = <TestResult>[];
  var processed = 0;

  for (var testCase in sample) {
    final result = await classifier.classify(testCase.text);
    results.add(TestResult(
      text: testCase.text,
      expected: testCase.intent,
      predicted: result.intent,
      confidence: result.confidence,
    ));

    processed++;
    if (processed % 500 == 0) {
      print('   Processed $processed/${sample.length}...');
    }
  }

  print('\n');

  // Analyze results
  _analyzeResults(results);
}

List<String> _parseCSVLine(String line) {
  final parts = <String>[];
  var current = '';
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      parts.add(current);
      current = '';
    } else {
      current += char;
    }
  }

  parts.add(current);
  return parts;
}

void _analyzeResults(List<TestResult> results) {
  // Overall accuracy
  final correct = results.where((r) => r.expected == r.predicted).length;
  final total = results.length;
  final accuracy = (correct / total * 100).toStringAsFixed(2);

  print('═══════════════════════════════════════════════════════');
  print('📊 OVERALL ACCURACY: $accuracy% ($correct/$total)');
  print('═══════════════════════════════════════════════════════\n');

  // Per-intent accuracy
  print('📈 PER-INTENT ACCURACY:');
  print('───────────────────────────────────────────────────────');

  for (var intent in [Intent.jobPost, Intent.interview, Intent.candidateSearch]) {
    final intentCases = results.where((r) => r.expected == intent).toList();
    if (intentCases.isEmpty) continue;

    final correctIntent = intentCases.where((r) => r.predicted == intent).length;
    final intentAccuracy = (correctIntent / intentCases.length * 100).toStringAsFixed(2);

    print('${intent.value.padRight(20)}: $intentAccuracy% ($correctIntent/${intentCases.length})');
  }

  print('\n');

  // Confusion matrix
  print('🔀 CONFUSION MATRIX:');
  print('───────────────────────────────────────────────────────');
  print('                    Predicted →');
  print('Expected ↓          JOB_POST    INTERVIEW   SEARCH      NULL');
  print('───────────────────────────────────────────────────────');

  for (var expected in [Intent.jobPost, Intent.interview, Intent.candidateSearch]) {
    final row = expected.value.padRight(18);
    final jobPostCount = results.where((r) => r.expected == expected && r.predicted == Intent.jobPost).length;
    final interviewCount = results.where((r) => r.expected == expected && r.predicted == Intent.interview).length;
    final searchCount = results.where((r) => r.expected == expected && r.predicted == Intent.candidateSearch).length;
    final nullCount = results.where((r) => r.expected == expected && r.predicted == null).length;

    print('$row ${jobPostCount.toString().padLeft(8)}    ${interviewCount.toString().padLeft(8)}   ${searchCount.toString().padLeft(6)}    ${nullCount.toString().padLeft(4)}');
  }

  print('\n');

  // Misclassification analysis
  print('❌ TOP MISCLASSIFICATION PATTERNS:');
  print('───────────────────────────────────────────────────────');

  final misclassified = results.where((r) => r.expected != r.predicted).toList();

  // Group by expected -> predicted
  final patterns = <String, List<TestResult>>{};
  for (var result in misclassified) {
    final key = '${result.expected?.value ?? "null"} → ${result.predicted?.value ?? "null"}';
    patterns.putIfAbsent(key, () => []).add(result);
  }

  // Sort by frequency
  final sortedPatterns = patterns.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  for (var i = 0; i < min(5, sortedPatterns.length); i++) {
    final entry = sortedPatterns[i];
    print('\n${i + 1}. ${entry.key} (${entry.value.length} cases)');
    print('   Examples:');

    for (var j = 0; j < min(3, entry.value.length); j++) {
      final example = entry.value[j];
      final truncated = example.text.length > 80
          ? '${example.text.substring(0, 77)}...'
          : example.text;
      print('   - "$truncated"');
      print('     Confidence: ${(example.confidence * 100).toStringAsFixed(1)}%');
    }
  }

  print('\n');

  // Low confidence correct predictions
  print('⚠️  LOW CONFIDENCE CORRECT PREDICTIONS (< 60%):');
  print('───────────────────────────────────────────────────────');

  final lowConfidenceCorrect = results
      .where((r) => r.expected == r.predicted && r.confidence < 0.6)
      .toList()
    ..sort((a, b) => a.confidence.compareTo(b.confidence));

  for (var i = 0; i < min(5, lowConfidenceCorrect.length); i++) {
    final result = lowConfidenceCorrect[i];
    final truncated = result.text.length > 80
        ? '${result.text.substring(0, 77)}...'
        : result.text;
    print('${i + 1}. "${truncated}"');
    print('   Intent: ${result.expected?.value}, Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%\n');
  }

  // Recommendations
  print('═══════════════════════════════════════════════════════');
  print('💡 RECOMMENDATIONS FOR IMPROVEMENT:');
  print('═══════════════════════════════════════════════════════');

  final jobPostMisclassified = results
      .where((r) => r.expected == Intent.jobPost && r.predicted != Intent.jobPost)
      .length;
  final interviewMisclassified = results
      .where((r) => r.expected == Intent.interview && r.predicted != Intent.interview)
      .length;
  final searchMisclassified = results
      .where((r) => r.expected == Intent.candidateSearch && r.predicted != Intent.candidateSearch)
      .length;

  if (jobPostMisclassified > interviewMisclassified && jobPostMisclassified > searchMisclassified) {
    print('1. 🎯 Focus on JOB_POST classification');
    print('   - Most misclassifications are in JOB_POST');
    print('   - Add more JOB_POST patterns to rule_based_classifier.dart:54');
    print('   - Review negative indicators that may be too aggressive');
  } else if (interviewMisclassified > searchMisclassified) {
    print('1. 🎯 Focus on INTERVIEW classification');
    print('   - Most misclassifications are in INTERVIEW');
    print('   - Add more INTERVIEW patterns to rule_based_classifier.dart:330');
  } else {
    print('1. 🎯 Focus on CANDIDATE_SEARCH classification');
    print('   - Most misclassifications are in CANDIDATE_SEARCH');
    print('   - Add more CANDIDATE_SEARCH patterns to rule_based_classifier.dart:509');
  }

  print('\n2. 📝 Review confusion matrix for pattern insights');
  print('   - Identify which intents are being confused');
  print('   - Adjust scoring weights to reduce confusion');

  print('\n3. 🔍 Analyze low confidence correct predictions');
  print('   - These cases need stronger signals');
  print('   - Add missing keywords or patterns');

  print('\n4. ⚖️  Adjust confidence thresholds');
  final avgConfidence = results
      .where((r) => r.expected == r.predicted)
      .map((r) => r.confidence)
      .fold(0.0, (a, b) => a + b) / correct;
  print('   - Average confidence for correct predictions: ${(avgConfidence * 100).toStringAsFixed(1)}%');
  print('   - Current threshold: 50%');

  print('\n5. 🚀 Use Gemini API fallback for edge cases');
  print('   - ${misclassified.length} cases could benefit from API');
  print('   - Consider lowering tier1ConfidenceThreshold for better accuracy');

  print('\n═══════════════════════════════════════════════════════\n');
}

class TestCase {
  final String text;
  final Intent? intent;

  TestCase(this.text, this.intent);
}

class TestResult {
  final String text;
  final Intent? expected;
  final Intent? predicted;
  final double confidence;

  TestResult({
    required this.text,
    required this.expected,
    required this.predicted,
    required this.confidence,
  });
}
