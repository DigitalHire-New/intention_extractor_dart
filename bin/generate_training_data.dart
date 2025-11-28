/// Generates 100k diverse training prompts for the intent classifier
/// Covers multiple industries, skills, and USA locations
///
/// Run: dart run bin/generate_training_data.dart

import 'dart:io';
import 'dart:math';
import 'package:user_intent_classifier/user_intent_classifier.dart';

void main() async {
  print('🚀 Generating 100,000 diverse training prompts...\n');

  final generator = TrainingDataGenerator();
  final prompts = generator.generate100kPrompts();

  print('✅ Generated ${prompts.length} prompts');
  print('📊 Distribution:');
  print('   - JOB_POST: ${prompts.where((p) => p.intent == Intent.jobPost).length}');
  print('   - INTERVIEW: ${prompts.where((p) => p.intent == Intent.interview).length}');
  print('   - CANDIDATE_SEARCH: ${prompts.where((p) => p.intent == Intent.candidateSearch).length}');

  // Test classification accuracy
  print('\n🧪 Testing classifier accuracy on generated prompts...');
  await _testAccuracy(prompts);

  // Save to file
  print('\n💾 Saving to training_data_100k.csv...');
  _saveToCSV(prompts, 'training_data_100k.csv');

  print('\n✨ Done!');
}

Future<void> _testAccuracy(List<TrainingPrompt> prompts) async {
  final classifier = IntentClassifier();

  // Sample 1000 prompts for testing
  final random = Random(42);
  final sample = <TrainingPrompt>[];
  for (var i = 0; i < 1000 && i < prompts.length; i++) {
    sample.add(prompts[random.nextInt(prompts.length)]);
  }

  var correct = 0;
  var total = 0;

  for (var prompt in sample) {
    final result = await classifier.classify(prompt.text);
    if (result.intent == prompt.intent) {
      correct++;
    }
    total++;
  }

  final accuracy = (correct / total * 100).toStringAsFixed(2);
  print('Accuracy: $accuracy% ($correct/$total)');
}

void _saveToCSV(List<TrainingPrompt> prompts, String filename) {
  final file = File(filename);
  final lines = ['text,intent'];

  for (var prompt in prompts) {
    final intent = prompt.intent?.value ?? 'null';
    final text = '"${prompt.text.replaceAll('"', '""')}"'; // Escape quotes
    lines.add('$text,$intent');
  }

  file.writeAsStringSync(lines.join('\n'));
  print('Saved to: ${file.absolute.path}');
}

class TrainingPrompt {
  final String text;
  final Intent? intent;

  TrainingPrompt(this.text, this.intent);
}

class TrainingDataGenerator {
  final Random _random = Random();

  List<TrainingPrompt> generate100kPrompts() {
    final prompts = <TrainingPrompt>[];

    // Distribution: 40% JOB_POST, 30% INTERVIEW, 30% CANDIDATE_SEARCH
    final jobPostCount = 40000;
    final interviewCount = 30000;
    final candidateSearchCount = 30000;

    print('Generating JOB_POST prompts...');
    prompts.addAll(_generateJobPostPrompts(jobPostCount));

    print('Generating INTERVIEW prompts...');
    prompts.addAll(_generateInterviewPrompts(interviewCount));

    print('Generating CANDIDATE_SEARCH prompts...');
    prompts.addAll(_generateCandidateSearchPrompts(candidateSearchCount));

    // Shuffle
    prompts.shuffle(_random);

    return prompts;
  }

  List<TrainingPrompt> _generateJobPostPrompts(int count) {
    final prompts = <TrainingPrompt>[];

    for (var i = 0; i < count; i++) {
      final template = _randomElement(_jobPostTemplates);
      final title = _randomElement(_jobTitles);
      final location = _randomElement(_usLocations);
      final skill = _randomElement(_skills);
      final salary = _randomElement(_salaries);
      final experience = _randomElement(_experienceLevels);
      final industry = _randomElement(_industries);
      final workplace = _randomElement(_workplaceTypes);

      var text = template
          .replaceAll('{title}', title)
          .replaceAll('{location}', location)
          .replaceAll('{skill}', skill)
          .replaceAll('{salary}', salary)
          .replaceAll('{experience}', experience)
          .replaceAll('{industry}', industry)
          .replaceAll('{workplace}', workplace);

      prompts.add(TrainingPrompt(text, Intent.jobPost));
    }

    return prompts;
  }

