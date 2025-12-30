import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intent_classifier/intent_classifier.dart';

/// Example Flutter integration showing how to use IntentClassifier
/// in a real application with debouncing and state management
class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({Key? key}) : super(key: key);

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  // Initialize the classifier with your API key
  final classifier = IntentClassifier(
    apiKey: "YOUR_OPENAI_API_KEY",
    model: 'gpt-4o-mini', // Cost-effective and fast
  );

  // Debounce timer to avoid excessive API calls
  Timer? debounceTimer;

  // Track user intent
  UserIntent _tempIntent = UserIntent.searchJob;

  // Track which fields are detected
  Map<String, bool> selectedJobPostChip = {
    'title': false,
    'location': false,
    'experience': false,
    'skills': false,
    'salary': false,
    'industry': false,
  };

  // Map of intent strings to UserIntent enum
  final Map<String, UserIntent> intentMap = {
    'search_job': UserIntent.searchJob,
    'find_similar': UserIntent.findSimilar,
    'job_description': UserIntent.jobDescription,
    'boolean': UserIntent.boolean,
    'select_manually': UserIntent.selectManually,
  };

  Future<void> filterIntent(String text) async {
    // Cancel previous timer
    debounceTimer?.cancel();

    // Set new timer for 300ms debounce
    debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await classifier.classify(text);
        print("Classifier Intent: ${res.intent} | Fields: ${res.fields}");

        if (res.intent == null) {
          _tempIntent = UserIntent.searchJob;
          // Reset all chips
          selectedJobPostChip.updateAll((key, value) => false);
        } else {
          _tempIntent = res.intent!;

          // Update chips based on detected fields
          selectedJobPostChip['title'] = res.fields.containsKey('title');
          selectedJobPostChip['location'] = res.fields.containsKey('location');
          selectedJobPostChip['experience'] =
              res.fields.containsKey('experience');
          selectedJobPostChip['skills'] = res.fields.containsKey('skills');
          selectedJobPostChip['salary'] = res.fields.containsKey('salary');
          selectedJobPostChip['industry'] = res.fields.containsKey('industry');
        }

        setState(() {});
      } catch (e) {
        print('Classification error: $e');
        // Handle error gracefully
      }
    });
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search input field
            TextField(
              onChanged: filterIntent,
              decoration: const InputDecoration(
                hintText: 'Who are you looking for?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Display detected field chips
            Wrap(
              spacing: 8,
              children: [
                if (selectedJobPostChip['title']!)
                  const Chip(label: Text('Job Title')),
                if (selectedJobPostChip['location']!)
                  const Chip(label: Text('Location')),
                if (selectedJobPostChip['experience']!)
                  const Chip(label: Text('Years of Experience')),
                if (selectedJobPostChip['skills']!)
                  const Chip(label: Text('Skills')),
                if (selectedJobPostChip['salary']!)
                  const Chip(label: Text('Salary')),
                if (selectedJobPostChip['industry']!)
                  const Chip(label: Text('Industry')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
