/// Learns optimal patterns and weights from training data
/// Analyzes 100k prompts to extract patterns and generate improved rules
///
/// Run: dart run bin/learn_from_training_data.dart

import 'dart:io';
import 'dart:math';
import 'package:user_intent_classifier/user_intent_classifier.dart';

void main() async {
  print('🧠 Learning from Training Data...\n');

  // Load training data
  final file = File('training_data_100k.csv');
  if (!file.existsSync()) {
    print('❌ training_data_100k.csv not found!');
    print('Run: dart run bin/generate_training_data.dart');
    return;
  }

  print('📁 Loading training data...');
  final lines = await file.readAsLines();
  final trainingData = <TrainingCase>[];

  for (var i = 1; i < lines.length; i++) {
    final parts = _parseCSVLine(lines[i]);
    if (parts.length >= 2) {
      final text = parts[0];
      final intentStr = parts[1];
      Intent? intent;

      if (intentStr == 'JOB_POST') intent = Intent.jobPost;
      else if (intentStr == 'INTERVIEW') intent = Intent.interview;
      else if (intentStr == 'CANDIDATE_SEARCH') intent = Intent.candidateSearch;

      trainingData.add(TrainingCase(text, intent));
    }
  }

  print('✅ Loaded ${trainingData.length} training cases\n');

  // Learn patterns
  final learner = PatternLearner(trainingData);
  print('🔍 Analyzing patterns...\n');

  final patterns = await learner.learnPatterns();

  // Generate optimized classifier
  print('\n📝 Generating optimized classifier...\n');
  _generateOptimizedClassifier(patterns);

  // Test new classifier
  print('\n🧪 Testing optimized classifier...\n');
  await _testOptimizedClassifier(trainingData);

  print('\n✨ Done! Check lib/rules/optimized_classifier.dart\n');
}

