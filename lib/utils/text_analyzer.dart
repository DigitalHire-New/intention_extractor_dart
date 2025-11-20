/// Text analysis utilities
class TextAnalyzer {
  /// Normalize text for processing
  static String normalize(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Extract potential job titles from text
  static String? extractJobTitle(String text) {
    final normalized = normalize(text);

    // Special case: If text starts with seniority level + title words, capture everything until preposition
    // e.g., "senior hiring manager", "vice president of marketing"
    final seniorityPattern = RegExp(
      r'^((?:senior|junior|lead|principal|associate|assistant|chief|head|vice|deputy|sr|jr)\s+(?:[a-z]+\s+)*(?:manager|engineer|developer|designer|analyst|director|consultant|coordinator|architect|specialist|scientist|representative|administrator|president|recruiter|technologist|auditor|partner|tech)(?:\s+(?:iv|iii|ii|i|4|3|2|1))?)',
      caseSensitive: false,
    );
    final seniorityMatch = seniorityPattern.firstMatch(normalized);
    if (seniorityMatch != null) {
      final title = seniorityMatch.group(1);
      if (title != null && title.isNotEmpty) {
        return _capitalizeTitle(title.trim());
      }
    }

    // Special case: "[specialty] [role]" at start of text
    // e.g., "engineering manager", "technical recruiter", "front end developer"
    final specialtyPattern = RegExp(
      r'^((?:mortgage|real estate|insurance|healthcare|engineering|marketing|sales|product|project|operations|finance|human resources|hr|account|customer|data|software|quality|technical|business|financial|program|category|system|network|backend|frontend|front end|clinical|rehab|integration|support services|business development|product marketing|category marketing|digital marketing|content marketing|social media|community|regional|district|territory|field|corporate|retail|store|pediatric|interventional|radiology|application|service desk|sales operations|compliance)\s+(?:[a-z]+\s+)?(?:manager|engineer|director|lead|head|coordinator|analyst|developer|designer|consultant|architect|specialist|scientist|representative|administrator|liaison|worker|associate|nurse|agent|recruiter|technologist|auditor|partner|tech)(?:\s+(?:iv|iii|ii|i|4|3|2|1))?)',
      caseSensitive: false,
    );
    final specialtyMatch = specialtyPattern.firstMatch(normalized);
    if (specialtyMatch != null) {
      final title = specialtyMatch.group(1);
      if (title != null && title.isNotEmpty) {
        return _capitalizeTitle(title.trim());
      }
    }

    // Common patterns for job titles
    final patterns = [
      // "Programmer Analyst 1", "Software Engineer III" - title with level number
      RegExp(r'^((?:programmer|software|backend|frontend|full stack|network|system|data|business)\s+(?:analyst|engineer|developer|administrator|architect|scientist)\s+(?:iv|iii|ii|i|\d))(?:\s|$)', caseSensitive: false),

      // "entry level [title] jobs", "senior [title] jobs"
      RegExp(r'(?:entry level|entry-level|senior|junior|lead|mid level|mid-level)?\s*([a-z\s]+?)\s+jobs?\s*(?:-|in|at|with|$)', caseSensitive: false),

      // "post job for [title]", "post a job for [title]"
      RegExp(r'post\s+(?:a\s+)?job\s+for\s+([a-z\s]+?)(?:\s+(?:with|in|at|who|salary|experience)|\s*$)', caseSensitive: false),

      // "for [title]" at the end or before prepositions
      RegExp(r'\bfor\s+(?:a\s+)?([a-z\s]+?developer|[a-z\s]+?engineer|[a-z\s]+?manager|[a-z\s]+?designer|[a-z\s]+?analyst)', caseSensitive: false),

      // "hire/looking for/need/want [title]"
      RegExp(r'(?:need|looking for|hire|hiring|find|want|wanted)\s+(?:an?\s+)?([a-z\s]+?)(?:\s+(?:for|with|in|at|who)|\s*$)', caseSensitive: false),

      // "position/role/job: [title]"
      RegExp(r'(?:position|role|job):\s*([a-z\s]+?)(?:\s+(?:for|with|in|at)|\s*$)', caseSensitive: false),

      // "[title] manager/developer/etc" - Greedy to capture full title including modifiers
      // This should match "senior hiring manager", capturing "senior hiring" in group 1
      RegExp(r'([a-z\s]+)\s+(?:manager|developer|engineer|designer|analyst|consultant|architect|director|coordinator)(?:\s|$)', caseSensitive: false),

      // Standalone professions and abbreviations
      RegExp(r'\b(?:an?\s+)?(accountant|lawyer|attorney|doctor|nurse|teacher|professor|chef|driver|pilot|scientist|pharmacist|therapist|mechanic|electrician|plumber|technician|recruiter|technologist|auditor|rn)\b', caseSensitive: false),

      // "[specialty/medical] [specialty role]" - e.g., "RN Pediatric Residency Clinic", "Interventional Radiology Technologist"
      RegExp(r'^((?:rn|lpn|cna|emt|paramedic)\s+[a-z\s]+?)(?:\s+(?:in|at|for|with)|$)', caseSensitive: false),
      RegExp(r'^([a-z\s]+?\s+(?:technologist|technician|tech))(?:\s+(?:in|at|for|with|role|-)|$)', caseSensitive: false),
    ];

    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Get the captured title
        final title = (match.groupCount > 0 ? match.group(1)?.trim() : null);

        if (title != null && title.isNotEmpty && title.split(' ').length <= 5) {
          // Filter out common non-title words
          final filtered = _filterNonTitleWords(title);
          if (filtered.isNotEmpty) {
            return _capitalizeTitle(filtered);
          }
        }
      }
    }