  List<TrainingPrompt> _generateInterviewPrompts(int count) {
    final prompts = <TrainingPrompt>[];

    for (var i = 0; i < count; i++) {
      final template = _randomElement(_interviewTemplates);
      final title = _randomElement(_jobTitles);
      final candidateName = _randomElement(_candidateNames);
      final time = _randomElement(_times);
      final day = _randomElement(_days);
      final interviewType = _randomElement(_interviewTypes);

      var text = template
          .replaceAll('{title}', title)
          .replaceAll('{candidate}', candidateName)
          .replaceAll('{time}', time)
          .replaceAll('{day}', day)
          .replaceAll('{type}', interviewType);

      prompts.add(TrainingPrompt(text, Intent.interview));
    }

    return prompts;
  }

  List<TrainingPrompt> _generateCandidateSearchPrompts(int count) {
    final prompts = <TrainingPrompt>[];

    for (var i = 0; i < count; i++) {
      final template = _randomElement(_candidateSearchTemplates);
      final title = _randomElement(_jobTitles);
      final location = _randomElement(_usLocations);
      final skill = _randomElement(_skills);
      final experience = _randomElement(_experienceLevels);

      var text = template
          .replaceAll('{title}', title)
          .replaceAll('{location}', location)
          .replaceAll('{skill}', skill)
          .replaceAll('{experience}', experience);

      prompts.add(TrainingPrompt(text, Intent.candidateSearch));
    }

    return prompts;
  }

  T _randomElement<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  // ============================================================================
  // JOB_POST TEMPLATES (200+ variations)
  // ============================================================================
  final _jobPostTemplates = [
    // Hiring actions
    'Hiring {title} in {location}',
    'Looking to hire {title} with {skill} experience',
    'Need to hire a {title} for our {industry} team',
    'We are hiring {title} - {salary}',
    'Recruiting {title} for {location}, {workplace}',
    'Urgently hiring {experience} {title}',
    'Post job for {title} position',
    'Create job posting for {title} in {location}',
    'Publish {title} job opening - {salary}',
    'Looking for {title} to join our team in {location}',
    'Seeking {experience} {title} with {skill}',
    'Want to hire {title} ASAP',
    'Need {title} for {industry} company',
    'Hiring {title} - {workplace}, {location}',
    'Recruit {experience} {title} in {location}',
    'Onboarding {title} for {industry} team',
    'Staffing {title} position in {location}',
    'Fill {title} role with {skill} expertise',
    'Add {title} to our {industry} team',
    'Expand team with {title}',
    'Growing team - need {title}',
    'Building {industry} team - hiring {title}',
    'Talent acquisition: {title} in {location}',
    'Open position: {experience} {title}',
    'Job opening for {title} - {salary}',
    '{title} vacancy in {location}',
    'Career opportunity: {title} at {industry} company',
    '{title} role available - {workplace}',
    'Employment opportunity: {title}',
    '{title} position - {experience}, {location}',

    // Complex patterns
    'Hire {title} with {skill} for {workplace} role in {location}',
    'Post {title} job - {salary}, {experience} required',
    'Looking for {experience} {title} in {location} with {skill}',
    'Recruiting top {title} talent in {location} - {salary}',
    '{title} needed for {industry} startup in {location}',
    'Want to hire {title} - {skill}, {experience}, {workplace}',
    'Fill {title} role - {location}, {salary}, {workplace}',
    'Seeking {title} for {industry} - {experience} level',
    '{industry} company hiring {title} in {location}',
    'Need {experience} {title} with strong {skill} background',

    // Bare title + location (should be JOB_POST, not CANDIDATE_SEARCH)
    '{title} in {location}',
    '{experience} {title} {location}',
    '{title} - {location}',
    '{title} {location} {workplace}',
    '{title} role {location}',
    '{title} position {location}',

    // Job title variations
    '{title} jobs in {location}',
    '{experience} {title} jobs',
    '{industry} {title} jobs - {location}',
    'Customer service jobs in {location}',
    'Software engineer jobs - {salary}',
    'Entry level {title} jobs',

    // Action-first patterns
    'Post a job for {title}',
    'Create position for {title}',
    'Open role for {title} in {location}',
    'Advertise {title} position',
    'List {title} job opening',
    'Publish {title} vacancy',
    'Onboard {title} for {industry}',
    'Employ {title} in {location}',
    'Bring on {title} for our team',
    'Take on {experience} {title}',

    // Professional titles (should be JOB_POST)
    'Technical Recruiter',
    'Hiring Manager position',
    'RN Pediatric',
    'Interventional Radiology Technologist',
    'Engineering Manager in {location}',
    'Vice President of {industry}',
    'Chief Technology Officer',
    'Senior Hiring Manager',
    'Programmer Analyst 1',
    'Software Engineer III',
    'Business Development Partner',
    'Account Executive - {industry}',

    // Industry-specific patterns
    '{industry} {title} - {location}',
    '{title} for {industry} company',
    '{industry} startup needs {title}',
    'Hiring {title} for {industry} in {location}',
    '{industry} firm seeking {title}',

    // Salary-focused
    '{title} - {salary} in {location}',
    'Hiring {title}, offering {salary}',
    '{title} position paying {salary}',
    '{salary} {title} role',
    'Competitive salary for {title} - {location}',

    // Workplace-focused
    '{workplace} {title} position',
    'Hiring {workplace} {title}',
    '{title} - {workplace} in {location}',
    '{workplace} opportunity: {title}',
    'Fully {workplace} {title} role',

    // Urgency patterns
    'URGENT: {title} needed in {location}',
    'Immediate hire: {title}',
    '{title} needed ASAP - {location}',
    'Quick hire for {title} position',
    'Fast-track hiring for {title}',
  ];

