import 'package:vcare_admin/features/find_care/data/find_care_mock_data.dart';

import 'home_models.dart';
import 'vcare_assets.dart';

class HomeMockData {
  HomeMockData._();

  static const member = HomeMember(
    fullName: 'Liam Smith',
    memberId: 'VC-8472-1903',
    plan: 'VCare Family Plus',
    photoAsset: VCareAssets.member,
    email: 'liam.smith@example.com',
    phone: '(415) 555-0142',
    dobLabel: '04/18/1990',
  );

  static const profile = HomeProfile(
    fullName: 'Liam Smith',
    photoUrl: VCareAssets.member,
  );

  static const careTeam = <CareTeamMember>[
    CareTeamMember(
      id: 'ct1',
      name: 'Carmel Hohmann',
      role: CareTeamRole.advocate,
      photoAsset: VCareAssets.advocate,
      bio:
          '12+ years helping families navigate complex care decisions, billing disputes, and specialist referrals.',
      email: 'savannah@vcare.com',
      phone: '(415) 555-0188',
    ),
    CareTeamMember(
      id: 'ct2',
      name: 'Keith Holland',
      role: CareTeamRole.agent,
      photoAsset: VCareAssets.agent,
      bio:
          'Helps you understand benefits, deductibles, and find the right plan for your family.',
      email: 'keith@vcare.com',
      phone: '(415) 555-0144',
    ),
    CareTeamMember(
      id: 'ct4',
      name: 'Northwind Logistics',
      role: CareTeamRole.employer,
      logoText: 'NL',
      bio:
          "Your employer's HR benefits team. Reach out for enrollment, life events, and FSA/HSA questions.",
      email: 'benefits@northwind.com',
      phone: '(415) 555-0120',
      website: 'https://benefits.northwind.com',
      address: '200 Market St, San Francisco, CA 94105',
      hours: 'Mon–Fri, 8am–5pm PT',
      groupNumber: 'GRP-22841',
    ),
    CareTeamMember(
      id: 'ct5',
      name: 'BlueShield National',
      role: CareTeamRole.insurance,
      logoText: 'BS',
      bio:
          "Your insurance carrier. Contact for claims status, coverage details, and prior authorizations.",
      email: 'members@blueshieldnational.com',
      phone: '1-800-555-0199',
      website: 'https://blueshieldnational.com/members',
      hours: '24/7 member support',
      policyNumber: 'VC-8472-1903',
      groupNumber: 'GRP-22841',
    ),
    CareTeamMember(
      id: 'ct6',
      name: 'Dr. Maya Patel',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=47',
      bio:
          'Primary care physician — annual visits, preventive care, and chronic conditions.',
      email: 'm.patel@bayclinic.com',
      phone: '(415) 555-0211',
    ),
    CareTeamMember(
      id: 'ct7',
      name: 'Dr. Jonah Kim',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=12',
      bio: 'Pediatric care for kids ages 0–18.',
      email: 'j.kim@baykids.com',
      phone: '(415) 555-0212',
    ),
    CareTeamMember(
      id: 'ct8',
      name: 'Dr. Lena Park',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=32',
      bio: 'Individual therapy and stress management.',
      email: 'l.park@mindful.com',
      phone: '(415) 555-0213',
    ),
    CareTeamMember(
      id: 'ct9',
      name: 'Sofia Alvarez',
      role: CareTeamRole.advocate,
      photoUrl: 'https://i.pravatar.cc/200?img=49',
      bio: 'Specializes in claim appeals and surprise-bill disputes.',
      email: 'sofia@vcare.com',
      phone: '(415) 555-0214',
    ),
    CareTeamMember(
      id: 'ct10',
      name: 'Marcus Lee',
      role: CareTeamRole.agent,
      photoUrl: 'https://i.pravatar.cc/200?img=15',
      bio: 'Open enrollment guidance and plan comparisons.',
      email: 'marcus@vcare.com',
      phone: '(415) 555-0215',
    ),
    CareTeamMember(
      id: 'ct11',
      name: 'Dr. Priya Shah',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=44',
      bio: 'Medical and cosmetic dermatology.',
      email: 'p.shah@missionderm.com',
      phone: '(415) 555-0216',
    ),
    CareTeamMember(
      id: 'ct12',
      name: 'Dr. Aaron Brooks',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=33',
      bio: 'Adult cardiology and preventive heart health.',
      email: 'a.brooks@baycardio.com',
      phone: '(415) 555-0217',
    ),
    CareTeamMember(
      id: 'ct13',
      name: 'Nadia Okafor',
      role: CareTeamRole.advocate,
      photoUrl: 'https://i.pravatar.cc/200?img=45',
      bio: 'Coordinates appointments across multiple specialists.',
      email: 'nadia@vcare.com',
      phone: '(415) 555-0218',
    ),
    CareTeamMember(
      id: 'ct14',
      name: 'Dr. Hana Yamato',
      role: CareTeamRole.provider,
      photoUrl: 'https://i.pravatar.cc/200?img=48',
      bio: "Women's health, prenatal and routine care.",
      email: 'h.yamato@pacificwh.com',
      phone: '(415) 555-0219',
    ),
  ];