    return null;
  }

  static String _filterNonTitleWords(String title) {
    final words = title.toLowerCase().split(' ');
    // Note: "hiring" is NOT in this list because it can be part of job titles like "Hiring Manager"
    final nonTitleWords = ['post', 'job', 'a', 'an', 'the', 'for', 'with', 'in', 'at', 'to', 'need', 'find'];

    final filtered = words.where((word) => !nonTitleWords.contains(word)).join(' ');
    return filtered.trim();
  }

  /// Extract location from text
  static String? extractLocation(String text) {
    // Location patterns
    final patterns = [
      RegExp(r'(?:in|at|from|location:?)\s+([a-z\s,]+?)(?:\s+(?:with|for|who)|\s*$)', caseSensitive: false),
      RegExp(r'\b(remote|onsite|hybrid|on-site)\b', caseSensitive: false),
      RegExp(r'\b([a-z]+(?:\s+[a-z]+)?),\s*([a-z]{2,})\b', caseSensitive: false), // City, State/Country
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final location = match.group(0)?.trim();
        if (location != null && location.isNotEmpty) {
          return _capitalizeTitle(location.replaceFirst(RegExp(r'^(?:in|at|from|location:?)\s+', caseSensitive: false), ''));
        }
      }
    }

    return null;
  }

  /// Extract experience requirements
  static String? extractExperience(String text) {
    final patterns = [
      RegExp(r'(\d+)[\s-]+(?:to|-)[\s-]+(\d+)\s+years?', caseSensitive: false),
      RegExp(r'(\d+)\+?\s+years?', caseSensitive: false),
      RegExp(r'(fresher|entry[- ]level|junior|mid[- ]level|senior|lead|principal)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }

    return null;
  }

  /// Extract compensation/salary information
  static String? extractCompensation(String text) {
    final patterns = [
      RegExp(r'\$[\d,]+k?\s*-?\s*\$?[\d,]*k?(?:\s*(?:per|/)\s*(?:year|month|hour))?', caseSensitive: false),
      RegExp(r'(?:salary|compensation|pay):\s*\$?[\d,]+k?', caseSensitive: false),
      RegExp(r'[\d,]+\s*(?:lpa|lac|lakh)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.trim();
      }
    }

    return null;
  }

  /// Extract skills from text
  static List<String> extractSkills(String text) {
    final normalized = normalize(text);
    final skills = <String>[];

    // Common tech skills database (simplified)
    final knownSkills = [
      'python', 'java', 'javascript', 'typescript', 'dart', 'flutter',
      'react', 'angular', 'vue', 'node', 'nodejs', 'express',
      'django', 'flask', 'spring', 'fastapi',
      'sql', 'mongodb', 'postgresql', 'mysql', 'redis',
      'aws', 'azure', 'gcp', 'docker', 'kubernetes',
      'git', 'ci/cd', 'jenkins', 'terraform',
      'rest', 'graphql', 'api', 'microservices',
      'html', 'css', 'sass', 'tailwind',
      'figma', 'sketch', 'photoshop',
      'agile', 'scrum', 'jira',
    ];

    for (var skill in knownSkills) {
      if (normalized.contains(skill)) {
        skills.add(_capitalizeTitle(skill));
      }
    }

    // Extract skills from "skills:" section
    final skillsPattern = RegExp(r'skills?:\s*([a-z,\s/]+?)(?:\.|$)', caseSensitive: false);
    final match = skillsPattern.firstMatch(text);
    if (match != null) {
      final skillsText = match.group(1);
      if (skillsText != null) {
        final extractedSkills = skillsText.split(RegExp(r'[,/]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length > 1)
            .map((s) => _capitalizeTitle(s));
        skills.addAll(extractedSkills);
      }
    }

    return skills.toSet().toList(); // Remove duplicates
  }

  static String _capitalizeTitle(String text) {
    return text.split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          // Handle Roman numerals - uppercase them completely
          if (RegExp(r'^[ivx]+$', caseSensitive: false).hasMatch(word)) {
            return word.toUpperCase();
          }
          // Regular capitalization
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