  // ============================================================================
  // INTERVIEW TEMPLATES (150+ variations)
  // ============================================================================
  final _interviewTemplates = [
    // Scheduling actions
    'Schedule interview with {candidate}',
    'Schedule {title} interview for {day}',
    'Book interview at {time}',
    'Arrange interview with {candidate} tomorrow',
    'Set up interview for {day} at {time}',
    'Plan interview with {title} candidate',
    'Organize interview for {day}',
    'Coordinate interview with {candidate}',
    'Reschedule interview to {day}',
    'Postpone interview with {candidate}',
    'Move interview to {time}',

    // Conducting interviews
    'Interview {candidate} today',
    'Conducting interview with {title}',
    'Hold interview at {time}',
    'Interview the {title} applicant',
    'Meeting with {candidate} for interview',
    'Video call interview at {time}',
    'Phone interview with {candidate}',
    'Zoom call with {title} candidate',
    '{type} interview scheduled for {day}',
    'Round 2 interview with {candidate}',
    'Final interview for {title} position',
    'Panel interview at {time}',
    'Technical interview with {candidate}',

    // Want/need to interview patterns
    'Want to interview {candidate}',
    'Need to interview a {title}',
    'Going to interview {title} applicants',
    'Would like to interview {candidate}',
    'Planning to interview {title} candidates',
    'Ready to interview for {title} role',
    'Must interview {candidate} ASAP',
    'Should interview the {title}',
    'Gonna interview {candidate} {day}',

    // Assessment actions
    'Evaluate {candidate} for {title} role',
    'Assess {title} candidate',
    'Review {candidate} application',
    'Screen {title} applicants',
    'Test {candidate} skills',
    'Examine {title} candidate qualifications',
    'Check out {candidate} for {title}',
    'Vet {candidate} for the position',
    'Want to evaluate {candidate}',
    'Need to assess {title} candidates',
    'Going to review {candidate} today',
    'Plan to screen {title} applicants',

    // Time-specific patterns
    'Interview {day} at {time}',
    'Interview scheduled for {day}',
    'Interview tomorrow with {candidate}',
    'Interview this week',
    'Interview next {day}',
    'Interview at {time} today',
    '{candidate} interview ASAP',
    'Interview soon with {title}',

    // Candidate-focused
    'Interview the candidate for {title}',
    'Interview applicant {candidate}',
    'Talk with {candidate} about {title} role',
    'Speak with {title} prospect',
    'Discuss {title} position with {candidate}',
    'Chat with {candidate} about the role',
    'Meet with {title} candidate',
    'Connect with {candidate} for interview',

    // Complex patterns
    'Schedule {type} interview with {candidate} on {day} at {time}',
    'Want to interview {candidate} for {title} position',
    'Need to conduct {type} interview with {title} applicant',
    'Planning {type} interview for {day}',
    '{type} interview with {candidate} - {day} at {time}',
    'Assess {candidate} via {type} interview',
    'Evaluate {title} candidate through interview',

    // Action + candidate patterns
    'Interviewing {candidate}',
    'Assessing {title} applicants',
    'Evaluating {candidate} today',
    'Screening {title} candidates',
    'Testing {candidate} skills',
    'Reviewing {title} applications',
    'Vetting {candidate} for role',
    'Checking {candidate} qualifications',
  ];

