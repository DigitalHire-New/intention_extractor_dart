import '../models/intent.dart';
import '../models/classification_result.dart';
import '../utils/text_analyzer.dart';

/// Fast rule-based classifier (Tier 1)
/// Response time: <10ms
class RuleBasedClassifier {
  static const double _confidenceThreshold = 0.5;

  /// Classify intent using rule-based approach
  ClassificationResult classify(String message) {
    final startTime = DateTime.now();
    final normalized = TextAnalyzer.normalize(message);

    // Calculate scores for each intent
    final jobPostScore = _calculateJobPostScore(normalized);
    final interviewScore = _calculateInterviewScore(normalized);

    Intent? intent;
    double confidence = 0.0;

    // Determine intent based on scores
    if (jobPostScore > interviewScore && jobPostScore >= _confidenceThreshold) {
      intent = Intent.jobPost;
      confidence = jobPostScore;
    } else if (interviewScore > jobPostScore && interviewScore >= _confidenceThreshold) {
      intent = Intent.interview;
      confidence = interviewScore;
    }

    // Extract fields
    final fields = _extractFields(message, intent);

    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;

    return ClassificationResult(
      intent: intent,
      fields: fields,
      confidence: confidence,
      tier: 'rules',
      responseTimeMs: responseTime,
    );
  }

