import 'package:vcare_admin/features/home/data/home_models.dart';

/// Seed requests — parity with vcareapp `requests-store.ts` `seed`.
class RequestsMockData {
  RequestsMockData._();

  static const assignedAdvocateLabel = 'Carmel R., Care Advocate';

  static List<CareRequest> seed({DateTime? now}) {
    final anchor = now ?? DateTime.now();
    return [
      CareRequest(
        id: 'r-001',
        type: 'bill_negotiation',
        title: 'Hospital bill seems too high',
        description:
            "I got a \$4,200 bill from St. Mary's after an ER visit. Can you help me review and negotiate?",
        status: RequestStatus.inReview,
        createdAt: anchor.subtract(const Duration(days: 3)),
        updatedAt: anchor.subtract(const Duration(hours: 5)),
        lastMessageBody:
            "Got it — I'm reviewing the itemized bill now and will reach out to the billing department this week. I'll update you by Friday.",
        messages: [
          RequestMessage(
            id: 'm1',
            sender: 'me',
            body: 'Attached the itemized bill. Some charges look duplicated.',
            createdAt: anchor.subtract(const Duration(days: 3)),
          ),
          RequestMessage(
            id: 'm2',
            sender: 'advocate',
            body:
                "Got it — I'm reviewing the itemized bill now and will reach out to the billing department this week. I'll update you by Friday.",
            createdAt: anchor.subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      CareRequest(
        id: 'r-002',
        type: 'provider_search',
        title: 'In-network dermatologist near 94107',
        description:
            'Looking for a dermatologist that takes my plan, ideally available within 2 weeks.',
        status: RequestStatus.resolved,
        createdAt: anchor.subtract(const Duration(days: 10)),
        updatedAt: anchor.subtract(const Duration(days: 7)),
        lastMessageBody:
            "Sent you 3 in-network options with next available appointments. Let me know if you'd like me to book.",
        messages: [
          RequestMessage(
            id: 'm1',
            sender: 'advocate',
            body:
                "Sent you 3 in-network options with next available appointments. Let me know if you'd like me to book.",
            createdAt: anchor.subtract(const Duration(days: 7)),
          ),
        ],
      ),
    ];
  }

  static CareRequest? byId(String id, {DateTime? now}) {
    for (final request in seed(now: now)) {
      if (request.id == id) return request;
    }
    return null;
  }
}