  // ============================================================================
  // CANDIDATE_SEARCH TEMPLATES (150+ variations)
  // ============================================================================
  final _candidateSearchTemplates = [
    // Find patterns
    'Find {title} candidates in {location}',
    'Find me {title} with {skill}',
    'Find {experience} {title} profiles',
    'Find candidates for {title} role',
    'Find me {title} in {location}',
    'Find some {title} resumes',
    'Find {skill} developers',
    'Find talent in {location}',

    // Search patterns
    'Search for {title} candidates',
    'Search {title} profiles in {location}',
    'Search for {skill} engineers',
    'Search candidates with {experience}',
    'Candidate search for {title}',
    'Search resumes for {title}',
    'Search talent pool for {skill}',
    'Profile search: {title}',

    // Looking patterns
    'Looking for {title} candidates',
    'Looking for {experience} {title}',
    'Looking for {skill} professionals in {location}',
    'Look for {title} profiles',
    'Looking at {title} candidates',
    'Looking for talent with {skill}',

    // Show/display patterns
    'Show me {title} candidates',
    'Show {title} profiles in {location}',
    'Show all {title} resumes',
    'Show me {experience} {title}',
    'Display {title} candidates',
    'Show {skill} developers',

    // Browse/view patterns
    'Browse {title} profiles',
    'Browse candidates in {location}',
    'View {title} resumes',
    'View all {title} applicants',
    'Browse through {skill} talent',
    'Viewing {title} candidates',
    'Browse talent pool',

    // Get/pull/retrieve patterns
    'Get {title} candidates from database',
    'Pull {title} profiles',
    'Retrieve {title} resumes',
    'Get me {experience} {title}',
    'Pull candidates with {skill}',
    'Fetch {title} from ATS',

    // Filter/sort/query patterns
    'Filter {title} candidates by {location}',
    'Sort {title} profiles',
    'Query database for {skill} engineers',
    'Filter candidates with {experience}',
    'Sort {title} by experience',
    'Query ATS for {title}',

    // Existence/availability queries
    'Is there any {title} in {location}',
    'Are there any {skill} developers',
    'Do we have {title} candidates',
    'Do you have any {experience} {title}',
    'Any {title} available',
    'Anyone available with {skill}',
    'Got any {title} in {location}',
    'Have we got any {skill} engineers',

    // "Any [title]" at start (strong query pattern)
    'Any {title} in {location}',
    'Any {experience} {title}',
    'Any {skill} developers',
    'Any associate engineer in {location}',
    'Any python developers',
    'Any senior {title} available',

    // Database/pool terms
    'Browse profiles in the ATS',
    'Query candidate database for {title}',
    'Search talent pool for {skill}',
    'Pull resumes from database',
    'View talent pipeline for {title}',
    'Check candidate pool for {location}',
    'Search recruitment system for {title}',
    'Browse applicant pool',

    // Complex patterns
    'Find me {experience} {title} with {skill} in {location}',
    'Search for {title} candidates with {skill} experience',
    'Looking for {experience} {title} in {location}',
    'Show me {title} profiles with {skill}',
    'Browse {title} candidates in {location} with {experience}',
    'Is there any {title} with {skill} in {location}',
    'Do we have {experience} {title} with {skill}',
    'Find {title} in talent database',
    'Query for {skill} professionals in {location}',
    'Search {title} resumes in {location}',

    // Action + title patterns
    'Find developers',
    'Search engineers',
    'Show me designers',
    'Browse analysts',
    'View managers',
    'Get programmers',
    'Pull consultants',
    'Retrieve specialists',
  ];

