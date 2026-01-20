import 'models.dart';

/// Fully offline intent classifier using regex and rule-based patterns
/// No API calls, instant responses, completely free!
class OfflineIntentClassifier {
  /// Classifies the given text to extract job posting fields using offline patterns
  ///
  /// Returns a [ClassificationResult] containing:
  /// - intent: Always UserIntent.createJobPost
  /// - fields: Extracted fields (title, location, experience, skills, salary, industry)
  /// - confidence: Score based on pattern matches
  ClassificationResult classify(String text) {
    if (text.trim().isEmpty) {
      return ClassificationResult(
        intent: UserIntent.createJobPost,
        fields: {},
        confidence: 0.0,
      );
    }

    final normalized = text.toLowerCase().trim();
    final fields = <String, dynamic>{};
    var matchScore = 0.0;
    var totalChecks = 0;

    // Extract experience
    final experience = _extractExperience(normalized);
    if (experience != null) {
      fields['experience'] = experience;
      matchScore += 1.0;
    }
    totalChecks++;

    // Extract location
    final location = _extractLocation(normalized);
    if (location != null) {
      fields['location'] = location;
      matchScore += 1.0;
    }
    totalChecks++;

    // Extract skills
    final skills = _extractSkills(normalized);
    if (skills.isNotEmpty) {
      fields['skills'] = skills;
      matchScore += 1.0;
    }
    totalChecks++;

    // Extract salary
    final salary = _extractSalary(normalized);
    if (salary != null) {
      fields['salary'] = salary;
      matchScore += 1.0;
    }
    totalChecks++;

    // Extract industry
    final industry = _extractIndustry(normalized);
    if (industry != null) {
      fields['industry'] = industry;
      matchScore += 1.0;
    }
    totalChecks++;

    // Extract job title (should be last to avoid conflicts)
    final title = _extractJobTitle(normalized, fields);
    if (title != null) {
      fields['title'] = title;
      matchScore += 1.0;
    }
    totalChecks++;

    // Calculate confidence based on matches
    final confidence = totalChecks > 0 ? (matchScore / totalChecks) : 0.0;

    return ClassificationResult(
      intent: UserIntent.createJobPost,
      fields: fields,
      confidence: confidence,
      rawResponse: 'Offline extraction',
    );
  }

  /// Extract years of experience using regex patterns
  String? _extractExperience(String text) {
    // Patterns: "5 years", "5+ years", "5-7 years", "5 yrs", "5 year"
    final patterns = [
      RegExp(r'(\d+)\+?\s*(?:-\s*\d+)?\s*(?:years?|yrs?)\s+(?:of\s+)?(?:experience|exp)'),
      RegExp(r'(\d+)\+?\s*(?:-\s*\d+)?\s*(?:years?|yrs?)'),
      RegExp(r'experience[:\s]+(\d+)\+?'),
      RegExp(r'exp[:\s]+(\d+)\+?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!;
      }
    }

    return null;
  }

  /// Extract location using common patterns and city names
  String? _extractLocation(String text) {
    // Common location indicators
    final locationKeywords = [
      'in', 'at', 'location:', 'based in', 'from', 'near', 'around'
    ];

    // Major cities and location keywords
    final locations = [
      // Pakistan
      'karachi', 'lahore', 'islamabad', 'rawalpindi', 'faisalabad', 'multan',
      'peshawar', 'quetta', 'sialkot', 'gujranwala', 'hyderabad',
      // USA
      'new york', 'nyc', 'san francisco', 'los angeles', 'chicago', 'boston',
      'seattle', 'austin', 'denver', 'portland', 'miami', 'atlanta',
      // Other major cities
      'london', 'dubai', 'singapore', 'toronto', 'vancouver', 'sydney',
      'melbourne', 'berlin', 'amsterdam', 'paris', 'tokyo', 'bangalore',
      'mumbai', 'delhi', 'pune',
      // Generic
      'remote', 'hybrid', 'onsite', 'on-site', 'work from home', 'wfh',
    ];

    // Try to find location after keywords
    for (final keyword in locationKeywords) {
      final pattern = RegExp('$keyword\\s+([\\w\\s]{3,20})(?:[,\\.]|\\s+with|\\s+for|\$)');
      final match = pattern.firstMatch(text);
      if (match != null) {
        final candidate = match.group(1)!.trim();
        if (locations.any((loc) => candidate.contains(loc))) {
          return _capitalizeWords(candidate);
        }
      }
    }

    // Direct match for known locations
    for (final loc in locations) {
      if (text.contains(loc)) {
        return _capitalizeWords(loc);
      }
    }

    return null;
  }

