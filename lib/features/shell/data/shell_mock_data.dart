import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';

class ProviderCategoryItem {
  const ProviderCategoryItem({
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

class MessageThreadItem {
  const MessageThreadItem({
    required this.contact,
    this.lastBody,
    this.lastAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final CareTeamMember contact;
  final String? lastBody;
  final DateTime? lastAt;
  final int unreadCount;
  final bool isOnline;
}

class MessageGroupItem {
  const MessageGroupItem({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    this.lastBody,
    this.lastAt,
  });

  final String id;
  final String name;
  final List<CareTeamMember> members;
  final DateTime createdAt;
  final String? lastBody;
  final DateTime? lastAt;
}

class ShellMockData {
  ShellMockData._();

  static const quickCaseIdeas = [
    'Negotiate a hospital bill',
    'Find an in-network specialist',
    'Understand my benefits',
    'Appeal a denied claim',
  ];

  static const requestTypeLabels = {
    'bill_negotiation': 'Bill Negotiation',
    'provider_search': 'Provider Search',
    'insurance_navigation': 'Insurance Navigation',
    'benefit_navigation': 'Benefit Navigation',
    'procedure_cost': 'Procedure Cost',
    'care_coordination': 'Care Coordination',
    'claims_assistance': 'Claims Assistance',
    'appeals_grievances': 'Appeals & Grievances',
    'other': 'Something else',
  };

  static String requestTypeLabel(String type) =>
      requestTypeLabels[type] ?? type;

  static String formatCaseWhen(DateTime iso) {
    final diff = DateTime.now().difference(iso);
    const day = Duration(days: 1);
    if (diff < day) return 'Today';
    if (diff < day * 2) return 'Yesterday';
    if (diff < day * 7) return '${diff.inDays}d ago';
    return formatWhen(iso);
  }

  static List<CareRequest> allRequests() => HomeMockData.requests();

  static int _hashId(String id) {
    int h = 0;
    for (int i = 0; i < id.length; i++) {
      h = (h * 31 + id.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return h.abs();
  }

  static List<MessageThreadItem> messageThreads({
    required List<CareTeamMember> careTeam,
  }) {
    return careTeam
        .map((c) {
          final msgs = HomeMockData.messagesByContact[c.id] ?? [];
          final last = msgs.isNotEmpty ? msgs.last : null;
          final h = _hashId(c.id);
          return MessageThreadItem(
            contact: c,
            lastBody: last?.body,
            lastAt: last?.createdAt,
            isOnline: h % 2 == 0,
            unreadCount: h % 7 == 0 ? (h % 25) + 1 : 0,
          );
        })
        .where((t) => t.lastBody != null)
        .toList();
  }

  static List<MessageGroupItem> messageGroups({
    required List<CareTeamMember> careTeam,
  }) {
    if (careTeam.isEmpty) {
      return const [];
    }

    final members = careTeam.take(4).toList();
    return [
      MessageGroupItem(
        id: 'group-1',
        name: 'Alex Care Team',
        members: members,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lastBody: 'Welcome to your care group!',
        lastAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }

  static const providerCategories = <ProviderCategoryItem>[
    ProviderCategoryItem(
      slug: 'pediatrics',
      label: 'Pediatrics',
      blurb: 'Kids and teen care',
      icon: LucideIcons.baby,
      iconBackground: Color(0x1A009E9E),
      iconColor: Color(0xFF009E9E),
    ),
    ProviderCategoryItem(
      slug: 'womens-health',
      label: "Women's Health",
      blurb: 'OB/GYN and midwifery',
      icon: LucideIcons.heartPulse,
      iconBackground: Color(0x1AE86F33),
      iconColor: Color(0xFFE86F33),
    ),
    ProviderCategoryItem(
      slug: 'urgent-care',
      label: 'Urgent Care',
      blurb: 'Same-day visits',
      icon: LucideIcons.activity,
      iconBackground: Color(0x26E86F33),
      iconColor: Color(0xFFE86F33),
    ),
    ProviderCategoryItem(
      slug: 'er',
      label: 'Emergency Room',
      blurb: '24/7 emergencies',
      icon: LucideIcons.siren,
      iconBackground: Color(0x1AE53935),
      iconColor: Color(0xFFE53935),
    ),
    ProviderCategoryItem(
      slug: 'specialist',
      label: 'Specialist',
      blurb: 'Cardiology, derm & more',
      icon: LucideIcons.userPlus,
      iconBackground: Color(0x1A2E9E6E),
      iconColor: Color(0xFF2E9E6E),
    ),
    ProviderCategoryItem(
      slug: 'mental-health',
      label: 'Mental Health',
      blurb: 'Therapy & psychiatry',
      icon: LucideIcons.brain,
      iconBackground: Color(0x26009E9E),
      iconColor: Color(0xFF009E9E),
    ),
    ProviderCategoryItem(
      slug: 'hearing',
      label: 'Hearing & Audiology',
      blurb: 'Hearing tests & aids',
      icon: LucideIcons.ear,
      iconBackground: Color(0x26E86F33),
      iconColor: Color(0xFFE86F33),
    ),
    ProviderCategoryItem(
      slug: 'physical-therapy',
      label: 'Physical Therapy',
      blurb: 'PT, OT & rehab',
      icon: LucideIcons.dumbbell,
      iconBackground: Color(0x1AE86F33),
      iconColor: Color(0xFFE86F33),
    ),
    ProviderCategoryItem(
      slug: 'sleep-medicine',
      label: 'Sleep Medicine',
      blurb: 'Sleep studies & CPAP',
      icon: LucideIcons.moon,
      iconBackground: Color(0x262E9E6E),
      iconColor: Color(0xFF2E9E6E),
    ),
    ProviderCategoryItem(
      slug: 'home-health',
      label: 'Home Health & DME',
      blurb: 'Care at home & equipment',
      icon: LucideIcons.home,
      iconBackground: Color(0x1A009E9E),
      iconColor: Color(0xFF009E9E),
    ),
  ];
}