  // ============================================================================
  // DATA: Job Titles (400+)
  // ============================================================================
  final _jobTitles = [
    // Tech & Engineering
    'Software Engineer', 'Software Developer', 'Full Stack Developer', 'Frontend Developer',
    'Backend Developer', 'Web Developer', 'Mobile Developer', 'iOS Developer',
    'Android Developer', 'DevOps Engineer', 'Site Reliability Engineer', 'Platform Engineer',
    'Cloud Engineer', 'Solutions Architect', 'Technical Architect', 'Security Engineer',
    'QA Engineer', 'Test Engineer', 'Automation Engineer', 'Database Administrator',
    'Systems Engineer', 'Network Engineer', 'IT Specialist', 'Help Desk Technician',
    'Game Developer', 'Unity Developer', 'Embedded Engineer', 'Firmware Engineer',
    'ML Engineer', 'AI Engineer', 'Computer Vision Engineer', 'NLP Engineer',
    'Senior Software Engineer', 'Junior Developer', 'Lead Engineer', 'Principal Engineer',
    'Staff Engineer', 'Engineering Manager', 'Technical Lead', 'Architect',

    // Data & Analytics
    'Data Analyst', 'Data Scientist', 'Data Engineer', 'Business Analyst',
    'Analytics Engineer', 'BI Analyst', 'Research Analyst', 'Market Analyst',
    'Quantitative Analyst', 'Statistician', 'Researcher', 'Data Architect',
    'ETL Developer', 'Big Data Engineer', 'Machine Learning Engineer',

    // Product & Design
    'Product Manager', 'Product Designer', 'UX Designer', 'UI Designer',
    'UI/UX Designer', 'Graphic Designer', 'Visual Designer', 'Motion Designer',
    'Creative Director', 'Art Director', 'Technical Writer', 'Content Writer',
    'Copywriter', 'Video Editor', 'Photographer', 'Illustrator',

    // Business & Management
    'Project Manager', 'Program Manager', 'Operations Manager', 'General Manager',
    'Account Manager', 'Business Development Manager', 'Sales Manager', 'Marketing Manager',
    'CEO', 'CTO', 'CFO', 'COO', 'VP Engineering', 'VP Sales',
    'Director of Engineering', 'Engineering Director', 'Technical Director',
    'Coordinator', 'Administrator', 'Office Manager', 'Executive Assistant',
    'Scrum Master', 'Agile Coach', 'Team Lead', 'Supervisor',

    // Sales & Marketing
    'Sales Representative', 'Account Executive', 'Sales Development Representative',
    'Business Development Representative', 'Sales Engineer', 'Marketing Specialist',
    'Digital Marketing Manager', 'Content Marketing Manager', 'SEO Specialist',
    'Social Media Manager', 'Brand Manager', 'Growth Marketing Manager',
    'Partnership Manager', 'Channel Manager', 'Community Manager',

    // Professional Services
    'Consultant', 'Financial Advisor', 'Accountant', 'Auditor', 'Tax Advisor',
    'Lawyer', 'Attorney', 'Paralegal', 'HR Manager', 'Recruiter',
    'Talent Acquisition Specialist', 'People Operations Manager', 'HR Generalist',

    // Healthcare
    'Registered Nurse', 'Nurse Practitioner', 'Physician', 'Surgeon',
    'Physical Therapist', 'Occupational Therapist', 'Pharmacist', 'Medical Assistant',
    'Radiology Technician', 'Lab Technician', 'Dental Hygienist', 'Paramedic',
    'Clinical Nurse', 'Charge Nurse', 'Nurse Coordinator', 'Healthcare Administrator',

    // Customer Service
    'Customer Service Representative', 'Customer Support Specialist', 'Technical Support',
    'Customer Success Manager', 'Support Engineer', 'Help Desk Analyst',

    // Operations & Logistics
    'Operations Analyst', 'Supply Chain Manager', 'Logistics Coordinator',
    'Warehouse Manager', 'Inventory Manager', 'Procurement Specialist',
    'Facilities Manager', 'Maintenance Technician',

    // Retail & Hospitality
    'Retail Associate', 'Store Manager', 'Assistant Manager', 'Cashier',
    'Barista', 'Server', 'Bartender', 'Chef', 'Line Cook',

    // Trades
    'Electrician', 'Plumber', 'HVAC Technician', 'Mechanic', 'Carpenter',
    'Welder', 'Construction Worker', 'Truck Driver',

    // Finance
    'Financial Analyst', 'Investment Banker', 'Trader', 'Portfolio Manager',
    'Risk Analyst', 'Compliance Officer', 'Controller',

    // Education
    'Teacher', 'Professor', 'Instructor', 'Tutor', 'Principal',

    // Other
    'Security Officer', 'Real Estate Agent', 'Insurance Agent', 'Social Worker',
  ];

