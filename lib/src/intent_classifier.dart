import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Main class for classifying user intent in job search queries
class IntentClassifier {
  final String apiKey;
  final String model;
  final String baseUrl;

  /// Creates an IntentClassifier instance
  ///
  /// [apiKey] - Your OpenAI API key
  /// [model] - The GPT model to use (default: gpt-4o-mini for cost-effectiveness)
  /// [baseUrl] - OpenAI API base URL (default: https://api.openai.com/v1)
  IntentClassifier({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.baseUrl = 'https://api.openai.com/v1',
  });

  /// Classifies the given text to extract intent and job search fields
  ///
  /// Returns a [ClassificationResult] containing:
  /// - intent: The detected user intent
  /// - fields: Extracted fields (title, location, experience, skills, salary, industry)
  Future<ClassificationResult> classify(String text) async {
    if (text.trim().isEmpty) {
      return ClassificationResult(
        intent: UserIntent.createJobPost,
        fields: {},
        confidence: 0.0,
      );
    }

    try {
      final response = await _callOpenAI(text);
      return _parseResponse(response);
    } catch (e) {
      // Return a default result on error
      return ClassificationResult(
        intent: UserIntent.createJobPost,
        fields: {},
        confidence: 0.0,
        rawResponse: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _callOpenAI(String text) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    const systemPrompt = '''You are an expert at extracting structured information from job posting descriptions. Analyze the user's query and extract relevant fields.

Your task:
Extract relevant fields from the query:
- title: Job title or role (e.g., "Python Developer", "Senior Software Engineer")
- location: Location mentioned (e.g., "New York", "San Francisco", "remote")
- experience: Years of experience (extract number, e.g., "10", "5")
- skills: Technical or professional skills (e.g., ["Python", "Django", "AWS"])
- salary: Salary information if mentioned (e.g., "100k", "150000")
- industry: Industry or domain (e.g., "fintech", "healthcare", "e-commerce")

Return ONLY a JSON object with this exact structure:
{
  "fields": {
    "title": "value",
    "location": "value",
    "experience": "value",
    "skills": ["skill1", "skill2"],
    "salary": "value",
    "industry": "value"
  },
  "confidence": 0.95
}

Rules:
- Only include fields that are explicitly mentioned or clearly implied
- For skills, always use an array even if single skill
- For experience, extract just the number
- Omit fields that are not mentioned in the query
- confidence should be 0.0 to 1.0 based on how clear the information is''';

    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    return jsonDecode(content);
  }

  ClassificationResult _parseResponse(Map<String, dynamic> response) {
    try {
      // Intent is always createJobPost
      const intent = UserIntent.createJobPost;

      // Parse fields
      final fields = <String, dynamic>{};
      final rawFields = response['fields'] as Map<String, dynamic>?;

      if (rawFields != null) {
        // Extract and normalize each field
        if (rawFields['title'] != null) {
          fields['title'] = rawFields['title'].toString();
        }
        if (rawFields['location'] != null) {
          fields['location'] = rawFields['location'].toString();
        }
        if (rawFields['experience'] != null) {
          fields['experience'] = rawFields['experience'].toString();
        }
        if (rawFields['skills'] != null) {
          if (rawFields['skills'] is List) {
            fields['skills'] = List<String>.from(
              (rawFields['skills'] as List).map((e) => e.toString()),
            );
          } else {
            fields['skills'] = [rawFields['skills'].toString()];
          }
        }
        if (rawFields['salary'] != null) {
          fields['salary'] = rawFields['salary'].toString();
        }
        if (rawFields['industry'] != null) {
          fields['industry'] = rawFields['industry'].toString();
        }
      }

      final confidence = (response['confidence'] ?? 1.0).toDouble();

      return ClassificationResult(
        intent: intent,
        fields: fields,
        confidence: confidence,
        rawResponse: jsonEncode(response),
      );
    } catch (e) {
      return ClassificationResult(
        intent: UserIntent.createJobPost,
        fields: {},
        confidence: 0.0,
        rawResponse: 'Parse error: $e',
      );
    }
  }
}
