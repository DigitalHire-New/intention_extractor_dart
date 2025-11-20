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
    final candidateSearchScore = _calculateCandidateSearchScore(normalized);

    Intent? intent;
    double confidence = 0.0;

    // Determine intent based on highest score
    final maxScore = [jobPostScore, interviewScore, candidateSearchScore].reduce((a, b) => a > b ? a : b);

    if (maxScore >= _confidenceThreshold) {
      if (maxScore == jobPostScore) {
        intent = Intent.jobPost;
        confidence = jobPostScore;
      } else if (maxScore == interviewScore) {
        intent = Intent.interview;
        confidence = interviewScore;
      } else {
        intent = Intent.candidateSearch;
        confidence = candidateSearchScore;
      }
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
    final primaryActions = [
      // Hiring terms
      'hire', 'hiring', 'hired', 'hires', 'hire for',
      'recruit', 'recruiting', 'recruitment', 'recruiter', 'recruited', 'recruits',
      'employ', 'employing', 'employment', 'employed', 'employer',
      'onboard', 'onboarding', 'onboarded',
      'staffing', 'staff for', 'staffed',
      'headhunt', 'headhunting', 'headhunted', 'headhunter',
      // Action phrases
      'bring on', 'bringing on', 'brought on',
      'take on', 'taking on', 'took on',
      'add to team', 'add team member', 'join our team', 'join the team',
      'fill position', 'fill role', 'fill vacancy', 'filling position',
      'expand team', 'expanding team', 'grow team', 'growing team',
      'build team', 'building team', 'team building',
      'acquire talent', 'acquiring talent', 'talent acquisition'
    ];
    for (var action in primaryActions) {
      if (text.contains(action)) {
        score += 0.45;
        break;
      }
    }

    // Secondary action words (40% each)
    // BUT: Don't count if it's part of certain patterns
    final secondaryActions = [
      // Posting terms
      'post', 'posting', 'posted', 'posts', 'post a', 'post for',
      'create', 'creating', 'created', 'create a', 'create job',
      'publish', 'publishing', 'published', 'advertise', 'advertising',
      'list', 'listing', 'listed', 'list a job', 'list position',
      'open', 'opening', 'opened', 'open position', 'open role',
      // Searching terms
      'looking for', 'look for', 'seeking', 'seek', 'sought',
      'search for', 'searching for', 'searched for', 'in search of',
      'on the lookout', 'lookout for', 'scouting', 'scouting for',
      // Need/Want terms
      'want', 'wanted', 'wanting', 'wants', 'would like', 'wanna',
      'need', 'needed', 'needing', 'needs', 'in need of',
      'require', 'required', 'requiring', 'requires', 'requirement',
      'must have', 'must find', 'gotta find', 'got to find',
      'have to hire', 'have to recruit', 'got to hire',
      // Interest terms
      'interested in', 'interest in', 'keen to', 'eager to',
      'hoping to', 'wish to', 'wishing to', 'like to'
    ];
    if (score < 0.45) { // Only check if no primary action found
      for (var action in secondaryActions) {
        if (text.contains(action)) {
          // Skip if "want/need" appears with interview or assessment terms
          if ((action == 'want' || action == 'need') &&
              (text.contains('interview') || text.contains('evaluate') ||
               text.contains('assess') || text.contains('review'))) {
            continue;
          }
          // Skip "looking for" if it's likely a candidate search pattern
          if (action == 'looking for' && !text.contains('hire') && !text.contains('recruit')) {
            // This might be a candidate search, give lower score
            score += 0.25;
            break;
          }
          score += 0.40;
          break;
        }
      }
    }

    // "find" (25%) - but only if not a search pattern like "find me [job title]"
    if (text.contains('find')) {
      // Don't count "find" if it's likely a candidate search
      final isSearchPattern = text.contains('find me') || text.contains('find candidates');
      if (!isSearchPattern) {
        score += 0.25;
      }
    }

    // Target words (30% each) - but skip if assessment context
    final targetWords = [
      // Candidate variations
      'candidate', 'candidates', 'candidacy', 'applicant', 'applicants',
      'talent', 'talents', 'talented', 'professional', 'professionals',
      'resource', 'resources', 'personnel', 'people',
      'employee', 'employees', 'worker', 'workers',
      'team member', 'team members', 'staff', 'staffer', 'staffers',
      'individual', 'individuals', 'person', 'people',
      // Seeker variations
      'job seeker', 'job seekers', 'job hunter', 'job hunters',
      'prospect', 'prospects', 'potential hire', 'potential hires',
      'new hire', 'new hires', 'fresh talent', 'fresh hire',
      // Skill level terms
      'expert', 'experts', 'specialist', 'specialists',
      'skilled worker', 'skilled workers', 'pro', 'pros',
      'contractor', 'contractors', 'freelancer', 'freelancers',
      'consultant', 'consultants', 'temp', 'temps',
      // Collective terms
      'workforce', 'manpower', 'human capital',
      'crew', 'squad', 'pool of talent'
    ];
    // Skip target words if in assessment/evaluation context
    final isAssessmentContext = text.contains('evaluate') || text.contains('assess') ||
                                  text.contains('review') || text.contains('screening');
    if (!isAssessmentContext) {
      for (var word in targetWords) {
        if (text.contains(word)) {
          score += 0.30;
          break;
        }
      }
    }

    // Job-related terms (25%)
    final jobTerms = [
      // Job terms
      'job', 'jobs', 'job opening', 'job position', 'job posting',
      'position', 'positions', 'open position', 'available position',
      'role', 'roles', 'open role', 'available role',
      'opening', 'openings', 'vacancy', 'vacancies', 'vacant position',
      'opportunity', 'opportunities', 'career opportunity', 'work opportunity',
      'posting', 'postings', 'job ad', 'job advertisement',
      'listing', 'listings', 'job listing',
      // Career terms
      'career', 'careers', 'career path', 'career move',
      'employment', 'employment opportunity', 'work', 'work position',
      'gig', 'contract', 'contract work', 'freelance',
      'full time', 'full-time', 'fulltime', 'ft',
      'part time', 'part-time', 'parttime', 'pt',
      'permanent', 'temporary', 'temp', 'contract role',
      // Slot/spot terms
      'slot', 'spot', 'seat', 'place', 'berth'
    ];
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
      // Corporate titles
      'recruiter', 'hiring manager', 'talent manager',
      'technologist', 'technician', 'tech', 'specialist',
      'auditor', 'business partner', 'account executive',
      'vice president', 'vp', 'president', 'ceo', 'cto', 'cfo', 'coo',
      'director', 'head of', 'chief',
      // Engineering/Tech
      'engineer', 'engineering', 'developer', 'dev', 'programmer',
      'architect', 'devops', 'sre', 'qa', 'qe',
      'frontend', 'backend', 'fullstack', 'full stack',
      // Analysis/Data
      'analyst', 'data scientist', 'scientist',
      'researcher', 'research', 'statistician',
      // Management
      'manager', 'mgr', 'lead', 'team lead', 'supervisor',
      'coordinator', 'admin', 'administrator',
      // Sales/Marketing
      'representative', 'rep', 'agent', 'broker',
      'consultant', 'advisor', 'associate',
      'salesperson', 'sales rep', 'account manager',
      // Medical/Healthcare
      'physician', 'practitioner', 'clinician',
      'therapist', 'nurse practitioner',
      // Operations
      'operator', 'handler', 'controller',
      'refrigeration', 'hvac', 'maintenance'
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
    // BUT: Don't add this if it's a search pattern without hiring terms
    final isSearchPattern = (text.contains('looking for') || text.contains('find me') ||
                             text.contains('search for') || text.contains('show me')) &&
                            !text.contains('hire') && !text.contains('recruit') &&
                            !text.contains('to hire') && !text.contains('to recruit');

    if (_containsJobTitle(text) && _containsLocation(text) && !isSearchPattern) {
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

    // Strong negative for candidate search patterns
    final searchPatterns = ['find me', 'show me', 'search for', 'browse', 'filter', 'profiles', 'resumes'];
    for (var pattern in searchPatterns) {
      if (text.contains(pattern)) {
        score -= 0.40;
        break;
      }
    }

    // Strong negative for query/existence patterns
    final queryPatterns = ['is there any', 'are there any', 'is there a', 'are there',
                           'do we have', 'do you have', 'have any', 'got any'];
    for (var pattern in queryPatterns) {
      if (text.contains(pattern)) {
        score -= 0.50;
        break;
      }
    }

    // Negative for "any [title]" at start - likely a query, not a job post
    if (text.startsWith('any ') && _containsJobTitle(text)) {
      score -= 0.60;
    }

    // Negative for interview/assessment actions
    final assessmentTerms = [
      'evaluate', 'evaluating', 'evaluation', 'evaluated',
      'assess', 'assessing', 'assessment', 'assessed',
      'review', 'reviewing', 'reviewed', 'reviews',
      'screen', 'screening', 'screened', 'screens',
      'interview', 'interviewing', 'interviewed',
      'vet', 'vetting', 'vetted',
      'test', 'testing', 'tested',
      'examine', 'examining', 'examined',
      'check out', 'checking', 'check'
    ];
    for (var term in assessmentTerms) {
      if (text.contains(term)) {
        score -= 0.35;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateInterviewScore(String text) {
    double score = 0.0;

    // Strong intent patterns - "want to interview", "need to interview", etc. (60%)
    final strongInterviewPatterns = [
      // Interview patterns
      'want to interview', 'want interview', 'wanna interview', 'wants to interview',
      'need to interview', 'need interview', 'needs to interview', 'gotta interview',
      'going to interview', 'gonna interview', 'will interview', 'would interview',
      'planning to interview', 'plan to interview', 'planning interview',
      'to interview a', 'to interview the', 'to interview some',
      'like to interview', 'would like to interview', 'wish to interview',
      'have to interview', 'got to interview', 'must interview',
      'should interview', 'gonna interview', 'ready to interview',
      // Evaluation patterns
      'want to evaluate', 'want to assess', 'want to review', 'wants to evaluate',
      'need to evaluate', 'need to assess', 'need to review', 'needs to evaluate',
      'going to evaluate', 'going to assess', 'going to review',
      'plan to evaluate', 'plan to assess', 'plan to review',
      'like to evaluate', 'like to assess', 'would like to evaluate',
      'have to evaluate', 'have to assess', 'must evaluate', 'must assess',
      // Screening patterns
      'want to screen', 'need to screen', 'needs to screen',
      'going to screen', 'plan to screen', 'planning to screen',
      'like to screen', 'have to screen', 'must screen',
      // Testing patterns
      'want to test', 'need to test', 'going to test',
      'plan to test', 'must test', 'should test',
      // Meeting patterns
      'want to meet', 'need to meet', 'going to meet',
      'want to meet with', 'need to meet with',
      'like to meet', 'plan to meet', 'must meet',
      // Vetting patterns
      'want to vet', 'need to vet', 'going to vet',
      'plan to vet', 'must vet', 'should vet'
    ];
    for (var pattern in strongInterviewPatterns) {
      if (text.contains(pattern)) {
        score += 0.60;
        break;
      }
    }

    // "interview" keyword is strongest signal (35%)
    final interviewKeywords = [
      'interview', 'interviewing', 'interviewed', 'interviews',
      'interviewer', 'interviewee', 'phone screen', 'screening call',
      'technical interview', 'behavioral interview', 'panel interview',
      'onsite interview', 'virtual interview', 'video interview',
      'first round', 'second round', 'final round', 'interview round'
    ];
    for (var keyword in interviewKeywords) {
      if (text.contains(keyword)) {
        score += 0.35;
        break;
      }
    }

    // Scheduling actions (30%)
    final schedulingActions = [
      'schedule', 'scheduling', 'scheduled',
      'arrange', 'arranging', 'arranged',
      'set up', 'setup', 'setting up',
      'book', 'booking', 'booked',
      'plan', 'planning', 'planned',
      'organize', 'organizing', 'coordinate', 'coordinating',
      'reschedule', 'rescheduling', 'postpone', 'postponing'
    ];
    for (var action in schedulingActions) {
      if (text.contains(action)) {
        score += 0.30;
        break;
      }
    }

    // Conducting/meeting actions (30%)
    final conductActions = [
      'conduct', 'conducting', 'hold', 'holding',
      'meeting', 'meet', 'meet with',
      'call', 'calling', 'video call', 'phone call', 'zoom call',
      'round', 'rounds', 'session', 'sessions',
      'discussion', 'discuss', 'discussing',
      'talk', 'talking', 'speak', 'speaking',
      'chat', 'chatting', 'conversation'
    ];
    for (var action in conductActions) {
      if (text.contains(action)) {
        score += 0.30;
        break;
      }
    }

    // Assessment/evaluation actions (40%)
    final assessmentActions = [
      'evaluate', 'evaluating', 'evaluation', 'evaluated',
      'assess', 'assessing', 'assessment', 'assessed',
      'review', 'reviewing', 'reviewed', 'reviews',
      'screen', 'screening', 'screened',
      'test', 'testing', 'tested',
      'examine', 'examining', 'examined',
      'check', 'checking', 'checked',
      'vet', 'vetting', 'vetted'
    ];
    for (var action in assessmentActions) {
      if (text.contains(action)) {
        score += 0.40;
        break;
      }
    }

    // Candidate mention in interview context (25%)
    final candidateMentions = [
      'candidate', 'candidates', 'applicant', 'applicants',
      'interviewee', 'prospect', 'prospects'
    ];
    final contextWords = [
      'with', 'for', 'of', 'the', 'a', 'some',
      'this', 'that', 'these', 'those'
    ];
    for (var mention in candidateMentions) {
      if (text.contains(mention)) {
        for (var context in contextWords) {
          if (text.contains(context)) {
            score += 0.25;
            break;
          }
        }
        break;
      }
    }

    // Time/date indicators (15%)
    final timeIndicators = [
      // Days
      'today', 'tomorrow', 'yesterday',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
      'this week', 'next week', 'last week', 'this month', 'next month',
      // Times
      'am', 'pm', 'oclock', "o'clock", 'time', 'at', 'clock',
      'morning', 'afternoon', 'evening', 'noon', 'midnight',
      '1pm', '2pm', '3pm', '4pm', '5pm', '10am', '11am', '9am',
      // Dates
      'date', 'dated', 'dates', 'calendar',
      'next', 'this', 'upcoming', 'scheduled for',
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
      'jan', 'feb', 'mar', 'apr', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
      // Relative times
      'asap', 'soon', 'later', 'now', 'immediately',
      'in an hour', 'in minutes', 'in a bit'
    ];
    for (var indicator in timeIndicators) {
      if (text.contains(indicator)) {
        score += 0.15;
        break;
      }
    }

    // Negative indicators (reduce score if job posting-related)
    final jobPostTerms = [
      'hire', 'hiring', 'hired', 'hire for',
      'recruit', 'recruiting', 'recruitment',
      'post job', 'post a job', 'posting job',
      'create job', 'create position', 'create role',
      'open position', 'open role', 'job opening',
      'fill position', 'fill role', 'fill vacancy',
      'employ', 'employment', 'staffing'
    ];
    for (var term in jobPostTerms) {
      if (text.contains(term)) {
        score -= 0.30;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateCandidateSearchScore(String text) {
    double score = 0.0;

    // Primary search patterns (60%)
    final primarySearchPatterns = [
      // Find patterns
      'find candidates', 'find me candidates', 'find some candidates', 'find a candidate',
      'find profiles', 'find me profiles', 'find some profiles', 'find a profile',
      'find resumes', 'find me resumes', 'find some resumes', 'find a resume',
      'find talent', 'find me talent', 'find applicants', 'find me applicants',
      'find cv', 'find cvs', 'find portfolio', 'find portfolios',
      // Search patterns
      'search candidates', 'search for candidates', 'searching candidates',
      'search profiles', 'search for profiles', 'searching profiles',
      'search resumes', 'search for resumes', 'searching resumes',
      'search talent', 'search for talent', 'searching talent',
      'search applicants', 'search cv', 'search cvs',
      'candidate search', 'profile search', 'talent search', 'resume search',
      // Looking patterns
      'looking for candidates', 'look for candidates',
      'looking for profiles', 'look for profiles',
      'looking for resumes', 'look for resumes',
      'looking for talent', 'look for talent',
      'looking for applicants', 'look at candidates', 'look at profiles',
      // Show patterns
      'show candidates', 'show me candidates', 'show all candidates',
      'show profiles', 'show me profiles', 'show all profiles',
      'show resumes', 'show me resumes', 'show all resumes',
      'show talent', 'show me talent', 'show applicants',
      // Browse/View patterns
      'browse candidates', 'browse profiles', 'browse resumes', 'browse talent',
      'browse through', 'browsing candidates', 'browsing profiles',
      'view candidates', 'view profiles', 'view resumes', 'view talent',
      'view all', 'viewing candidates', 'viewing profiles',
      // Get/Pull patterns
      'get candidates', 'get me candidates', 'get profiles', 'get resumes',
      'pull candidates', 'pull profiles', 'pull resumes', 'pull talent',
      'retrieve candidates', 'retrieve profiles', 'retrieve resumes',
      // Filter/Sort patterns
      'filter candidates', 'filter profiles', 'filter resumes',
      'sort candidates', 'sort profiles', 'sort resumes',
      // Query patterns
      'query candidates', 'query profiles', 'query database',
      // Existence/Availability queries (60%)
      'is there any', 'are there any', 'is there a', 'are there',
      'do we have any', 'do we have', 'do you have any', 'do you have',
      'have any', 'have we got any', 'got any',
      'any available', 'anyone available', 'anybody available'
    ];
    for (var pattern in primarySearchPatterns) {
      if (text.contains(pattern)) {
        score += 0.60;
        break;
      }
    }

    // "any [title]" at start - strong query indicator (65%)
    // e.g., "any associate engineer in new york", "any python developers"
    if (score < 0.60 && text.startsWith('any ') && _containsJobTitle(text)) {
      score += 0.65;
    }

    // Search + job title pattern (65%)
    // "find me developers", "search for engineers", "show me designers", "looking for candidates"
    if (score < 0.60) {
      final searchActions = ['find', 'search', 'show', 'show me', 'find me', 'search for', 'looking for'];
      for (var action in searchActions) {
        if (text.contains(action) && _containsJobTitle(text)) {
          // This is likely a candidate search, not a job post
          score += 0.65;
          break;
        }
      }
    }

    // Secondary search actions (45%)
    final secondarySearchActions = [
      // Basic search
      'find', 'finding', 'found', 'finder',
      'search', 'searching', 'searched', 'searcher',
      'looking for', 'look for', 'looking', 'look at', 'looking at',
      'seek', 'seeking', 'sought',
      // Display
      'show', 'show me', 'showing', 'display', 'displaying',
      'view', 'viewing', 'viewed',
      'see', 'seeing', 'check out',
      // Navigate
      'browse', 'browsing', 'browsed',
      'explore', 'exploring', 'explored',
      'review', 'reviewing', 'reviewed',
      'scan', 'scanning', 'scanned',
      // Retrieve
      'get', 'getting', 'got', 'grab', 'grabbing',
      'pull', 'pulling', 'pulled',
      'fetch', 'fetching', 'fetched',
      'retrieve', 'retrieving', 'retrieved',
      // Filter
      'filter', 'filtering', 'filtered',
      'sort', 'sorting', 'sorted',
      'query', 'querying', 'queried'
    ];
    if (score < 0.55) { // Only if no primary or job title pattern matched
      for (var action in secondarySearchActions) {
        if (text.contains(action)) {
          // Check if followed by candidate-related terms
          if (text.contains('candidate') || text.contains('profile') ||
              text.contains('resume') || text.contains('applicant')) {
            score += 0.45;
            break;
          }
        }
      }
    }

    // Candidate-related terms (30%)
    final candidateTerms = [
      // Candidate terms
      'candidate', 'candidates', 'candidacy',
      'applicant', 'applicants', 'application', 'applications',
      'prospect', 'prospects', 'prospective',
      'potential hire', 'potential hires', 'potential candidate',
      // Profile terms
      'profile', 'profiles', 'profiled',
      'resume', 'resumes', 'cv', 'cvs', 'curriculum vitae',
      'bio', 'bios', 'biography', 'biographies',
      'portfolio', 'portfolios', 'work sample', 'work samples',
      // Talent terms
      'talent', 'talents', 'skilled', 'professional', 'professionals',
      // Job seeker terms
      'job seeker', 'job seekers', 'job hunter', 'job hunters',
      'candidate pool', 'talent pool', 'applicant pool'
    ];
    for (var term in candidateTerms) {
      if (text.contains(term)) {
        score += 0.30;
        break;
      }
    }

    // Database/pool terms (25%)
    final databaseTerms = [
      // Database terms
      'database', 'databases', 'db',
      'talent database', 'candidate database', 'resume database',
      'applicant database', 'profile database',
      // Pool terms
      'talent pool', 'talent pools',
      'candidate pool', 'candidate pools',
      'applicant pool', 'applicant pools',
      'hiring pool', 'recruitment pool',
      // Bank/Repository terms
      'resume bank', 'resume banks', 'cv bank',
      'talent bank', 'candidate bank',
      'repository', 'repositories',
      // System terms
      'ats', 'applicant tracking', 'applicant tracking system',
      'crm', 'recruitment system', 'hiring system',
      'hrms', 'hris', 'talent management system',
      // Pipeline terms
      'pipeline', 'talent pipeline', 'candidate pipeline',
      'recruitment pipeline', 'hiring pipeline',
      'funnel', 'recruitment funnel', 'hiring funnel'
    ];
    for (var term in databaseTerms) {
      if (text.contains(term)) {
        score += 0.25;
        break;
      }
    }

    // Filter/sort actions (20%)
    final filterActions = [
      'filter', 'filtering', 'filtered',
      'sort', 'sorting', 'sorted',
      'view', 'viewing', 'viewed',
      'browse', 'browsing', 'browsed',
      'list', 'listing', 'listed',
      'query', 'querying', 'queried',
      'explore', 'exploring', 'explored'
    ];
    for (var action in filterActions) {
      if (text.contains(action)) {
        score += 0.20;
        break;
      }
    }

    // Job title in search context (25%)
    if (_containsJobTitle(text) && (text.contains('find') || text.contains('search') || text.contains('looking for'))) {
      score += 0.25;
    }

    // Negative indicators (reduce score if clearly job posting or interview)
    final jobPostTerms = [
      'hire', 'hiring', 'hired', 'hire for',
      'recruit', 'recruiting', 'recruitment',
      'post job', 'post a job', 'posting job',
      'create job', 'create position', 'create role',
      'open position', 'open role', 'job opening',
      'fill position', 'fill role', 'fill vacancy',
      'employ', 'employment', 'staffing'
    ];
    for (var term in jobPostTerms) {
      if (text.contains(term)) {
        score -= 0.30;
        break;
      }
    }

    final interviewTerms = [
      'interview', 'interviewing', 'interviewed',
      'schedule interview', 'scheduling interview',
      'conduct interview', 'conducting interview',
      'meeting', 'schedule meeting', 'arrange meeting',
      'call with', 'talk with', 'speak with', 'meet with'
    ];
    for (var term in interviewTerms) {
      if (text.contains(term)) {
        score -= 0.25;
        break;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  bool _containsJobTitle(String text) {
    final jobTitles = [
      // Tech & Engineering (massively expanded)
      'developer', 'dev', 'engineer', 'eng', 'programmer', 'coder', 'architect',
      'software engineer', 'software developer', 'web developer', 'full stack', 'fullstack',
      'frontend developer', 'frontend engineer', 'backend developer', 'backend engineer',
      'mobile developer', 'ios developer', 'android developer', 'app developer',
      'devops engineer', 'devops', 'sre', 'site reliability', 'platform engineer',
      'systems engineer', 'network engineer', 'network administrator', 'sysadmin',
      'cloud engineer', 'cloud architect', 'solutions architect', 'technical architect',
      'security engineer', 'security analyst', 'cybersecurity', 'infosec',
      'qa engineer', 'quality assurance', 'test engineer', 'sdet', 'automation engineer',
      'database administrator', 'dba', 'database engineer',
      'technician', 'tech', 'it specialist', 'it support', 'help desk',
      'integration engineer', 'technologist', 'systems analyst',
      'game developer', 'game engineer', 'unity developer', 'unreal developer',
      'embedded engineer', 'firmware engineer', 'hardware engineer',
      'ml engineer', 'ai engineer', 'machine learning engineer',

      // Data & Analytics (massively expanded)
      'analyst', 'data analyst', 'business analyst', 'systems analyst', 'financial analyst',
      'data scientist', 'data engineer', 'analytics engineer', 'bi analyst',
      'research analyst', 'market analyst', 'quantitative analyst', 'quant',
      'programmer analyst', 'data architect', 'etl developer',
      'statistician', 'researcher', 'research scientist',

      // Business & Management (massively expanded)
      'manager', 'mgr', 'director', 'head', 'lead', 'chief', 'executive',
      'project manager', 'program manager', 'product manager', 'pm', 'tpm',
      'engineering manager', 'technical manager', 'development manager',
      'operations manager', 'ops manager', 'general manager', 'gm',
      'account manager', 'client manager', 'relationship manager',
      'business development', 'bd', 'biz dev', 'business partner',
      'coordinator', 'supervisor', 'team lead', 'squad lead',
      'administrator', 'admin', 'office manager',
      'ceo', 'cto', 'cfo', 'coo', 'cmo', 'ciso', 'cpo', 'cdo',
      'vice president', 'vp', 'president', 'svp', 'evp',
      'principal', 'staff', 'distinguished', 'fellow',
      'entrepreneur', 'founder', 'co-founder', 'owner',
      'liaison', 'facilitator', 'scrum master', 'agile coach',

      // Sales & Marketing (massively expanded)
      'sales', 'salesperson', 'sales rep', 'sales representative', 'account executive', 'ae',
      'sales engineer', 'sales executive', 'sales manager', 'sales director',
      'business development representative', 'bdr', 'sdr', 'sales development',
      'account executive', 'senior account executive', 'enterprise sales',
      'marketer', 'marketing', 'marketing manager', 'marketing director', 'cmo',
      'product marketing', 'growth marketing', 'digital marketing', 'content marketing',
      'social media manager', 'community manager', 'brand manager',
      'seo specialist', 'sem specialist', 'ppc specialist',
      'campaign manager', 'demand generation', 'lead generation',
      'partnerships', 'partner manager', 'channel manager',
      'specialist', 'sales specialist', 'marketing specialist',

      // Design & Creative (massively expanded)
      'designer', 'design', 'graphic designer', 'visual designer', 'ui designer',
      'ux designer', 'ui/ux designer', 'product designer', 'web designer',
      'motion designer', 'animator', 'illustrator', 'artist',
      'creative director', 'art director', 'design director',
      'writer', 'content writer', 'copywriter', 'technical writer', 'editor',
      'journalist', 'reporter', 'author', 'blogger',
      'video editor', 'producer', 'videographer', 'photographer',

      // Product (expanded)
      'product manager', 'product owner', 'po', 'product lead',
      'product designer', 'product analyst', 'product operations',
      'growth product manager', 'technical product manager',

      // Professional Services (massively expanded)
      'consultant', 'advisor', 'specialist', 'expert',
      'accountant', 'cpa', 'bookkeeper', 'tax preparer', 'tax advisor',
      'auditor', 'audit', 'internal auditor', 'external auditor',
      'financial advisor', 'financial planner', 'wealth manager',
      'lawyer', 'attorney', 'counsel', 'legal', 'paralegal',
      'recruiter', 'recruiting', 'talent acquisition', 'ta', 'sourcer',
      'hr', 'human resources', 'hr manager', 'hr generalist', 'hr specialist',
      'people operations', 'people ops', 'people partner',

      // Healthcare (massively expanded)
      'doctor', 'physician', 'md', 'do', 'surgeon', 'cardiologist', 'pediatrician',
      'nurse', 'rn', 'registered nurse', 'lpn', 'nurse practitioner', 'np',
      'nurse coordinator', 'charge nurse', 'clinical nurse',
      'cna', 'certified nursing assistant', 'nursing assistant',
      'emt', 'paramedic', 'first responder',
      'therapist', 'physical therapist', 'pt', 'occupational therapist', 'ot',
      'speech therapist', 'respiratory therapist',
      'pharmacist', 'pharmacy', 'pharmacy technician',
      'medical assistant', 'ma', 'cma', 'medical technician',
      'radiology', 'radiologist', 'radiology tech', 'xray tech',
      'lab technician', 'phlebotomist', 'lab tech',
      'dentist', 'dental hygienist', 'dental assistant',
      'optometrist', 'optician', 'veterinarian', 'vet tech',
      'sanitarian', 'health inspector', 'clinical', 'clinician',
      'healthcare', 'medical', 'patient care',

      // Education (expanded)
      'teacher', 'educator', 'instructor', 'professor', 'lecturer',
      'tutor', 'trainer', 'coach', 'teaching assistant', 'ta',
      'principal', 'dean', 'superintendent', 'counselor',
      'librarian', 'curriculum developer',

      // Customer Service & Support (massively expanded)
      'customer service', 'customer support', 'customer success', 'cs',
      'support engineer', 'technical support', 'tech support',
      'support specialist', 'support representative', 'support agent',
      'help desk', 'service desk', 'helpdesk analyst',
      'customer care', 'client services', 'client success',
      'representative', 'rep', 'agent', 'operator',
      'call center', 'contact center', 'chat support',
      'customer experience', 'cx', 'customer advocate',

      // Operations & Logistics (massively expanded)
      'operations', 'ops', 'operations manager', 'operations analyst',
      'logistics', 'supply chain', 'procurement', 'purchasing',
      'warehouse', 'warehouse worker', 'warehouse manager', 'warehouse lead',
      'inventory', 'inventory manager', 'inventory analyst',
      'dispatcher', 'scheduler', 'planner', 'forklift operator',
      'facilities', 'facilities manager', 'building manager',
      'maintenance', 'maintenance technician', 'maintenance worker',

      // Retail & Hospitality (massively expanded)
      'cashier', 'retail', 'retail associate', 'sales associate',
      'store manager', 'assistant manager', 'shift supervisor',
      'merchandise associate', 'merchandiser', 'stocker',
      'barista', 'server', 'waiter', 'waitress', 'bartender',
      'host', 'hostess', 'front desk', 'receptionist',
      'housekeeper', 'housekeeping', 'custodian', 'janitor',
      'chef', 'cook', 'line cook', 'prep cook', 'sous chef',
      'food service', 'kitchen', 'dishwasher',

      // Trades & Skilled Labor (massively expanded)
      'electrician', 'plumber', 'mechanic', 'hvac', 'refrigeration',
      'carpenter', 'construction', 'contractor', 'builder',
      'welder', 'machinist', 'technician', 'installer',
      'driver', 'truck driver', 'delivery driver', 'cdl',
      'pilot', 'flight attendant', 'aircraft', 'aviation',

      // Finance & Accounting (expanded)
      'finance', 'accountant', 'controller', 'treasurer', 'cfo',
      'analyst', 'investment', 'banker', 'trader', 'portfolio manager',
      'risk analyst', 'compliance', 'credit analyst',

      // Legal & Compliance (expanded)
      'legal', 'lawyer', 'attorney', 'counsel', 'paralegal',
      'compliance', 'regulatory', 'risk', 'governance',

      // Administrative (expanded)
      'receptionist', 'secretary', 'administrative assistant', 'admin',
      'executive assistant', 'ea', 'office manager', 'clerk',
      'data entry', 'scheduler', 'assistant',

      // Other Specialized
      'scientist', 'researcher', 'research', 'lab', 'laboratory',
      'quality', 'qa', 'qc', 'quality control', 'inspector',
      'environmental', 'safety', 'ehs', 'safety coordinator',
      'translator', 'interpreter', 'linguist',
      'real estate', 'realtor', 'broker', 'agent',
      'insurance', 'claims', 'underwriter', 'actuary',
      'social worker', 'case manager', 'counselor',
      'security guard', 'security officer', 'guard',

      // Levels & Seniority (expanded)
      'senior', 'sr', 'junior', 'jr', 'intern', 'internship',
      'associate', 'entry level', 'entry-level', 'graduate', 'trainee',
      'mid level', 'mid-level', 'intermediate',
      'principal', 'lead', 'staff', 'distinguished', 'fellow',
      'apprentice', 'fresher', 'new grad',
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

    // Extract all 5 unified fields for all intent types
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

    // Additional context-specific fields
    if (intent == Intent.jobPost) {
      final experience = TextAnalyzer.extractExperience(message);
      if (experience != null) fields['experience'] = experience;
    }

    return fields;
  }
}