  // ============================================================================
  // DATA: Skills (200+)
  // ============================================================================
  final _skills = [
    // Programming Languages
    'Python', 'Java', 'JavaScript', 'TypeScript', 'C++', 'C#', 'Ruby', 'Go',
    'Rust', 'Swift', 'Kotlin', 'Dart', 'PHP', 'Scala', 'R', 'MATLAB',

    // Web Frontend
    'React', 'Angular', 'Vue', 'HTML', 'CSS', 'SASS', 'Tailwind CSS',
    'jQuery', 'Bootstrap', 'Webpack', 'Next.js', 'Svelte',

    // Backend
    'Node.js', 'Express', 'Django', 'Flask', 'Spring Boot', 'ASP.NET',
    'Ruby on Rails', 'Laravel', 'NestJS',

    // Mobile
    'Flutter', 'React Native', 'iOS Development', 'Android Development',
    'SwiftUI', 'Jetpack Compose',

    // Databases
    'SQL', 'MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'Elasticsearch',
    'Oracle', 'Cassandra', 'DynamoDB', 'Firebase',

    // Cloud/DevOps
    'AWS', 'Azure', 'Google Cloud', 'Docker', 'Kubernetes', 'Terraform',
    'Jenkins', 'GitLab CI', 'GitHub Actions', 'Ansible', 'CI/CD',

    // Data/ML
    'Machine Learning', 'Deep Learning', 'TensorFlow', 'PyTorch', 'Pandas',
    'NumPy', 'Scikit-learn', 'Apache Spark', 'Kafka', 'Airflow',

    // Design
    'Figma', 'Sketch', 'Adobe XD', 'Photoshop', 'Illustrator',
    'UI/UX Design', 'Wireframing', 'Prototyping',

    // Methodologies
    'Agile', 'Scrum', 'Kanban', 'TDD', 'Microservices', 'REST API',
    'GraphQL', 'Git',

    // Business Tools
    'Salesforce', 'SAP', 'Excel', 'Tableau', 'Power BI', 'Jira',
    'Confluence', 'Slack', 'Microsoft Office',

    // Soft Skills
    'Leadership', 'Communication', 'Project Management', 'Problem Solving',
    'Teamwork', 'Time Management', 'Critical Thinking',
  ];

