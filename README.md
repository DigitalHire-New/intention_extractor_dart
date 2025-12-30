# Intent Classifier

A powerful Dart package for extracting structured job posting information using OpenAI GPT. Automatically extracts fields (title, location, experience, skills, salary, industry) from natural language job posting descriptions.

## Features

- **Accurate NLP Field Extraction**: Uses GPT-4 for highly accurate field detection
- **Comprehensive Field Detection**: Automatically extracts job title, location, experience, skills, salary, and industry
- **Industry Agnostic**: Works with any industry, skill set, title, location, or experience level
- **Simple API**: Easy-to-use interface with async/await support
- **Type Safe**: Full Dart type safety with enums and models
- **Flutter Ready**: Perfect for Flutter applications with debouncing examples
- **Always CreateJobPost Intent**: Focused on job posting creation with consistent intent

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  intent_classifier: ^1.0.0
```

Or install it from a local path:

```yaml
dependencies:
  intent_classifier:
    path: ../intent_classifier
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Usage

```dart
import 'package:intent_classifier/intent_classifier.dart';

void main() async {
  // Initialize with your OpenAI API key
  final classifier = IntentClassifier(
    apiKey: 'YOUR_OPENAI_API_KEY',
  );

  // Classify a query
  final result = await classifier.classify(
    'need python developer in new york with 10 years of experience and should be experienced with fintech',
  );

  print('Intent: ${result.intent}'); // UserIntent.searchJob
  print('Fields: ${result.fields}');
  // Fields: {
  //   title: 'python developer',
  //   location: 'new york',
  //   experience: '10',
  //   industry: 'fintech'
  // }
}
```

### Flutter Integration with Debouncing

```dart
import 'dart:async';
import 'package:intent_classifier/intent_classifier.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final classifier = IntentClassifier(apiKey: "YOUR_API_KEY");
  Timer? debounceTimer;
  UserIntent _tempIntent = UserIntent.searchJob;
  Map<String, bool> selectedJobPostChip = {
    'title': false,
    'location': false,
    'experience': false,
    'skills': false,
    'salary': false,
    'industry': false,
  };

  Future<void> filterIntent(String text) async {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final res = await classifier.classify(text);
      print("Intent: ${res.intent} | Fields: ${res.fields}");

      if (res.intent == null) {
        _tempIntent = UserIntent.searchJob;
        selectedJobPostChip.updateAll((key, value) => false);
      } else {
        _tempIntent = res.intent!;
        selectedJobPostChip['title'] = res.fields.containsKey('title');
        selectedJobPostChip['location'] = res.fields.containsKey('location');
        selectedJobPostChip['experience'] = res.fields.containsKey('experience');
        selectedJobPostChip['skills'] = res.fields.containsKey('skills');
        selectedJobPostChip['salary'] = res.fields.containsKey('salary');
        selectedJobPostChip['industry'] = res.fields.containsKey('industry');
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: filterIntent,
      decoration: InputDecoration(hintText: 'Who are you looking for?'),
    );
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }
}
```

## API Reference

### IntentClassifier

Main class for classifying user intent.

#### Constructor

```dart
IntentClassifier({
  required String apiKey,
  String model = 'gpt-4o-mini',
  String baseUrl = 'https://api.openai.com/v1',
})
```

Parameters:
- `apiKey` (required): Your OpenAI API key
- `model`: The GPT model to use (default: `gpt-4o-mini` for cost-effectiveness)
- `baseUrl`: OpenAI API base URL (default: `https://api.openai.com/v1`)

#### Methods

##### classify(String text)

Classifies the given text to extract intent and job search fields.

```dart
Future<ClassificationResult> classify(String text)
```

Returns a `ClassificationResult` containing:
- `intent`: The detected user intent
- `fields`: Extracted fields as a Map
- `confidence`: Confidence score (0.0 to 1.0)

### ClassificationResult

Result model returned by the classifier.

Properties:
- `UserIntent? intent`: The detected user intent
- `Map<String, dynamic> fields`: Extracted fields with their values
- `double confidence`: Confidence score (0.0 to 1.0)
- `String? rawResponse`: Raw API response for debugging

### UserIntent

Enum representing possible user intents:

- `UserIntent.searchJob`: User is searching for a job
- `UserIntent.findSimilar`: User wants to find similar jobs
- `UserIntent.jobDescription`: User is looking at job descriptions
- `UserIntent.boolean`: User is using boolean search
- `UserIntent.selectManually`: User wants to manually select criteria
- `UserIntent.unknown`: Intent could not be determined

### Extracted Fields

The `fields` map can contain:

- `title` (String): Job title or role
- `location` (String): Location mentioned
- `experience` (String): Years of experience (as number string)
- `skills` (List<String>): Technical or professional skills
- `salary` (String): Salary information
- `industry` (String): Industry or domain

## Examples

### Example 1: Complex Query

```dart
final result = await classifier.classify(
  'need python developer in new york with 10 years of experience and should be experienced with fintech',
);
// Intent: UserIntent.searchJob
// Fields: {
//   title: 'python developer',
//   location: 'new york',
//   experience: '10',
//   industry: 'fintech'
// }
```

### Example 2: Skills and Salary

```dart
final result = await classifier.classify(
  'DevOps engineer with 5 years experience, salary 150k, remote',
);
// Intent: UserIntent.searchJob
// Fields: {
//   title: 'DevOps engineer',
//   experience: '5',
//   salary: '150k',
//   location: 'remote'
// }
```

### Example 3: Multiple Skills

```dart
final result = await classifier.classify(
  'looking for java backend engineer in San Francisco with Spring Boot and AWS experience',
);
// Intent: UserIntent.searchJob
// Fields: {
//   title: 'java backend engineer',
//   location: 'San Francisco',
//   skills: ['Java', 'Spring Boot', 'AWS']
// }
```

## Cost Optimization

By default, the package uses `gpt-4o-mini` which is cost-effective and fast. For even better accuracy, you can use `gpt-4o`:

```dart
final classifier = IntentClassifier(
  apiKey: 'YOUR_API_KEY',
  model: 'gpt-4o', // More accurate but higher cost
);
```

## Getting Your OpenAI API Key

1. Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy your API key and keep it secure

**Important**: Never commit your API key to version control. Use environment variables or secure configuration management.

## Error Handling

The classifier returns a safe default result when errors occur:

```dart
try {
  final result = await classifier.classify(text);
  // Use result
} catch (e) {
  print('Classification error: $e');
  // Fallback behavior
}
```

## Performance Tips

1. **Use Debouncing**: Implement debouncing to avoid excessive API calls on every keystroke
2. **Cache Results**: Cache recent classifications to reduce API costs
3. **Use gpt-4o-mini**: Unless you need maximum accuracy, use `gpt-4o-mini` for better cost/performance
4. **Batch Requests**: If processing multiple queries, consider batching them

## License

MIT License - See LICENSE file for details

## Support

For issues, feature requests, or questions, please file an issue on GitHub.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
