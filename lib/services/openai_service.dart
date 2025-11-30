import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intent.dart';
import '../models/classification_result.dart';

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
              'content': '''You are an intent classifier for a hiring platform.

Classify the message into one of these intents:
- JOB_POST: hiring, recruiting, posting jobs
- INTERVIEW: scheduling, conducting interviews
- CANDIDATE_SEARCH: finding, browsing, searching candidates

Extract ALL relevant fields from the message:
- title: job position/title
- skills: array of technical and soft skills
- salary: compensation information
- location: work location (city, state, country)
- workplace_type: "Remote", "Hybrid", or "Onsite"
- experience: years of experience required

Respond ONLY with valid JSON in this exact format:
{
  "intent": "JOB_POST|INTERVIEW|CANDIDATE_SEARCH",
  "confidence": 0.0-1.0,
  "fields": {
    "title": "extracted title or null",
    "skills": ["skill1", "skill2"] or [],
    "salary": "extracted salary or null",
    "location": "extracted location or null",
    "workplace_type": "Remote|Hybrid|Onsite or null",
    "experience": "extracted experience or null"
  }
}'''
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0,
          'max_tokens': 200,
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

        // Extract fields from GPT response - remove null and empty values
        final rawFields = result['fields'] as Map<String, dynamic>? ?? {};
        final fields = <String, dynamic>{};
        rawFields.forEach((key, value) {
          if (value != null && value != 'null') {
            // Skip empty arrays
            if (value is List && value.isEmpty) return;
            // Skip empty strings
            if (value is String && value.trim().isEmpty) return;
            fields[key] = value;
          }
        });

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
}