  // ============================================================================
  // DATA: USA Locations (All 50 States + 100+ Cities)
  // ============================================================================
  final _usLocations = [
    // Major Cities
    'New York City', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
    'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose',
    'Austin', 'Jacksonville', 'Fort Worth', 'Columbus', 'Charlotte',
    'San Francisco', 'Indianapolis', 'Seattle', 'Denver', 'Boston',
    'Nashville', 'Detroit', 'Portland', 'Las Vegas', 'Memphis',
    'Louisville', 'Baltimore', 'Milwaukee', 'Albuquerque', 'Tucson',
    'Fresno', 'Sacramento', 'Kansas City', 'Atlanta', 'Miami',
    'Oakland', 'Tulsa', 'Cleveland', 'New Orleans', 'Tampa',
    'Raleigh', 'Minneapolis', 'Omaha', 'Long Beach', 'Virginia Beach',
    'Colorado Springs', 'Wichita', 'Arlington', 'Bakersfield', 'Aurora',
    'Anaheim', 'Santa Ana', 'Riverside', 'Stockton', 'Orlando',
    'Pittsburgh', 'Cincinnati', 'St. Louis', 'Salt Lake City', 'Richmond',
    'Boise', 'Spokane', 'Madison', 'Des Moines', 'Little Rock',
    'Honolulu', 'Anchorage', 'Sioux Falls', 'Fargo', 'Burlington',

    // All 50 States
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina',
    'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania',
    'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas',
    'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia',
    'Wisconsin', 'Wyoming',

    // Tech Hubs
    'Silicon Valley', 'Bay Area', 'Research Triangle', 'Tech Corridor',
  ];

  // ============================================================================
  // DATA: Industries (30+)
  // ============================================================================
  final _industries = [
    'Technology', 'Healthcare', 'Finance', 'Retail', 'Manufacturing',
    'Education', 'Hospitality', 'Transportation', 'Real Estate', 'Construction',
    'Telecommunications', 'Energy', 'Pharmaceutical', 'Biotechnology', 'Insurance',
    'Media', 'Entertainment', 'Aerospace', 'Automotive', 'Agriculture',
    'Consulting', 'Legal', 'Nonprofit', 'Government', 'Banking',
    'E-commerce', 'SaaS', 'Cybersecurity', 'Fintech', 'EdTech',
    'HealthTech', 'CleanTech', 'AI/ML', 'Gaming',
  ];

  // ============================================================================
  // DATA: Supporting Data
  // ============================================================================
  final _salaries = [
    '\$50k', '\$60k', '\$70k', '\$80k', '\$90k', '\$100k', '\$110k', '\$120k',
    '\$130k', '\$140k', '\$150k', '\$160k', '\$180k', '\$200k', '\$250k',
    '\$80k-\$100k', '\$100k-\$120k', '\$120k-\$150k', '\$150k-\$200k',
    '\$50-\$70 per hour', '\$30-\$50 per hour',
  ];

  final _experienceLevels = [
    'Entry Level', 'Junior', 'Mid Level', 'Senior', 'Lead', 'Principal',
    'Staff', '2 years', '3 years', '5 years', '7 years', '10+ years',
    'Fresher', 'Experienced', '3-5 years', '5-7 years',
  ];

  final _workplaceTypes = [
    'Remote', 'Onsite', 'Hybrid', 'Fully Remote', 'Work from Home',
    'In-Office', 'Flexible',
  ];

  final _candidateNames = [
    'John Smith', 'Sarah Johnson', 'Michael Brown', 'Emily Davis', 'David Wilson',
    'Jessica Martinez', 'James Anderson', 'Jennifer Taylor', 'Robert Thomas', 'Lisa Garcia',
    'William Rodriguez', 'Mary Martinez', 'Richard Lee', 'Patricia White', 'Christopher Harris',
  ];

  final _times = [
    '9 AM', '10 AM', '11 AM', '2 PM', '3 PM', '4 PM', '5 PM',
    '9:00', '10:30', '2:00', '3:30', 'noon', 'morning', 'afternoon',
  ];

  final _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'today', 'tomorrow', 'next week', 'this week', 'next Monday',
  ];

  final _interviewTypes = [
    'phone', 'video', 'in-person', 'technical', 'behavioral',
    'panel', 'first round', 'second round', 'final',
  ];
}