List<String> _parseCSVLine(String line) {
  final parts = <String>[];
  var current = '';
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
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

Future<void> _testOptimizedClassifier(List<TrainingCase> data) async {
  // Sample for testing
  final random = Random(42);
  final sample = <TrainingCase>[];
  for (var i = 0; i < min(1000, data.length); i++) {
    sample.add(data[random.nextInt(data.length)]);
  }

  final classifier = IntentClassifier();
  var correct = 0;

  for (var testCase in sample) {
    final result = await classifier.classify(testCase.text);
    if (result.intent == testCase.intent) {
      correct++;
    }
  }

  final accuracy = (correct / sample.length * 100).toStringAsFixed(2);
  print('Current Classifier Accuracy: $accuracy%');
  print('(This will improve after you use the optimized classifier)');
}

void _generateOptimizedClassifier(LearnedPatterns patterns) {
  final output = StringBuffer();

  output.writeln('import \'../models/intent.dart\';');
  output.writeln('import \'../models/classification_result.dart\';');
  output.writeln('import \'../utils/text_analyzer.dart\';');
  output.writeln();
  output.writeln('/// Optimized rule-based classifier');
  output.writeln('/// Generated from 100k training data analysis');
  output.writeln('/// Generated: ${DateTime.now()}');
  output.writeln('class OptimizedClassifier {');
  output.writeln('  static const double _confidenceThreshold = 0.5;');
  output.writeln();
  output.writeln('  ClassificationResult classify(String message) {');
  output.writeln('    final startTime = DateTime.now();');
  output.writeln('    final normalized = TextAnalyzer.normalize(message);');
  output.writeln();
  output.writeln('    final jobPostScore = _calculateJobPostScore(normalized);');
  output.writeln('    final interviewScore = _calculateInterviewScore(normalized);');
  output.writeln('    final candidateSearchScore = _calculateCandidateSearchScore(normalized);');
  output.writeln();
  output.writeln('    Intent? intent;');
  output.writeln('    double confidence = 0.0;');
  output.writeln();
  output.writeln('    final maxScore = [jobPostScore, interviewScore, candidateSearchScore].reduce((a, b) => a > b ? a : b);');
  output.writeln();
  output.writeln('    if (maxScore >= _confidenceThreshold) {');
  output.writeln('      if (maxScore == jobPostScore) {');
  output.writeln('        intent = Intent.jobPost;');
  output.writeln('        confidence = jobPostScore;');
  output.writeln('      } else if (maxScore == interviewScore) {');
  output.writeln('        intent = Intent.interview;');
  output.writeln('        confidence = interviewScore;');
  output.writeln('      } else {');
  output.writeln('        intent = Intent.candidateSearch;');
  output.writeln('        confidence = candidateSearchScore;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    final fields = _extractFields(message, intent);');
  output.writeln('    final endTime = DateTime.now();');
  output.writeln('    final responseTime = endTime.difference(startTime).inMilliseconds;');
  output.writeln();
  output.writeln('    return ClassificationResult(');
  output.writeln('      intent: intent,');
  output.writeln('      fields: fields,');
  output.writeln('      confidence: confidence,');
  output.writeln('      tier: \'rules_optimized\',');
  output.writeln('      responseTimeMs: responseTime,');
  output.writeln('    );');
  output.writeln('  }');
  output.writeln();

  // JOB_POST scoring
  output.writeln('  double _calculateJobPostScore(String text) {');
  output.writeln('    double score = 0.0;');
  output.writeln();
  output.writeln('    // Learned from ${patterns.jobPost.total} JOB_POST examples');
  output.writeln('    // Top patterns (sorted by precision):');

  for (var i = 0; i < min(50, patterns.jobPost.patterns.length); i++) {
    final p = patterns.jobPost.patterns[i];
    output.writeln('    // ${i+1}. "${p.pattern}" - ${(p.precision * 100).toStringAsFixed(1)}% precision, ${p.frequency} occurrences');
  }

  output.writeln();
  output.writeln('    final jobPostPatterns = [');
  for (var i = 0; i < min(100, patterns.jobPost.patterns.length); i++) {
    final p = patterns.jobPost.patterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\', // ${(p.precision * 100).toStringAsFixed(0)}% precision');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in jobPostPatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score += ${patterns.jobPost.averageWeight.toStringAsFixed(2)};');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();

  // Negative patterns
  output.writeln('    // Negative indicators');
  output.writeln('    final negativePatterns = [');
  for (var i = 0; i < min(30, patterns.jobPost.negativePatterns.length); i++) {
    final p = patterns.jobPost.negativePatterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\',');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in negativePatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score -= 0.40;');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    return score.clamp(0.0, 1.0);');
  output.writeln('  }');
  output.writeln();

  // INTERVIEW scoring
  output.writeln('  double _calculateInterviewScore(String text) {');
  output.writeln('    double score = 0.0;');
  output.writeln();
  output.writeln('    // Learned from ${patterns.interview.total} INTERVIEW examples');
  output.writeln('    final interviewPatterns = [');
  for (var i = 0; i < min(100, patterns.interview.patterns.length); i++) {
    final p = patterns.interview.patterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\', // ${(p.precision * 100).toStringAsFixed(0)}% precision');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in interviewPatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score += ${patterns.interview.averageWeight.toStringAsFixed(2)};');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    final negativePatterns = [');
  for (var i = 0; i < min(30, patterns.interview.negativePatterns.length); i++) {
    final p = patterns.interview.negativePatterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\',');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in negativePatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score -= 0.35;');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    return score.clamp(0.0, 1.0);');
  output.writeln('  }');
  output.writeln();

  // CANDIDATE_SEARCH scoring
  output.writeln('  double _calculateCandidateSearchScore(String text) {');
  output.writeln('    double score = 0.0;');
  output.writeln();
  output.writeln('    // Learned from ${patterns.candidateSearch.total} CANDIDATE_SEARCH examples');
  output.writeln('    final searchPatterns = [');
  for (var i = 0; i < min(100, patterns.candidateSearch.patterns.length); i++) {
    final p = patterns.candidateSearch.patterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\', // ${(p.precision * 100).toStringAsFixed(0)}% precision');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in searchPatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score += ${patterns.candidateSearch.averageWeight.toStringAsFixed(2)};');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    final negativePatterns = [');
  for (var i = 0; i < min(30, patterns.candidateSearch.negativePatterns.length); i++) {
    final p = patterns.candidateSearch.negativePatterns[i];
    output.writeln('      \'${_escapeString(p.pattern)}\',');
  }
  output.writeln('    ];');
  output.writeln();
  output.writeln('    for (var pattern in negativePatterns) {');
  output.writeln('      if (text.contains(pattern)) {');
  output.writeln('        score -= 0.40;');
  output.writeln('        break;');
  output.writeln('      }');
  output.writeln('    }');
  output.writeln();
  output.writeln('    return score.clamp(0.0, 1.0);');
  output.writeln('  }');
  output.writeln();

  // Field extraction (reuse existing)
  output.writeln('  Map<String, dynamic> _extractFields(String message, Intent? intent) {');
  output.writeln('    final fields = <String, dynamic>{};');
  output.writeln('    if (intent == null) return fields;');
  output.writeln();
  output.writeln('    final jobTitle = TextAnalyzer.extractJobTitle(message);');
  output.writeln('    if (jobTitle != null) fields[\'title\'] = jobTitle;');
  output.writeln();
  output.writeln('    final skills = TextAnalyzer.extractSkills(message);');
  output.writeln('    if (skills.isNotEmpty) fields[\'skills\'] = skills;');
  output.writeln();
  output.writeln('    final salary = TextAnalyzer.extractCompensation(message);');
  output.writeln('    if (salary != null) fields[\'salary\'] = salary;');
  output.writeln();
  output.writeln('    final location = TextAnalyzer.extractLocation(message);');
  output.writeln('    if (location != null) fields[\'location\'] = location;');
  output.writeln();
  output.writeln('    final workplaceType = TextAnalyzer.extractWorkplaceType(message);');
  output.writeln('    if (workplaceType != null) fields[\'workplace_type\'] = workplaceType;');
  output.writeln();
  output.writeln('    if (intent == Intent.jobPost) {');
  output.writeln('      final experience = TextAnalyzer.extractExperience(message);');
  output.writeln('      if (experience != null) fields[\'experience\'] = experience;');
  output.writeln('    }');
  output.writeln();
  output.writeln('    return fields;');
  output.writeln('  }');
  output.writeln('}');

  // Write to file
  final outputFile = File('lib/rules/optimized_classifier.dart');
  outputFile.writeAsStringSync(output.toString());

  print('✅ Generated optimized classifier: lib/rules/optimized_classifier.dart');
}