  /// Extract technical and professional skills (ALL TYPES - not just tech!)
  List<String> _extractSkills(String text) {
    final skills = <String>[];
    final normalizedSkills = <String>{};

    // COMPREHENSIVE skills dictionary - TECH + NON-TECH
    final skillsDict = {
      // Programming languages
      'python', 'java', 'javascript', 'typescript', 'c++', 'cpp',
      'c#', 'csharp', 'php', 'ruby', 'go', 'golang', 'rust', 'swift', 'kotlin',
      'dart', 'scala', 'r', 'matlab', 'perl', 'shell', 'bash',

      // Web frameworks
      'react', 'reactjs', 'react.js', 'angular', 'vue', 'vuejs', 'vue.js',
      'svelte', 'next.js', 'nextjs', 'nuxt', 'django', 'flask', 'fastapi',
      'express', 'expressjs', 'nestjs', 'spring', 'laravel', 'rails',
      'asp.net', 'blazor',

      // Mobile
      'flutter', 'react native', 'android', 'ios', 'xamarin', 'ionic',

      // Databases
      'sql', 'mysql', 'postgresql', 'postgres', 'mongodb', 'redis',
      'cassandra', 'dynamodb', 'oracle', 'mssql', 'sqlite', 'firebase',
      'elasticsearch', 'neo4j',

      // Cloud & DevOps
      'aws', 'azure', 'gcp', 'google cloud', 'docker', 'kubernetes', 'k8s',
      'jenkins', 'gitlab', 'github actions', 'terraform', 'ansible',
      'ci/cd', 'cicd',

      // Data & ML
      'machine learning', 'ml', 'deep learning', 'ai', 'nlp', 'computer vision',
      'tensorflow', 'pytorch', 'keras', 'scikit-learn', 'pandas', 'numpy',
      'data science', 'big data', 'hadoop', 'spark',

      // Other tech
      'git', 'rest', 'restful', 'api', 'graphql', 'microservices', 'agile',
      'scrum', 'node.js', 'nodejs', 'linux', 'unix', 'selenium', 'testing',
      'unit testing', 'tdd', 'bdd', 'jira', 'figma', 'photoshop',

      // FINANCE & ACCOUNTING
      'accounting', 'bookkeeping', 'quickbooks', 'sap', 'erp', 'excel',
      'financial analysis', 'auditing', 'taxation', 'payroll', 'tally',
      'budgeting', 'forecasting', 'financial reporting', 'accounts payable',
      'accounts receivable', 'reconciliation',

      // SALES & MARKETING
      'sales', 'marketing', 'digital marketing', 'seo', 'sem', 'ppc',
      'social media marketing', 'content marketing', 'email marketing',
      'lead generation', 'cold calling', 'negotiation', 'crm', 'salesforce',
      'hubspot', 'google analytics', 'facebook ads', 'google ads',
      'copywriting', 'brand management',

      // HR & RECRUITMENT
      'recruitment', 'hiring', 'talent acquisition', 'onboarding',
      'hr management', 'employee relations', 'performance management',
      'compensation', 'benefits', 'payroll', 'labor law', 'hris',

      // DESIGN & CREATIVE
      'photoshop', 'illustrator', 'indesign', 'after effects', 'premiere pro',
      'sketch', 'figma', 'adobe xd', 'ui design', 'ux design', 'graphic design',
      'video editing', 'animation', '3d modeling', 'branding',

      // OFFICE & ADMIN
      'microsoft office', 'ms office', 'word', 'excel', 'powerpoint',
      'data entry', 'typing', 'administrative', 'scheduling', 'calendar management',
      'email management', 'filing', 'documentation',

      // CUSTOMER SERVICE
      'customer service', 'customer support', 'call center', 'phone support',
      'chat support', 'ticketing', 'zendesk', 'freshdesk', 'complaint handling',

      // HEALTHCARE & MEDICAL
      'nursing', 'patient care', 'medical terminology', 'cpr', 'first aid',
      'emr', 'ehr', 'phlebotomy', 'vital signs', 'medication administration',
      'radiology', 'surgery', 'diagnostics',

      // EDUCATION & TEACHING
      'teaching', 'curriculum development', 'lesson planning', 'classroom management',
      'tutoring', 'training', 'e-learning', 'lms', 'student assessment',

      // HOSPITALITY & FOOD
      'cooking', 'food preparation', 'menu planning', 'food safety', 'haccp',
      'bartending', 'waitressing', 'hotel management', 'front desk',
      'housekeeping', 'guest relations',

      // TRANSPORTATION & LOGISTICS
      'driving', 'forklift', 'warehouse', 'inventory management', 'supply chain',
      'shipping', 'receiving', 'logistics', 'route planning', 'delivery',
      'commercial driving', 'cdl',

      // CONSTRUCTION & TRADES
      'carpentry', 'plumbing', 'electrical', 'welding', 'masonry', 'hvac',
      'painting', 'construction', 'blueprint reading', 'safety regulations',

      // LEGAL
      'legal research', 'contract drafting', 'litigation', 'compliance',
      'paralegal', 'legal writing',

      // SOFT SKILLS
      'communication', 'teamwork', 'leadership', 'problem solving',
      'time management', 'critical thinking', 'adaptability', 'creativity',
      'attention to detail', 'multitasking', 'organization',

      // LANGUAGES - World's major languages
      // South Asian
      'english', 'urdu', 'punjabi', 'sindhi', 'pashto', 'balochi', 'saraiki',
      'hindi', 'bengali', 'tamil', 'telugu', 'marathi', 'gujarati', 'kannada',
      'malayalam', 'odia', 'nepali', 'sinhala',
      // Middle Eastern
      'arabic', 'persian', 'farsi', 'dari', 'turkish', 'hebrew', 'kurdish',
      // East Asian
      'chinese', 'mandarin', 'cantonese', 'japanese', 'korean', 'vietnamese',
      'thai', 'indonesian', 'malay', 'tagalog', 'filipino',
      // European
      'spanish', 'french', 'german', 'italian', 'portuguese', 'russian',
      'polish', 'dutch', 'greek', 'swedish', 'norwegian', 'danish', 'finnish',
      'czech', 'hungarian', 'romanian', 'ukrainian', 'croatian', 'serbian',
      'bulgarian', 'slovak', 'albanian',
      // African
      'swahili', 'zulu', 'xhosa', 'afrikaans', 'amharic', 'hausa', 'yoruba',
      'igbo', 'somali',
      // Others
      'bilingual', 'multilingual', 'trilingual',
    };

    // Skill normalization map to avoid duplicates
    final skillNormalization = {
      'js': 'javascript',
      'ts': 'typescript',
      'nodejs': 'node.js',
      'reactjs': 'react',
      'vuejs': 'vue',
      'nextjs': 'next.js',
      'expressjs': 'express',
      'postgres': 'postgresql',
      'mongo': 'mongodb',
      'k8s': 'kubernetes',
    };

    for (final skill in skillsDict) {
      // Escape special regex characters in skill name
      final escapedSkill = RegExp.escape(skill);
      // Check for whole word or common variations
      final pattern = RegExp('\\b$escapedSkill\\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        final normalized = skillNormalization[skill.toLowerCase()] ?? skill;
        normalizedSkills.add(_capitalizeSkill(normalized));
      }
    }

    // Also check for common abbreviations
    for (final entry in skillNormalization.entries) {
      final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        normalizedSkills.add(_capitalizeSkill(entry.value));
      }
    }

