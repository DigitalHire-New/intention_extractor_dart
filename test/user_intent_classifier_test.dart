import 'package:user_intent_classifier/user_intent_classifier.dart';
import 'package:test/test.dart';

void main() {
  group('IntentClassifier', () {
    late IntentClassifier classifier;

    setUp(() {
      classifier = IntentClassifier();
    });

    group('Job Post Intent', () {
      test('should classify simple job posting', () async {
        final result = await classifier.classify('Help me find candidates');

        expect(result.intent, Intent.jobPost);
        expect(result.confidence, greaterThan(0.5));
        expect(result.responseTimeMs, lessThan(50)); // Should be very fast
      });

      test('should classify job posting with title', () async {
        final result = await classifier.classify('I need to hire a Software Engineer');

        expect(result.intent, Intent.jobPost);
        expect(result.fields['JOB_TITLE'], isNotNull);
        expect(result.fields['JOB_TITLE'], contains('Software'));
      });

      test('should extract job fields correctly', () async {
        final result = await classifier.classify(
          'Looking for Senior Python Developer with 5 years experience in New York, salary \$120k'
        );

        expect(result.intent, Intent.jobPost);
        expect(result.fields['JOB_TITLE'], isNotNull);
        expect(result.fields['EXPERIENCE'], isNotNull);
        expect(result.fields['LOCATION'], isNotNull);
        expect(result.fields['COMPENSATION'], isNotNull);
      });

      test('should extract skills from message', () async {
        final result = await classifier.classify(
          'Post job for React developer with AWS, Docker and Python skills'
        );

        expect(result.intent, Intent.jobPost);
        expect(result.fields['SKILLS'], isNotNull);
        expect(result.fields['SKILLS'], isList);
        expect(result.fields['SKILLS'].length, greaterThan(0));
      });

      test('should handle remote location', () async {
        final result = await classifier.classify(
          'Hiring Flutter developer for remote position'
        );

        expect(result.intent, Intent.jobPost);
        expect(result.fields['LOCATION'], isNotNull);
        expect(result.fields['LOCATION'].toLowerCase(), contains('remote'));
      });
    });

    group('Interview Intent', () {
      test('should classify interview scheduling', () async {
        final result = await classifier.classify('Schedule an interview with John');

        expect(result.intent, Intent.interview);
        expect(result.confidence, greaterThan(0.5));
      });

      test('should classify interview with time', () async {
        final result = await classifier.classify(
          'Set up an interview tomorrow at 3 PM'
        );

        expect(result.intent, Intent.interview);
        expect(result.confidence, greaterThan(0.6));
      });

      test('should classify interview call', () async {
        final result = await classifier.classify(
          'Conduct a phone interview with the candidate'
        );

        expect(result.intent, Intent.interview);
      });
    });

    group('Null Intent', () {
      test('should return null for unrelated messages', () async {
        final result = await classifier.classify('What is the weather today?');

        expect(result.intent, isNull);
      });

      test('should return null for empty message', () async {
        final result = await classifier.classify('');

        expect(result.intent, isNull);
        expect(result.tier, 'empty');
      });

      test('should return null for generic greeting', () async {
        final result = await classifier.classify('Hello, how are you?');

        expect(result.intent, isNull);
      });
    });

    group('Performance', () {
      test('should respond within 500ms', () async {
        final result = await classifier.classify(
          'I need to hire a Senior Software Engineer with 10 years experience'
        );

        expect(result.responseTimeMs, lessThan(500));
      });

      test('fast classify should respond under 10ms', () {
        final result = classifier.classifyFast('Help me find candidates');

        expect(result.responseTimeMs, lessThan(10));
      });

      test('should handle batch classification', () async {
        final messages = [
          'Hire developers',
          'Schedule interview',
          'Post job',
          'Set up meeting',
        ];

        final results = await classifier.classifyBatch(messages);

        expect(results.length, messages.length);
        expect(results[0].intent, Intent.jobPost);
        expect(results[1].intent, Intent.interview);
      });
    });

    group('Edge Cases', () {
      test('should handle very long messages', () async {
        final longMessage = 'I need to hire ' + 'a developer ' * 100;
        final result = await classifier.classify(longMessage);

        expect(result, isNotNull);
      });

      test('should handle special characters', () async {
        final result = await classifier.classify(
          'Hire @developer #remote \$120k!!!'
        );

        expect(result.intent, Intent.jobPost);
      });

      test('should handle mixed case', () async {
        final result = await classifier.classify(
          'HELP ME FIND CANDIDATES FOR SOFTWARE ENGINEER'
        );

        expect(result.intent, Intent.jobPost);
      });
    });

    group('Confidence Scoring', () {
      test('should have high confidence for clear intent', () async {
        final result = await classifier.classify(
          'I need to hire candidates for software engineer position'
        );

        expect(result.confidence, greaterThan(0.7));
      });

      test('should have lower confidence for ambiguous messages', () async {
        final result = await classifier.classify('I need help');

        expect(result.confidence, lessThan(0.7));
      });
    });
  });
}