  static const favoriteProviderIds = FindCareMockData.favoriteProviderIds;

  static const providers = FindCareMockData.providers;

  static final messagesByContact = <String, List<ChatMessage>>{
    'ct1': [
      ChatMessage(
        id: 'm1',
        body:
            "Hi Alex! I scheduled your follow-up with Dr. Patel for next Thursday at 2pm. Does that work?",
        createdAt: DateTime.parse('2026-05-02T14:21:00Z'),
        sender: 'them',
      ),
      ChatMessage(
        id: 'm2',
        body: 'Perfect, thank you so much!',
        createdAt: DateTime.parse('2026-05-02T14:25:00Z'),
        sender: 'me',
      ),
      ChatMessage(
        id: 'm3',
        body:
            "Anytime. I also reviewed the bill from City Imaging — looks like a coding error. I'll handle the appeal.",
        createdAt: DateTime.parse('2026-05-02T14:26:00Z'),
        sender: 'them',
      ),
    ],
    'ct2': [
      ChatMessage(
        id: 'm4',
        body: 'Open enrollment starts Nov 1. Want to schedule a 15-min review?',
        createdAt: DateTime.parse('2026-04-28T09:00:00Z'),
        sender: 'them',
      ),
    ],
    'ct6': [
      ChatMessage(
        id: 'm6a',
        body:
            'Hi Alex — your lab results came back normal. We can chat at your next visit.',
        createdAt: DateTime.parse('2026-05-03T11:10:00Z'),
        sender: 'them',
      ),
      ChatMessage(
        id: 'm6b',
        body: 'Great to hear, thanks Dr. Patel!',
        createdAt: DateTime.parse('2026-05-03T11:25:00Z'),
        sender: 'me',
      ),
    ],
    'ct7': [
      ChatMessage(
        id: 'm7a',
        body:
            "Reminder: Maya's well-child visit is scheduled for Friday at 10am.",
        createdAt: DateTime.parse('2026-05-01T15:00:00Z'),
        sender: 'them',
      ),
    ],
    'ct8': [
      ChatMessage(
        id: 'm8a',
        body: "How did the breathing exercises go this week?",
        createdAt: DateTime.parse('2026-04-30T18:00:00Z'),
        sender: 'them',
      ),
    ],
    'ct9': [
      ChatMessage(
        id: 'm9a',
        body:
            "I filed the appeal for the City Imaging bill — usually 10–14 days for a response.",
        createdAt: DateTime.parse('2026-05-04T09:45:00Z'),
        sender: 'them',
      ),
    ],
    'ct10': [
      ChatMessage(
        id: 'm10a',
        body:
            "Want me to send a side-by-side of the two plans you're considering?",
        createdAt: DateTime.parse('2026-04-29T13:20:00Z'),
        sender: 'them',
      ),
    ],
    'ct11': [
      ChatMessage(
        id: 'm11a',
        body: "Your biopsy results are benign — no further action needed.",
        createdAt: DateTime.parse('2026-05-02T10:00:00Z'),
        sender: 'them',
      ),
    ],
  };

  static const notifications = <AppNotification>[
    AppNotification(read: false),
    AppNotification(read: false),
    AppNotification(read: true),
    AppNotification(read: true),
  ];

  static List<SavedProviderItem> savedProviders(List<String> favoriteIds) =>
      FindCareMockData.savedProviders(favoriteIds);

  static HomeViewData defaultView() {
    final favs = List<String>.from(favoriteProviderIds);
    return HomeViewData(
      profile: profile,
      member: member,
      careTeam: careTeam,
      savedProviders: savedProviders(favs),
      recentActivity: const [],
      unreadNotifications: notifications.where((n) => !n.read).length,
      favoriteProviderIds: favs,
    );
  }
}
