import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intent.dart';
import '../models/classification_result.dart';

/// OpenAI GPT-3.5-turbo service for intent classification
class OpenAIService {
  final String apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const int _timeoutMs = 5000; // 5 second timeout
  static const int _maxConcurrentRequests = 3; // Keep last 3 requests open

  // Track active requests to manage concurrency
  final List<http.Client> _activeClients = [];

  OpenAIService(this.apiKey);

  Future<ClassificationResult> classify(String message) async {
    final startTime = DateTime.now();

    // Create new client for this request
    final client = http.Client();
    _activeClients.add(client);

    // Cancel oldest requests if we exceed the limit
    while (_activeClients.length > _maxConcurrentRequests) {
      final oldestClient = _activeClients.removeAt(0);
      oldestClient.close();
    }

    try {
      final response = await client.post(
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
              'content': 'You are an intent classifier for a hiring platform. Classify the user message into JOB_POST (hiring/recruiting), INTERVIEW (scheduling interviews), or CANDIDATE_SEARCH (finding candidates). Extract fields: title (job position), skills (array), salary, location, workplace_type (Remote/Hybrid/Onsite), experience. Return JSON: {"intent":"JOB_POST|INTERVIEW|CANDIDATE_SEARCH","confidence":0.0-1.0,"fields":{"title":"value or null","skills":["skill1"],"salary":"value or null","location":"value or null","workplace_type":"value or null","experience":"value or null"}}'
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
      // API failed, timed out, or was cancelled
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      // Check if request was cancelled
      final tier = e.toString().contains('ClientException') ? 'cancelled' : 'failed';

      return ClassificationResult(
        intent: null,
        fields: {},
        confidence: 0.0,
        tier: tier,
        responseTimeMs: responseTime,
      );
    } finally {
      // Clean up this client after request completes
      _activeClients.remove(client);
      client.close();
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

  /// Dispose resources - close all active clients
  void dispose() {
    for (var client in _activeClients) {
      client.close();
    }
    _activeClients.clear();
  }
}
