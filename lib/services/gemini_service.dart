import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intent.dart';
import '../models/classification_result.dart';

/// Gemini API service for advanced classification (Tier 3)
class GeminiService {
  final String apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  GeminiService({required this.apiKey});

  /// Classify using Gemini API with field extraction
  Future<ClassificationResult> classify(String message) async {
    final startTime = DateTime.now();

    try {
      final prompt = _buildPrompt(message);
      final response = await _callGeminiAPI(prompt);
      final result = _parseResponse(response);

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      return ClassificationResult(
        intent: result['intent'],
        fields: result['fields'] ?? {},
        confidence: result['confidence'] ?? 1.0,
        tier: 'api',
        responseTimeMs: responseTime,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      // Return null result on error
      return ClassificationResult(
        intent: null,
        fields: {},
        confidence: 0.0,
        tier: 'api_error',
        responseTimeMs: responseTime,
      );
    }
  }

  String _buildPrompt(String message) {
    return '''You are an intent classifier for a hiring platform. Analyze the user's message and:
1. Classify the intent as one of:
   - "JOB_POST": User wants to post a job opening
   - "INTERVIEW": User wants to schedule/conduct an interview
   - "CANDIDATE_SEARCH": User wants to find/search for candidates or view profiles
   - "NONE": If none of the above applies
2. Extract relevant fields (same fields for all intents):
   - title: Job title or position
   - skills: List of required skills/technologies
   - salary: Salary or compensation range
   - location: Work location (city, state, country)
   - workplace_type: remote, hybrid, or onsite

User message: "$message"

Respond ONLY with valid JSON in this exact format:
{
  "intent": "JOB_POST" | "INTERVIEW" | "CANDIDATE_SEARCH" | "NONE",
  "fields": {
    "title": "Software Engineer",
    "skills": ["Python", "React"],
    "salary": "\$100k-120k",
    "location": "New York",
    "workplace_type": "remote"
  },
  "confidence": 0.0 to 1.0
}

Do not include any explanation, only the JSON.''';
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$apiKey');

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 500,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null) {
      throw Exception('Invalid response from Gemini API');
    }

    return text as String;
  }

  Map<String, dynamic> _parseResponse(String response) {
    try {
      // Extract JSON from response (in case there's extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Parse intent
      Intent? intent;
      final intentStr = data['intent'] as String?;
      if (intentStr == 'JOB_POST') {
        intent = Intent.jobPost;
      } else if (intentStr == 'INTERVIEW') {
        intent = Intent.interview;
      } else if (intentStr == 'CANDIDATE_SEARCH') {
        intent = Intent.candidateSearch;
      }

      // Parse fields
      final fields = (data['fields'] as Map<String, dynamic>?) ?? {};

      // Parse confidence
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 1.0;

      return {
        'intent': intent,
        'fields': fields,
        'confidence': confidence,
      };
    } catch (e) {
      throw Exception('Failed to parse Gemini response: $e');
    }
  }
}