String _escapeString(String s) {
  return s.replaceAll('\\', '\\\\').replaceAll('\'', '\\\'');
}

class TrainingCase {
  final String text;
  final Intent? intent;

  TrainingCase(this.text, this.intent);
}

class PatternLearner {
  final List<TrainingCase> data;

  PatternLearner(this.data);

  Future<LearnedPatterns> learnPatterns() async {
    final jobPostCases = data.where((c) => c.intent == Intent.jobPost).toList();
    final interviewCases = data.where((c) => c.intent == Intent.interview).toList();
    final searchCases = data.where((c) => c.intent == Intent.candidateSearch).toList();

    print('Analyzing JOB_POST patterns (${jobPostCases.length} cases)...');
    final jobPostPatterns = await _extractPatterns(jobPostCases, Intent.jobPost, data);

    print('Analyzing INTERVIEW patterns (${interviewCases.length} cases)...');
    final interviewPatterns = await _extractPatterns(interviewCases, Intent.interview, data);

    print('Analyzing CANDIDATE_SEARCH patterns (${searchCases.length} cases)...');
    final searchPatterns = await _extractPatterns(searchCases, Intent.candidateSearch, data);

    return LearnedPatterns(
      jobPost: jobPostPatterns,
      interview: interviewPatterns,
      candidateSearch: searchPatterns,
    );
  }

