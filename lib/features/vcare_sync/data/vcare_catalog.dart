import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VCareRouteAction {
  const VCareRouteAction({
    required this.label,
    required this.routeName,
    this.pathParameters = const {},
  });

  final String label;
  final String routeName;
  final Map<String, String> pathParameters;
}

class VCareProviderCategory {
  const VCareProviderCategory({
    required this.slug,
    required this.label,
    required this.blurb,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String slug;
  final String label;
  final String blurb;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}

class VCareProvider {
  const VCareProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.category,
    required this.address,
    required this.city,
    required this.distanceMi,
    required this.phone,
    required this.hours,
    required this.inNetwork,
    required this.acceptingNew,
    required this.rating,
  });

  final String id;
  final String name;
  final String specialty;
  final String category;
  final String address;
  final String city;
  final double distanceMi;
  final String phone;
  final String hours;
  final bool inNetwork;
  final bool acceptingNew;
  final double rating;
}

class VCareProcedure {
  const VCareProcedure({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.costLow,
    required this.costAvg,
    required this.costHigh,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final int costLow;
  final int costAvg;
  final int costHigh;
}

class VCareNotificationItem {
  const VCareNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;
}

class VCareDocumentItem {
  const VCareDocumentItem({
    required this.name,
    required this.kind,
    required this.sourceLabel,
    required this.sizeLabel,
    required this.createdAt,
  });

  final String name;
  final String kind;
  final String sourceLabel;
  final String sizeLabel;
  final DateTime createdAt;
}

class VCareFaqItem {
  const VCareFaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class VCareRequestType {
  const VCareRequestType({
    required this.value,
    required this.label,
    required this.description,
  });

  final String value;
  final String label;
  final String description;
}

class VCareCatalog {
  VCareCatalog._();

  static const providerCategories = <VCareProviderCategory>[
    VCareProviderCategory(
      slug: 'pediatrics',
      label: 'Pediatrics',
      blurb: 'Kids and teen care',
      icon: LucideIcons.baby,
      iconBackground: Color(0x1A009E9E),
      iconColor: Color(0xFF009E9E),
    ),
    VCareProviderCategory(
      slug: 'womens-health',
      label: "Women's Health",
      blurb: 'OB/GYN and midwifery',
      icon: LucideIcons.heartPulse,
      iconBackground: Color(0x1AE86F33),
      iconColor: Color(0xFFE86F33),
    ),
    VCareProviderCategory(
      slug: 'urgent-care',
      label: 'Urgent Care',
      blurb: 'Same-day visits',
      icon: LucideIcons.activity,
      iconBackground: Color(0x26E86F33),
      iconColor: Color(0xFFE86F33),
    ),
    VCareProviderCategory(
      slug: 'er',
      label: 'Emergency Room',
      blurb: '24/7 emergencies',
      icon: LucideIcons.siren,
      iconBackground: Color(0x1AE53935),
      iconColor: Color(0xFFE53935),
    ),
    VCareProviderCategory(
      slug: 'specialist',
      label: 'Specialist',
      blurb: 'Cardiology, derm & more',
      icon: LucideIcons.userPlus,
      iconBackground: Color(0x1A2E9E6E),
      iconColor: Color(0xFF2E9E6E),
    ),
    VCareProviderCategory(
      slug: 'mental-health',
      label: 'Mental Health',
      blurb: 'Therapy & psychiatry',
      icon: LucideIcons.brain,
      iconBackground: Color(0x26009E9E),
      iconColor: Color(0xFF009E9E),
    ),
    VCareProviderCategory(
      slug: 'hearing',
      label: 'Hearing & Audiology',
      blurb: 'Hearing tests & aids',
      icon: LucideIcons.ear,
      iconBackground: Color(0x26E86F33),
      iconColor: Color(0xFFE86F33),
    ),
    VCareProviderCategory(
      slug: 'physical-therapy',
      label: 'Physical Therapy',
      blurb: 'PT, OT & rehab',
      icon: LucideIcons.dumbbell,
      iconBackground: Color(0x1AE86F33),
      iconColor: Color(0xFFE86F33),
    ),
    VCareProviderCategory(
      slug: 'sleep-medicine',
      label: 'Sleep Medicine',
      blurb: 'Sleep studies & CPAP',
      icon: LucideIcons.moon,
      iconBackground: Color(0x262E9E6E),
      iconColor: Color(0xFF2E9E6E),
    ),
    VCareProviderCategory(
      slug: 'home-health',
      label: 'Home Health & DME',
      blurb: 'Care at home & equipment',
      icon: LucideIcons.home,
      iconBackground: Color(0x1A009E9E),
      iconColor: Color(0xFF009E9E),
    ),
  ];

  static const providers = <VCareProvider>[
    VCareProvider(
      id: 'p1',
      name: 'Dr. Maya Patel, MD',
      specialty: 'Family Medicine',
      category: 'specialist',
      address: '120 Market St, Suite 400',
      city: 'San Francisco, CA',
      distanceMi: 1.2,
      phone: '(415) 555-0111',
      hours: 'Mon–Fri 8am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.8,
    ),
    VCareProvider(
      id: 'p2',
      name: 'Bay Area Cardiology',
      specialty: 'Cardiology',
      category: 'specialist',
      address: '455 Sutter St',
      city: 'San Francisco, CA',
      distanceMi: 2.4,
      phone: '(415) 555-0122',
      hours: 'Mon–Fri 9am–6pm',
      inNetwork: true,
      acceptingNew: false,
      rating: 4.6,
    ),
    VCareProvider(
      id: 'p3',
      name: 'Dr. Jonah Kim, MD',
      specialty: 'Pediatrics',
      category: 'pediatrics',
      address: '78 Geary Blvd',
      city: 'San Francisco, CA',
      distanceMi: 0.8,
      phone: '(415) 555-0133',
      hours: 'Mon–Sat 8am–6pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.9,
    ),
    VCareProvider(
      id: 'p4',
      name: 'Mission Dermatology',
      specialty: 'Dermatology',
      category: 'specialist',
      address: '2200 Mission St',
      city: 'San Francisco, CA',
      distanceMi: 3.1,
      phone: '(415) 555-0144',
      hours: 'Tue–Sat 9am–5pm',
      inNetwork: false,
      acceptingNew: true,
      rating: 4.4,
    ),
    VCareProvider(
      id: 'p9',
      name: 'MinuteCare Urgent Clinic',
      specialty: 'Urgent Care',
      category: 'urgent-care',
      address: '1200 Polk St',
      city: 'San Francisco, CA',
      distanceMi: 1.0,
      phone: '(415) 555-0199',
      hours: 'Daily 8am–10pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.5,
    ),
    VCareProvider(
      id: 'p10',
      name: 'BayHealth Urgent Care',
      specialty: 'Urgent Care',
      category: 'urgent-care',
      address: '3401 California St',
      city: 'San Francisco, CA',
      distanceMi: 2.6,
      phone: '(415) 555-0210',
      hours: 'Daily 7am–11pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.3,
    ),
    VCareProvider(
      id: 'p11',
      name: 'SF General ER',
      specialty: 'Emergency Room',
      category: 'er',
      address: '1001 Potrero Ave',
      city: 'San Francisco, CA',
      distanceMi: 3.4,
      phone: '(415) 555-0220',
      hours: '24/7',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.2,
    ),
    VCareProvider(
      id: 'p12',
      name: 'CPMC Emergency Department',
      specialty: 'Emergency Room',
      category: 'er',
      address: '1101 Van Ness Ave',
      city: 'San Francisco, CA',
      distanceMi: 1.9,
      phone: '(415) 555-0221',
      hours: '24/7',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.4,
    ),
    VCareProvider(
      id: 'p18',
      name: 'Dr. Lena Park, LCSW',
      specialty: 'Therapy & Counseling',
      category: 'mental-health',
      address: '98 Battery St',
      city: 'San Francisco, CA',
      distanceMi: 1.1,
      phone: '(415) 555-0250',
      hours: 'Mon–Fri 9am–7pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.9,
    ),
    VCareProvider(
      id: 'p19',
      name: 'Mindful Bay Psychiatry',
      specialty: 'Psychiatry',
      category: 'mental-health',
      address: '455 Brannan St',
      city: 'San Francisco, CA',
      distanceMi: 2.2,
      phone: '(415) 555-0251',
      hours: 'Mon–Fri 8am–6pm',
      inNetwork: true,
      acceptingNew: false,
      rating: 4.6,
    ),
    VCareProvider(
      id: 'p23',
      name: 'Bay Kids Pediatrics',
      specialty: 'Pediatric Primary Care',
      category: 'pediatrics',
      address: '600 California St, Suite 200',
      city: 'San Francisco, CA',
      distanceMi: 1.3,
      phone: '(415) 555-0271',
      hours: 'Mon–Fri 8am–6pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.9,
    ),
    VCareProvider(
      id: 'p24',
      name: 'Little Star Pediatric Clinic',
      specialty: 'Pediatrics & Adolescent Medicine',
      category: 'pediatrics',
      address: '1825 Union St',
      city: 'San Francisco, CA',
      distanceMi: 2.1,
      phone: '(415) 555-0272',
      hours: 'Mon–Sat 8am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.7,
    ),
    VCareProvider(
      id: 'p25',
      name: "Pacific Women's Health",
      specialty: 'OB/GYN',
      category: 'womens-health',
      address: '1375 Sutter St',
      city: 'San Francisco, CA',
      distanceMi: 1.5,
      phone: '(415) 555-0273',
      hours: 'Mon–Fri 8am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.8,
    ),
    VCareProvider(
      id: 'p26',
      name: 'Embarcadero Midwifery & Birth',
      specialty: "Midwifery & Women's Health",
      category: 'womens-health',
      address: '88 Howard St',
      city: 'San Francisco, CA',
      distanceMi: 0.9,
      phone: '(415) 555-0274',
      hours: 'Mon–Sun 9am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.9,
    ),
    VCareProvider(
      id: 'p27',
      name: 'Golden Gate Audiology',
      specialty: 'Hearing & Balance',
      category: 'hearing',
      address: '2100 Webster St',
      city: 'San Francisco, CA',
      distanceMi: 2.0,
      phone: '(415) 555-0275',
      hours: 'Tue–Sat 9am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.6,
    ),
    VCareProvider(
      id: 'p28',
      name: 'SF Hearing Center',
      specialty: 'Audiology & Hearing Aids',
      category: 'hearing',
      address: '450 Sutter St',
      city: 'San Francisco, CA',
      distanceMi: 1.1,
      phone: '(415) 555-0276',
      hours: 'Mon–Fri 9am–6pm',
      inNetwork: false,
      acceptingNew: true,
      rating: 4.4,
    ),
    VCareProvider(
      id: 'p29',
      name: 'Embarcadero PT & Sports Rehab',
      specialty: 'Physical Therapy',
      category: 'physical-therapy',
      address: '77 Battery St',
      city: 'San Francisco, CA',
      distanceMi: 1.0,
      phone: '(415) 555-0277',
      hours: 'Mon–Fri 7am–7pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.8,
    ),
    VCareProvider(
      id: 'p30',
      name: 'Mission Valley Orthopedic Rehab',
      specialty: 'PT & Occupational Therapy',
      category: 'physical-therapy',
      address: '2500 Mission St',
      city: 'San Francisco, CA',
      distanceMi: 3.0,
      phone: '(415) 555-0278',
      hours: 'Mon–Sat 8am–6pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.5,
    ),
    VCareProvider(
      id: 'p31',
      name: 'Bay Sleep Medicine Center',
      specialty: 'Sleep Medicine & CPAP',
      category: 'sleep-medicine',
      address: '3838 California St',
      city: 'San Francisco, CA',
      distanceMi: 2.7,
      phone: '(415) 555-0279',
      hours: 'Mon–Fri 8am–5pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.6,
    ),
    VCareProvider(
      id: 'p32',
      name: 'Pacific Heights Sleep Clinic',
      specialty: 'Sleep Studies',
      category: 'sleep-medicine',
      address: '1998 Union St',
      city: 'San Francisco, CA',
      distanceMi: 1.8,
      phone: '(415) 555-0280',
      hours: 'Mon–Fri 7am–4pm',
      inNetwork: true,
      acceptingNew: false,
      rating: 4.5,
    ),
    VCareProvider(
      id: 'p33',
      name: 'Lighthouse Home Health',
      specialty: 'Skilled Nursing at Home',
      category: 'home-health',
      address: 'Serving SF Bay Area',
      city: 'San Francisco, CA',
      distanceMi: 0,
      phone: '(415) 555-0281',
      hours: '24/7 triage',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.7,
    ),
    VCareProvider(
      id: 'p34',
      name: 'Bay Area DME & Medical Supply',
      specialty: 'DME & Home Equipment',
      category: 'home-health',
      address: '1600 Bryant St',
      city: 'San Francisco, CA',
      distanceMi: 2.3,
      phone: '(415) 555-0282',
      hours: 'Mon–Fri 8am–6pm',
      inNetwork: true,
      acceptingNew: true,
      rating: 4.3,
    ),
  ];

  static const procedures = <VCareProcedure>[
    VCareProcedure(
      id: 'pr1',
      name: 'MRI – Lower Back',
      category: 'Imaging',
      description:
          'Magnetic resonance imaging of the lumbar spine, no contrast.',
      costLow: 450,
      costAvg: 1100,
      costHigh: 2800,
    ),
    VCareProcedure(
      id: 'pr2',
      name: 'Routine Dental Cleaning',
      category: 'Dental',
      description: 'Adult prophylaxis, includes exam and polish.',
      costLow: 75,
      costAvg: 145,
      costHigh: 280,
    ),
    VCareProcedure(
      id: 'pr3',
      name: 'Colonoscopy (Screening)',
      category: 'Preventive',
      description: 'Standard screening colonoscopy, age 45+.',
      costLow: 1100,
      costAvg: 2400,
      costHigh: 5500,
    ),
    VCareProcedure(
      id: 'pr4',
      name: 'Knee Arthroscopy',
      category: 'Surgery',
      description: 'Outpatient diagnostic & repair procedure.',
      costLow: 4200,
      costAvg: 7800,
      costHigh: 14000,
    ),
    VCareProcedure(
      id: 'pr5',
      name: 'Annual Physical Exam',
      category: 'Preventive',
      description: 'Comprehensive wellness visit, often \$0 in-network.',
      costLow: 0,
      costAvg: 180,
      costHigh: 350,
    ),
    VCareProcedure(
      id: 'pr6',
      name: 'Tooth Filling (Composite)',
      category: 'Dental',
      description: 'Single-surface posterior composite filling.',
      costLow: 130,
      costAvg: 220,
      costHigh: 380,
    ),
    VCareProcedure(
      id: 'pr7',
      name: 'Therapy Session (60 min)',
      category: 'Mental Health',
      description: 'Individual outpatient psychotherapy.',
      costLow: 90,
      costAvg: 175,
      costHigh: 300,
    ),
  ];

  static final notifications = <VCareNotificationItem>[
    VCareNotificationItem(
      id: 'n1',
      title: 'Savannah sent you a message',
      body: 'I scheduled your follow-up with Dr. Patel...',
      type: 'message',
      read: false,
      createdAt: DateTime.parse('2026-05-02T14:21:00Z'),
    ),
    VCareNotificationItem(
      id: 'n2',
      title: 'Annual physical reminder',
      body: "It's been 11 months since your last wellness visit.",
      type: 'reminder',
      read: false,
      createdAt: DateTime.parse('2026-05-01T09:00:00Z'),
    ),
    VCareNotificationItem(
      id: 'n3',
      title: 'New tip: 5 questions to ask before any procedure',
      body: "An advocate's checklist to avoid surprise bills.",
      type: 'tip',
      read: true,
      createdAt: DateTime.parse('2026-05-01T08:00:00Z'),
    ),
    VCareNotificationItem(
      id: 'n4',
      title: 'Bill resolved',
      body: 'City Imaging \$480 charge appealed and removed.',
      type: 'billing',
      read: true,
      createdAt: DateTime.parse('2026-04-29T16:30:00Z'),
    ),
  ];

  static final documents = <VCareDocumentItem>[
    VCareDocumentItem(
      name: 'City Imaging itemized bill.pdf',
      kind: 'Files',
      sourceLabel: 'Request',
      sizeLabel: '428 KB',
      createdAt: DateTime.parse('2026-05-01'),
    ),
    VCareDocumentItem(
      name: 'Insurance card front.jpg',
      kind: 'Images',
      sourceLabel: 'Digital ID Card',
      sizeLabel: '1.4 MB',
      createdAt: DateTime.parse('2026-04-28'),
    ),
    VCareDocumentItem(
      name: 'Voice note for advocate.m4a',
      kind: 'Voice',
      sourceLabel: 'Request',
      sizeLabel: '820 KB',
      createdAt: DateTime.parse('2026-04-25'),
    ),
  ];

  static const faqs = <VCareFaqItem>[
    VCareFaqItem(
      question: 'How quickly will my advocate respond?',
      answer:
          'Most requests get a first response within 1 business day. Urgent matters are handled faster through the 24/7 line.',
    ),
    VCareFaqItem(
      question: 'What can VCare help me with?',
      answer:
          'Insurance navigation, benefits questions, denied-claim appeals, in-network provider search, scheduling, and decoding bills.',
    ),
    VCareFaqItem(
      question: 'Is my information private?',
      answer:
          'Yes. Your data is encrypted in transit and at rest. We only share with providers when you authorize us.',
    ),
    VCareFaqItem(
      question: 'Can I add family members to my account?',
      answer:
          'Yes. Go to Profile → My Family → Add family member to manage care on their behalf.',
    ),
    VCareFaqItem(
      question: 'How do I update my insurance card?',
      answer:
          'Open Digital ID Card from the home screen, tap your card, then upload new front/back photos.',
    ),
  ];

  static const requestTypes = <VCareRequestType>[
    VCareRequestType(
      value: 'insurance_navigation',
      label: 'Insurance Navigation',
      description: 'Find or understand a health insurance policy',
    ),
    VCareRequestType(
      value: 'benefit_navigation',
      label: 'Benefit Navigation',
      description: 'Decode coverage, copays, deductibles, and benefits',
    ),
    VCareRequestType(
      value: 'provider_search',
      label: 'Provider Search',
      description: 'Find a doctor, specialist, or facility',
    ),
    VCareRequestType(
      value: 'procedure_cost',
      label: 'Procedure Cost',
      description: 'Compare prices for a procedure or treatment',
    ),
    VCareRequestType(
      value: 'care_coordination',
      label: 'Care Coordination',
      description: 'Coordinate appointments and records across providers',
    ),
    VCareRequestType(
      value: 'claims_assistance',
      label: 'Claims Assistance',
      description: 'File a claim, fix a billing error, or understand a bill',
    ),
    VCareRequestType(
      value: 'bill_negotiation',
      label: 'Bill Negotiation',
      description: 'Reduce or settle a medical bill',
    ),
    VCareRequestType(
      value: 'appeals_grievances',
      label: 'Appeals & Grievances',
      description: 'Appeal a denied claim or file a grievance',
    ),
    VCareRequestType(
      value: 'other',
      label: 'Something else',
      description: 'Any other healthcare question',
    ),
  ];

  static VCareProviderCategory? categoryBySlug(String slug) {
    for (final category in providerCategories) {
      if (category.slug == slug) return category;
    }
    return null;
  }

  static VCareProvider? providerById(String id) {
    for (final provider in providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  static VCareProcedure? procedureById(String id) {
    for (final procedure in procedures) {
      if (procedure.id == id) return procedure;
    }
    return null;
  }
}
