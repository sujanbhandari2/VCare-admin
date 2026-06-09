enum CareTeamRole { advocate, agent, provider, employer, insurance }

enum RequestStatus { newRequest, inReview, actionNeeded, resolved }

enum ActivityKind { request, message, transaction }

enum StatusBadgeVariant { primary, secondary, destructive, outline }

class HomeMember {
  const HomeMember({
    required this.fullName,
    required this.memberId,
    required this.plan,
    required this.photoAsset,
    required this.email,
    required this.phone,
    required this.dobLabel,
    this.groupNumber = 'GRP-22841',
    this.effectiveDate = 'Jan 1, 2026',
  });

  final String fullName;
  final String memberId;
  final String plan;
  final String photoAsset;
  final String email;
  final String phone;
  final String dobLabel;
  final String groupNumber;
  final String effectiveDate;
}

class HomeProfile {
  const HomeProfile({required this.fullName, required this.photoAsset});

  final String fullName;
  final String photoAsset;
}

class CareTeamMember {
  const CareTeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.photoAsset,
    this.photoUrl,
    this.logoText,
    this.bio,
    this.email,
    this.phone,
    this.website,
  });

  final String id;
  final String name;
  final CareTeamRole role;
  final String? photoAsset;
  final String? photoUrl;
  final String? logoText;
  final String? bio;
  final String? email;
  final String? phone;
  final String? website;

  String get roleLabel {
    switch (role) {
      case CareTeamRole.advocate:
        return 'Advocate';
      case CareTeamRole.agent:
        return 'Agent';
      case CareTeamRole.provider:
        return 'Provider';
      case CareTeamRole.employer:
        return 'Employer';
      case CareTeamRole.insurance:
        return 'Insurance';
    }
  }

  bool get isOrg =>
      role == CareTeamRole.employer || role == CareTeamRole.insurance;
}

class Provider {
  const Provider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    required this.city,
    required this.distanceMi,
    required this.phone,
    required this.hours,
    required this.inNetwork,
    required this.rating,
    this.acceptingNew = true,
  });

  final String id;
  final String name;
  final String specialty;
  final String address;
  final String city;
  final double distanceMi;
  final String phone;
  final String hours;
  final bool inNetwork;
  final double rating;
  final bool acceptingNew;

  String get fullAddress => '$address, $city';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    this.sender = 'them',
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String sender; // 'me' or 'them'
}

class RequestAttachment {
  const RequestAttachment({
    required this.id,
    required this.name,
    required this.dataUrl,
    required this.size,
  });

  final String id;
  final String name;
  final String dataUrl;
  final int size;
}

class RequestMessage {
  const RequestMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.attachments,
  });

  /// `me` or `advocate` (parity with vcareapp requests-store).
  final String id;
  final String sender;
  final String body;
  final DateTime createdAt;
  final List<RequestAttachment>? attachments;
}

class CareRequest {
  const CareRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageBody,
    required this.description,
    required this.messages,
  });

  final String id;
  final String type;
  final String title;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessageBody;
  final String description;
  final List<RequestMessage> messages;
}

class AppNotification {
  const AppNotification({required this.read});

  final bool read;
}

enum HomeSavedProviderKind { mock, cms }

class SavedProviderItem {
  const SavedProviderItem({
    required this.key,
    required this.name,
    required this.tag,
    required this.location,
    this.kind = HomeSavedProviderKind.mock,
    this.rating,
    this.providerId,
    this.medicareNpi,
    this.phone,
    this.inNetwork = true,
    this.providerSubtitle,
  });

  final String key;
  final String name;
  final String tag;
  final String location;
  final HomeSavedProviderKind kind;
  final double? rating;
  final String? providerId;
  final String? medicareNpi;
  final String? phone;
  final bool inNetwork;
  final String? providerSubtitle;
}

class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.when,
    this.statusLabel,
    this.statusVariant,
    this.photoAsset,
    this.photoUrl,
    this.contactId,
    this.transaction,
  });

  final ActivityKind kind;
  final String id;
  final String title;
  final String subtitle;
  final DateTime when;
  final String? statusLabel;
  final StatusBadgeVariant? statusVariant;
  final String? photoAsset;
  final String? photoUrl;
  final String? contactId;
  final HomeTransaction? transaction;
}

class HomeTransaction {
  const HomeTransaction({
    required this.invoiceNumber,
    required this.membership,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    required this.periodStart,
    required this.periodEnd,
    required this.payerName,
    required this.method,
    this.failureReason,
  });

  final String invoiceNumber;
  final String membership;
  final double amount;
  final String currency;
  final String status;
  final DateTime paidAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String payerName;
  final String method;
  final String? failureReason;
}

class HomeViewData {
  const HomeViewData({
    required this.profile,
    required this.member,
    required this.careTeam,
    required this.savedProviders,
    required this.recentActivity,
    required this.unreadNotifications,
    required this.favoriteProviderIds,
  });

  final HomeProfile profile;
  final HomeMember member;
  final List<CareTeamMember> careTeam;
  final List<SavedProviderItem> savedProviders;
  final List<ActivityItem> recentActivity;
  final int unreadNotifications;
  final List<String> favoriteProviderIds;

  HomeViewData copyWith({
    HomeProfile? profile,
    HomeMember? member,
    List<CareTeamMember>? careTeam,
    List<SavedProviderItem>? savedProviders,
    List<ActivityItem>? recentActivity,
    int? unreadNotifications,
    List<String>? favoriteProviderIds,
  }) {
    return HomeViewData(
      profile: profile ?? this.profile,
      member: member ?? this.member,
      careTeam: careTeam ?? this.careTeam,
      savedProviders: savedProviders ?? this.savedProviders,
      recentActivity: recentActivity ?? this.recentActivity,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      favoriteProviderIds: favoriteProviderIds ?? this.favoriteProviderIds,
    );
  }
}