  double _calculateJobPostScore(String text) {
    double score = 0.0;

    // Primary action words for job posting (45% each)
    final primaryActions = ['hire', 'hiring', 'recruit', 'recruiting'];
    for (var action in primaryActions) {
      if (text.contains(action)) {
        score += 0.45;
        break;
      }
    }

    // Secondary action words (40% each)
    final secondaryActions = ['post', 'posting', 'looking for', 'seeking', 'want', 'wanted', 'need', 'needed'];
    if (score < 0.45) { // Only check if no primary action found
      for (var action in secondaryActions) {
        if (text.contains(action)) {
          score += 0.40;
          break;
        }
      }
    }

    // "find" (25%)
    if (text.contains('find')) {
      score += 0.25;
    }

    // Target words (30% each)
    final targetWords = ['candidate', 'candidates', 'applicant', 'applicants', 'talent'];
    for (var word in targetWords) {
      if (text.contains(word)) {
        score += 0.30;
        break;
      }
    }

    // Job-related terms (25%)
    final jobTerms = ['job', 'jobs', 'position', 'role', 'opening', 'opportunity', 'vacancy'];
    for (var term in jobTerms) {
      if (text.contains(term)) {
        score += 0.25;
        break;
      }
    }

    // "[title] jobs" pattern is a strong indicator (35%)
    // e.g., "customer service jobs", "software engineer jobs"
    if (text.contains('jobs') || text.contains('job ')) {
      // Check if there's a job-related word before "jobs/job"
      final jobPatternWords = [
        'service', 'support', 'sales', 'marketing', 'customer',
        'software', 'data', 'business', 'financial', 'technical',
        'engineering', 'entry level', 'senior', 'junior', 'lead'
      ];
      for (var word in jobPatternWords) {
        if (text.contains(word)) {
          score += 0.35;
          break;
        }
      }
    }

    // Job titles/skills indicate posting (20%)
    if (_containsJobTitle(text) || _containsSkills(text)) {
      score += 0.20;
    }

    // Professional job titles alone without action words (40%)
    // e.g., "Technical Recruiter", "RN Pediatric", "Interventional Radiology Technologist"
    final professionalTitles = [
      'recruiter', 'technologist', 'technician', 'auditor', 'business partner',
      'vice president', 'engineer', 'developer', 'analyst', 'manager', 'director',
      'coordinator', 'specialist', 'representative', 'consultant', 'refrigeration'
    ];

    // Check with word boundaries for RN, LPN, CNA, VP, Tech
    final abbreviationTitles = RegExp(r'\b(rn|lpn|cna|vp|emt|cma|tech)\b', caseSensitive: false);

    if (abbreviationTitles.hasMatch(text)) {
      score += 0.40;
    } else {
      for (var title in professionalTitles) {
        if (text.contains(title)) {
          score += 0.40;
          break;
        }
      }
    }

    // Strong indicator: Job title + location pattern (40%)
    // "engineering manager in chicago" should be detected as job post
    if (_containsJobTitle(text) && _containsLocation(text)) {
      score += 0.40;
    }

    // Negative indicators (reduce score if interview-related)
    final interviewTerms = ['interview', 'meeting'];
    for (var term in interviewTerms) {
      if (text.contains(term)) {
        score -= 0.30;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateInterviewScore(String text) {
    double score = 0.0;

    // "interview" keyword is strongest signal (35%)
    if (text.contains('interview') || text.contains('interviewing')) {
      score += 0.35;
    }

    // Scheduling actions (30%)
    final schedulingActions = ['schedule', 'scheduling', 'arrange', 'set up', 'setup', 'book'];
    for (var action in schedulingActions) {
      if (text.contains(action)) {
        score += 0.30;
        break;
      }
    }

    // Conducting/meeting actions (30%)
    final conductActions = ['conduct', 'meeting', 'call', 'round', 'session', 'discussion'];
    for (var action in conductActions) {
      if (text.contains(action)) {
        score += 0.30;
        break;
      }
    }

    // Candidate mention in interview context (25%)
    if (text.contains('candidate') || text.contains('applicant')) {
      if (text.contains('with') || text.contains('for')) {
        score += 0.25;
      }
    }

    // Time/date indicators (15%)
    final timeIndicators = [
      'today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday',
      'am', 'pm', 'oclock', 'time', 'date', 'next'
    ];
    for (var indicator in timeIndicators) {
      if (text.contains(indicator)) {
        score += 0.15;
        break;
      }
    }

    // Negative indicators (reduce score if job posting-related)
    final jobPostTerms = ['hire', 'hiring', 'recruit', 'find candidates', 'looking for'];
    for (var term in jobPostTerms) {
      if (text.contains(term)) {
        score -= 0.30;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  bool _containsJobTitle(String text) {
    final jobTitles = [
      // Tech & Engineering
      'developer', 'engineer', 'programmer', 'architect', 'technician', 'tech',
      'network administrator', 'software engineer', 'backend engineer',
      'system design', 'integration engineer', 'technologist',

      // Business & Management
      'manager', 'director', 'executive', 'coordinator', 'supervisor',
      'administrator', 'lead', 'principal', 'account manager',
      'program manager', 'business development', 'liaison',
      'vice president', 'vp', 'business partner',

      // Analysis & Data
      'analyst', 'data scientist', 'programmer analyst',

      // Design & Creative
      'designer', 'writer', 'editor',

      // Sales & Marketing
      'sales', 'marketer', 'marketing', 'sales executive',
      'business development representative', 'specialist',
      'product marketing', 'category marketing',

      // Professional Services
      'consultant', 'accountant', 'lawyer', 'attorney',
      'tax preparer', 'auditor', 'audit', 'recruiter',

      // Healthcare
      'doctor', 'nurse', 'therapist', 'pharmacist',
      'registered nurse', 'nurse coordinator', 'sanitarian',
      'rn', 'lpn', 'cna', 'emt', 'paramedic', 'radiology',

      // Education
      'teacher', 'professor', 'instructor', 'trainer',

      // Service & Support
      'customer service', 'customer support', 'support services',
      'representative', 'agent', 'operator', 'chat support',

      // Retail & Operations
      'cashier', 'retail', 'sales associate', 'merchandise associate',
      'warehouse worker', 'warehouse', 'maintenance',

      // Levels & Seniority
      'senior', 'junior', 'intern', 'associate', 'entry level',
      'entry-level', 'mid level', 'principal', 'lead',

      // Other
      'receptionist', 'clerk', 'assistant', 'secretary',
      'mechanic', 'electrician', 'plumber',
      'chef', 'cook', 'driver', 'pilot',
      'scientist', 'researcher'
    ];
    return jobTitles.any((title) => text.contains(title));
  }

  bool _containsSkills(String text) {
    final skills = [
      'python', 'java', 'javascript', 'react', 'node',
      'flutter', 'dart', 'sql', 'aws', 'docker'
    ];
    return skills.any((skill) => text.contains(skill));
  }

  bool _containsLocation(String text) {
    // Check for common location indicators
    final locationPatterns = [
      'in ', 'at ', 'from ', 'location',
      'remote', 'onsite', 'hybrid', 'on-site', 'work from home', 'wfh',

      // US States (all 50)
      'alabama', 'alaska', 'arizona', 'arkansas', 'california', 'colorado',
      'connecticut', 'delaware', 'florida', 'georgia', 'hawaii', 'idaho',
      'illinois', 'indiana', 'iowa', 'kansas', 'kentucky', 'louisiana',
      'maine', 'maryland', 'massachusetts', 'michigan', 'minnesota',
      'mississippi', 'missouri', 'montana', 'nebraska', 'nevada',
      'new hampshire', 'new jersey', 'new mexico', 'new york', 'north carolina',
      'north dakota', 'ohio', 'oklahoma', 'oregon', 'pennsylvania',
      'rhode island', 'south carolina', 'south dakota', 'tennessee', 'texas',
      'utah', 'vermont', 'virginia', 'washington', 'west virginia',
      'wisconsin', 'wyoming',

      // Major US Cities
      'new york city', 'nyc', 'los angeles', 'chicago', 'houston', 'phoenix',
      'philadelphia', 'san antonio', 'san diego', 'dallas', 'san jose',
      'austin', 'jacksonville', 'fort worth', 'columbus', 'charlotte',
      'san francisco', 'indianapolis', 'seattle', 'denver', 'boston',
      'nashville', 'detroit', 'portland', 'las vegas', 'memphis',
      'louisville', 'baltimore', 'milwaukee', 'albuquerque', 'tucson',
      'fresno', 'sacramento', 'kansas city', 'atlanta', 'miami',
      'oakland', 'tulsa', 'cleveland', 'new orleans', 'tampa',
      'raleigh', 'minneapolis', 'omaha', 'long beach', 'virginia beach',

      // State abbreviations
      'al', 'ak', 'az', 'ar', 'ca', 'co', 'ct', 'de', 'fl', 'ga',
      'hi', 'id', 'il', 'in', 'ia', 'ks', 'ky', 'la', 'me', 'md',
      'ma', 'mi', 'mn', 'ms', 'mo', 'mt', 'ne', 'nv', 'nh', 'nj',
      'nm', 'ny', 'nc', 'nd', 'oh', 'ok', 'or', 'pa', 'ri', 'sc',
      'sd', 'tn', 'tx', 'ut', 'vt', 'va', 'wa', 'wv', 'wi', 'wy',
    ];
    return locationPatterns.any((loc) => text.contains(loc));
  }

  Map<String, dynamic> _extractFields(String message, Intent? intent) {
    final fields = <String, dynamic>{};

    // Only extract fields if we have a clear intent
    if (intent == null) {
      return fields;
    }

    // Extract based on intent
    if (intent == Intent.jobPost) {
      final jobTitle = TextAnalyzer.extractJobTitle(message);
      if (jobTitle != null) fields['JOB_TITLE'] = jobTitle;

      final location = TextAnalyzer.extractLocation(message);
      if (location != null) fields['LOCATION'] = location;

      final experience = TextAnalyzer.extractExperience(message);
      if (experience != null) fields['EXPERIENCE'] = experience;

      final compensation = TextAnalyzer.extractCompensation(message);
      if (compensation != null) fields['COMPENSATION'] = compensation;

      final skills = TextAnalyzer.extractSkills(message);
      if (skills.isNotEmpty) fields['SKILLS'] = skills;
    }
    // For interview, we might extract different fields (candidate name, time, etc.)
    // For now, keeping it simple

    return fields;
  }
}
