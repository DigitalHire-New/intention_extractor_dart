import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intent.dart';
import '../models/classification_result.dart';
import '../utils/text_analyzer.dart';

/// OpenAI GPT-3.5-turbo service for intent classification
class OpenAIService {
  final String apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const int _timeoutMs = 5000; // 5 second timeout

  OpenAIService(this.apiKey);

  Future<ClassificationResult> classify(String message) async {
    final startTime = DateTime.now();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intent classifier for a hiring platform. Classify messages into: JOB_POST (hiring/recruiting/posting jobs), INTERVIEW (scheduling/conducting interviews), or CANDIDATE_SEARCH (finding/browsing/searching candidates). Respond ONLY with valid JSON: {"intent":"JOB_POST|INTERVIEW|CANDIDATE_SEARCH","confidence":0.0-1.0}'
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0,
          'max_tokens': 50,
        }),
      ).timeout(Duration(milliseconds: _timeoutMs));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content);

        Intent? intent;
        if (result['intent'] == 'JOB_POST') intent = Intent.jobPost;
        else if (result['intent'] == 'INTERVIEW') intent = Intent.interview;
        else if (result['intent'] == 'CANDIDATE_SEARCH') intent = Intent.candidateSearch;

        final fields = _extractFields(message, intent);
        final responseTime = DateTime.now().difference(startTime).inMilliseconds;

        return ClassificationResult(
          intent: intent,
          fields: fields,
          confidence: (result['confidence'] as num?)?.toDouble() ?? 0.9,
          tier: 'gpt',
          responseTimeMs: responseTime,
        );
      }
    } catch (e) {
      // API failed or timed out - return null
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      return ClassificationResult(
        intent: null,
        fields: {},
        confidence: 0.0,
        tier: 'failed',
        responseTimeMs: responseTime,
      );
    }

    // Fallback - return null
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;
    return ClassificationResult(
      intent: null,
      fields: {},
      confidence: 0.0,
      tier: 'failed',
      responseTimeMs: responseTime,
    );
  }

  Map<String, dynamic> _extractFields(String message, Intent? intent) {
    // Reuse existing TextAnalyzer for field extraction
    final fields = <String, dynamic>{};
    if (intent == null) return fields;

    final jobTitle = TextAnalyzer.extractJobTitle(message);
    if (jobTitle != null) fields['title'] = jobTitle;

    final skills = TextAnalyzer.extractSkills(message);
    if (skills.isNotEmpty) fields['skills'] = skills;

    final salary = TextAnalyzer.extractCompensation(message);
    if (salary != null) fields['salary'] = salary;

    final location = TextAnalyzer.extractLocation(message);
    if (location != null) fields['location'] = location;

    final workplaceType = TextAnalyzer.extractWorkplaceType(message);
    if (workplaceType != null) fields['workplace_type'] = workplaceType;

    if (intent == Intent.jobPost) {
      final experience = TextAnalyzer.extractExperience(message);
      if (experience != null) fields['experience'] = experience;
    }

    return fields;
  }
}