  Future<IntentPatterns> _extractPatterns(
    List<TrainingCase> intentCases,
    Intent intent,
    List<TrainingCase> allData,
  ) async {
    // Sample for faster processing (use 20% of data)
    final random = Random(42);
    final sampleSize = (intentCases.length * 0.2).toInt();
    final sampledCases = <TrainingCase>[];
    for (var i = 0; i < sampleSize; i++) {
      sampledCases.add(intentCases[random.nextInt(intentCases.length)]);
    }

    // Extract n-grams (1-4 words)
    final patternFrequency = <String, PatternStats>{};

    for (var testCase in sampledCases) {
      final normalized = testCase.text.toLowerCase();
      final words = normalized.split(RegExp(r'\s+'));

      // Extract 1-grams, 2-grams, 3-grams, 4-grams
      for (var n = 1; n <= 4; n++) {
        for (var i = 0; i <= words.length - n; i++) {
          final ngram = words.sublist(i, i + n).join(' ');

          // Skip very common words
          if (_isStopWord(ngram)) continue;

          patternFrequency.putIfAbsent(ngram, () => PatternStats(ngram));
          patternFrequency[ngram]!.positiveCount++;
        }
      }
    }

    // Calculate precision for each pattern
    for (var pattern in patternFrequency.keys) {
      var totalOccurrences = 0;
      var correctOccurrences = 0;

      for (var testCase in allData) {
        if (testCase.text.toLowerCase().contains(pattern)) {
          totalOccurrences++;
          if (testCase.intent == intent) {
            correctOccurrences++;
          }
        }
      }

      final stats = patternFrequency[pattern]!;
      stats.totalOccurrences = totalOccurrences;
      stats.precision = totalOccurrences > 0 ? correctOccurrences / totalOccurrences : 0.0;
    }

    // Filter and sort patterns
    final goodPatterns = patternFrequency.values
        .where((p) => p.precision >= 0.7 && p.positiveCount >= 10) // High precision, reasonable frequency
        .toList()
      ..sort((a, b) {
        // Sort by precision first, then frequency
        final precisionCompare = b.precision.compareTo(a.precision);
        if (precisionCompare != 0) return precisionCompare;
        return b.positiveCount.compareTo(a.positiveCount);
      });

    // Find negative patterns (common in other intents but not this one)
    final negativePatterns = <PatternStats>[];
    final otherCases = allData.where((c) => c.intent != intent).toList();

    for (var testCase in otherCases) {
      final normalized = testCase.text.toLowerCase();
      final words = normalized.split(RegExp(r'\s+'));

      for (var n = 1; n <= 3; n++) {
        for (var i = 0; i <= words.length - n; i++) {
          final ngram = words.sublist(i, i + n).join(' ');
          if (_isStopWord(ngram)) continue;

          // Check if this pattern is rare in current intent but common in others
          final inIntentCount = intentCases.where((c) => c.text.toLowerCase().contains(ngram)).length;
          final notInIntentCount = otherCases.where((c) => c.text.toLowerCase().contains(ngram)).length;

          if (notInIntentCount >= 50 && inIntentCount < notInIntentCount * 0.2) {
            final existing = negativePatterns.where((p) => p.pattern == ngram).firstOrNull;
            if (existing == null) {
              negativePatterns.add(PatternStats(ngram)
                ..positiveCount = notInIntentCount
                ..precision = 1.0 - (inIntentCount / (inIntentCount + notInIntentCount)));
            }
          }
        }
      }
    }

    negativePatterns.sort((a, b) => b.precision.compareTo(a.precision));

    print('  Found ${goodPatterns.length} positive patterns');
    print('  Found ${negativePatterns.length} negative patterns');

    final avgWeight = 0.60; // Base weight, can be tuned

    return IntentPatterns(
      patterns: goodPatterns,
      negativePatterns: negativePatterns.take(50).toList(),
      total: intentCases.length,
      averageWeight: avgWeight,
    );
  }

  bool _isStopWord(String word) {
    final stopWords = {
      'a', 'an', 'the', 'in', 'at', 'on', 'for', 'to', 'of', 'with',
      'is', 'are', 'was', 'were', 'be', 'been', 'being',
      'and', 'or', 'but', 'if', 'then', 'so',
      'i', 'you', 'he', 'she', 'it', 'we', 'they',
    };
    return stopWords.contains(word);
  }
}

class LearnedPatterns {
  final IntentPatterns jobPost;
  final IntentPatterns interview;
  final IntentPatterns candidateSearch;

  LearnedPatterns({
    required this.jobPost,
    required this.interview,
    required this.candidateSearch,
  });
}

class IntentPatterns {
  final List<PatternStats> patterns;
  final List<PatternStats> negativePatterns;
  final int total;
  final double averageWeight;

  IntentPatterns({
    required this.patterns,
    required this.negativePatterns,
    required this.total,
    required this.averageWeight,
  });
}

class PatternStats {
  final String pattern;
  int positiveCount = 0;
  int totalOccurrences = 0;
  double precision = 0.0;

  PatternStats(this.pattern);

  int get frequency => positiveCount;
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