    return normalizedSkills.toList();
  }

  /// Extract salary information
  String? _extractSalary(String text) {
    // Patterns: "100k", "$100000", "100000", "100-150k", "Rs. 50000"
    final patterns = [
      RegExp(r'(?:salary|pay|compensation)[:\s]+(?:rs\.?|pkr|usd|\$)?\s*(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:k|lakh|lac)?'),
      RegExp(r'(?:rs\.?|pkr|usd|\$)\s*(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:k|lakh|lac)?(?:/month|/year|per month|per year)?'),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:k|lakh|lac)(?:/month|/year|per month|per year)?'),
      RegExp(r'(\d+)\s*-\s*(\d+)\s*(?:k|lakh)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2 && match.group(2) != null) {
          return '${match.group(1)}-${match.group(2)}k';
        }
        return match.group(1)!;
      }
    }

    return null;
  }

  /// Extract industry/domain (ALL INDUSTRIES!)
  String? _extractIndustry(String text) {
    final industries = {
      // Tech & Digital
      'fintech': ['fintech', 'financial technology'],
      'software': ['software', 'saas', 'b2b software', 'enterprise software'],
      'e-commerce': ['ecommerce', 'e-commerce', 'online shopping'],
      'social media': ['social media', 'social network'],
      'gaming': ['gaming', 'esports', 'video game'],
      'cybersecurity': ['cybersecurity', 'infosec', 'information security'],
      'blockchain': ['blockchain', 'cryptocurrency', 'crypto', 'web3', 'defi'],
      'ai/ml': ['artificial intelligence'],
      'cloud': ['cloud computing', 'cloud services'],

      // Finance & Business
      'banking': ['banking', 'bank'],
      'finance': ['finance', 'financial services', 'investment'],
      'insurance': ['insurance', 'assurance'],
      'accounting': ['accounting', 'audit', 'chartered accountant'],
      'consulting': ['consulting', 'consultancy', 'advisory'],

      // Healthcare
      'healthcare': ['healthcare', 'health'],
      'pharmaceutical': ['pharmaceutical', 'pharma', 'pharmacy'],
      'medical': ['medical', 'clinic', 'hospital'],
      'dental': ['dental', 'dentistry'],

      // Education
      'education': ['education', 'school', 'university', 'college'],
      'edtech': ['edtech'],
      'training': ['training institute'],

      // Retail & Consumer
      'retail': ['retail', 'shopping', 'store'],
      'fmcg': ['fmcg', 'consumer goods', 'fast moving consumer goods'],
      'fashion': ['fashion', 'apparel', 'clothing', 'garment'],
      'beauty': ['beauty', 'cosmetics'],

      // Hospitality & Food
      'hospitality': ['hospitality', 'hotel'],
      'restaurant': ['restaurant', 'cafe', 'eatery'],
      'food': ['food service', 'food industry', 'catering'],
      'tourism': ['tourism', 'travel agency'],

      // Transportation & Logistics
      'logistics': ['logistics', 'supply chain'],
      'transportation': ['transportation', 'transport'],
      'shipping': ['shipping', 'freight', 'cargo'],
      'delivery': ['delivery service', 'courier'],
      'aviation': ['aviation', 'airline', 'airport'],

      // Real Estate & Construction
      'real estate': ['real estate', 'property'],
      'construction': ['construction', 'building'],
      'architecture': ['architecture', 'architectural'],

      // Manufacturing & Industrial
      'manufacturing': ['manufacturing', 'factory', 'production'],
      'automotive': ['automotive', 'automobile', 'vehicle'],
      'textile': ['textile', 'garment', 'fabric'],
      'steel': ['steel', 'metal'],
      'chemical': ['chemical', 'chemicals'],
      'oil & gas': ['oil and gas', 'petroleum', 'energy'],

      // Media & Entertainment
      'media': ['media', 'broadcasting', 'news'],
      'advertising': ['advertising', 'marketing agency'],
      'entertainment': ['entertainment', 'film', 'television'],
      'publishing': ['publishing', 'print'],

      // Telecom
      'telecom': ['telecom', 'telecommunications', 'mobile network'],

      // Agriculture
      'agriculture': ['agriculture', 'farming', 'agri'],

      // Legal
      'legal': ['legal', 'law firm'],

      // NGO & Social
      'ngo': ['ngo', 'non-profit', 'charity', 'welfare'],

      // Government
      'government': ['government', 'public sector'],

      // Security
      'security': ['security services', 'private security'],

      // Sports & Fitness
      'sports': ['sports', 'fitness', 'gym'],
    };

    for (final entry in industries.entries) {
      for (final keyword in entry.value) {
        // Use word boundaries to avoid false matches (e.g., "machine learning" shouldn't match "learning")
        final pattern = RegExp('\\b${RegExp.escape(keyword)}\\b', caseSensitive: false);
        if (pattern.hasMatch(text)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// Extract job title using SMART PATTERNS (handles UNLIMITED job variations!)
  String? _extractJobTitle(String text, Map<String, dynamic> existingFields) {
    // STRATEGY: Use generic patterns to extract ANY job title
    // This works for millions of variations, not just hardcoded titles

    // 1. Try to find title with skill/technology prefix
    if (existingFields.containsKey('skills')) {
      final skills = existingFields['skills'] as List<String>;
      for (final skill in skills) {
        // Pattern: "{skill} {role}"
        final patterns = [
          RegExp('\\b${RegExp.escape(skill.toLowerCase())}\\s+(developer|engineer|programmer|specialist|expert|architect|consultant|designer)\\b', caseSensitive: false),
        ];

        for (final pattern in patterns) {
          final match = pattern.firstMatch(text);
          if (match != null) {
            return _capitalizeWords('${skill.toLowerCase()} ${match.group(1)!}');
          }
        }
      }
    }

    // 2. Generic job role suffixes (works for ANY prefix!)
    final roleSuffixes = [
      'developer', 'engineer', 'designer', 'manager', 'analyst', 'specialist',
      'coordinator', 'assistant', 'associate', 'executive', 'director',
      'supervisor', 'consultant', 'architect', 'administrator', 'officer',
      'representative', 'agent', 'technician', 'operator', 'worker',
      'instructor', 'trainer', 'teacher', 'professor', 'lecturer',
      'scientist', 'researcher', 'advisor', 'counselor', 'therapist',
      'nurse', 'doctor', 'physician', 'pharmacist', 'surgeon',
      'accountant', 'auditor', 'cashier', 'clerk', 'receptionist',
      'chef', 'cook', 'waiter', 'waitress', 'bartender', 'barista',
      'driver', 'pilot', 'captain', 'guard', 'officer',
      'mechanic', 'electrician', 'plumber', 'carpenter', 'welder',
      'artist', 'photographer', 'videographer', 'writer', 'editor',
      'recruiter', 'salesperson', 'marketer', 'strategist',
    ];

    // Pattern: "need/looking for/hiring {prefix} {role}"
    for (final suffix in roleSuffixes) {
      final patterns = [
        // "i want to create job post for python developer"
        // "create job post for python developer"
        RegExp('(?:create|make|post|add)\\s+(?:a\\s+|an\\s+)?(?:job\\s+post|job|posting|vacancy)\\s+(?:for\\s+)?(?:a\\s+|an\\s+)?(?:experienced\\s+|senior\\s+|junior\\s+)?([\\w\\s-]{0,30}?)\\s*\\b${suffix}\\b', caseSensitive: false),
        // "i want python developer" / "iwant python developer"
        RegExp('(?:i\\s*want|want|need|looking for|hiring|required?|seeking)\\s+(?:to\\s+)?(?:hire\\s+)?(?:a\\s+|an\\s+)?(?:experienced\\s+|senior\\s+|junior\\s+)?([\\w\\s-]{0,30}?)\\s*\\b${suffix}\\b', caseSensitive: false),
        // "need senior python developer"
        RegExp('(?:need|looking for|hiring|required?|want|seeking)\\s+(?:a\\s+|an\\s+)?(?:experienced\\s+|senior\\s+|junior\\s+)?([\\w\\s-]{0,30}?)\\s*\\b${suffix}\\b', caseSensitive: false),
        // "senior python developer needed"
        RegExp('(?:experienced\\s+|senior\\s+|junior\\s+)?([\\w\\s-]{0,30}?)\\s*\\b${suffix}\\b\\s+(?:needed|required|wanted)', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final prefix = match.group(1)?.trim() ?? '';
          if (prefix.isNotEmpty && prefix.split(' ').length <= 4) {
            return _capitalizeWords('$prefix $suffix');
          } else {
            return _capitalizeWords(suffix);
          }
        }
      }
    }

    // 3. Pattern: "position/role/job: {title}"
    final positionPattern = RegExp(r'(?:position|role|job|vacancy)[:\s]+([a-z\s/-]{3,50})(?:[,\.]|\s+(?:in|for|with|at)|$)', caseSensitive: false);
    final positionMatch = positionPattern.firstMatch(text);
    if (positionMatch != null) {
      return _capitalizeWords(positionMatch.group(1)!.trim());
    }

    // 4. Common standalone titles (high-confidence matches)
    final commonTitles = {
      // C-level
      'ceo', 'cto', 'cfo', 'coo', 'cmo', 'cpo', 'cso',
      // Generic
      'manager', 'director', 'supervisor', 'coordinator', 'assistant',
      // Common standalone
      'accountant', 'lawyer', 'doctor', 'nurse', 'teacher', 'chef',
      'driver', 'guard', 'receptionist', 'cashier', 'clerk',
      'photographer', 'designer', 'writer', 'editor', 'translator',
    };

    for (final title in commonTitles) {
      final pattern = RegExp('\\b$title\\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        return _capitalizeWords(title);
      }
    }

    // 5. Compound titles: "{adjective} {noun} {role}"
    final compoundPattern = RegExp(
      r'\b(senior|junior|lead|principal|chief|head|assistant|associate|deputy|vice|executive|general|regional|area|branch|store|shift|night|day)\s+([\w]+)\s+(manager|engineer|developer|designer|analyst|coordinator|supervisor|officer|specialist)',
      caseSensitive: false,
    );
    final compoundMatch = compoundPattern.firstMatch(text);
    if (compoundMatch != null) {
      return _capitalizeWords('${compoundMatch.group(1)} ${compoundMatch.group(2)} ${compoundMatch.group(3)}');
    }

    // 6. Multi-word professional titles
    final multiWordPattern = RegExp(
      r'\b(human resources|customer service|business development|quality assurance|quality control|data science|machine learning|sales and marketing|supply chain|real estate|social media|project management|product management|software development|web development|graphic design|interior design|financial planning|tax|legal|public relations|event management)\s+(manager|specialist|coordinator|executive|analyst|consultant|director|officer|representative|agent)?',
      caseSensitive: false,
    );
    final multiMatch = multiWordPattern.firstMatch(text);
    if (multiMatch != null) {
      final base = multiMatch.group(1)!;
      final role = multiMatch.group(2);
      if (role != null && role.isNotEmpty) {
        return _capitalizeWords('$base $role');
      }
      return _capitalizeWords(base);
    }

    // 7. Fallback: Extract first noun-like word before common verbs
    final fallbackPattern = RegExp(
      r'\b([a-z]{3,20})\s+(?:needed|required|wanted|looking|hiring|seeking|vacancy|available)',
      caseSensitive: false,
    );
    final fallbackMatch = fallbackPattern.firstMatch(text);
    if (fallbackMatch != null) {
      return _capitalizeWords(fallbackMatch.group(1)!);
    }

    return null;
  }

  /// Capitalize first letter of each word
  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Capitalize skill names properly
  String _capitalizeSkill(String skill) {
    // Special cases
    final specialCases = {
      'javascript': 'JavaScript',
      'typescript': 'TypeScript',
      'nodejs': 'Node.js',
      'react.js': 'React.js',
      'vue.js': 'Vue.js',
      'next.js': 'Next.js',
      'express.js': 'Express.js',
      'nestjs': 'NestJS',
      'reactjs': 'ReactJS',
      'vuejs': 'VueJS',
      'aws': 'AWS',
      'gcp': 'GCP',
      'sql': 'SQL',
      'mysql': 'MySQL',
      'postgresql': 'PostgreSQL',
      'mongodb': 'MongoDB',
      'graphql': 'GraphQL',
      'restful': 'RESTful',
      'api': 'API',
      'html': 'HTML',
      'css': 'CSS',
      'php': 'PHP',
      'ios': 'iOS',
      'ai': 'AI',
      'ml': 'ML',
      'nlp': 'NLP',
      'ui/ux': 'UI/UX',
      'cicd': 'CI/CD',
      'ci/cd': 'CI/CD',
      'github': 'GitHub',
      'gitlab': 'GitLab',
      'k8s': 'K8s',
    };

    final lower = skill.toLowerCase();
    if (specialCases.containsKey(lower)) {
      return specialCases[lower]!;
    }

    return _capitalizeWords(skill);
  }
}
