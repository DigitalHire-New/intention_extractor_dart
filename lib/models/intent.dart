/// User intent types
enum Intent {
  jobPost,
  interview,
}

extension IntentExtension on Intent {
  String get value {
    switch (this) {
      case Intent.jobPost:
        return 'JOB_POST';
      case Intent.interview:
        return 'INTERVIEW';
    }
  }
}
