import 'package:flutter_template/features/clients/domain/entities/client.dart';

/// Mock clients — parity with vcareapp `clients-data.ts`.
class ClientsMockData {
  ClientsMockData._();

  static String _avatar(int n) => 'https://i.pravatar.cc/200?img=$n';

  static final List<({String id, String fullName, String email, String phone, String dob, String location, ClientGender gender, String ssn, int img})>
      _base = [
    (id: 'c1', fullName: 'Emily Carter', email: 'emily.carter@example.com', phone: '+1 (415) 555-0142', dob: '1988-04-12', location: 'San Francisco, CA', gender: ClientGender.female, ssn: '***-**-4821', img: 47),
    (id: 'c2', fullName: 'Marcus Johnson', email: 'marcus.j@example.com', phone: '+1 (212) 555-0193', dob: '1975-09-03', location: 'New York, NY', gender: ClientGender.male, ssn: '***-**-7610', img: 13),
    (id: 'c3', fullName: 'Priya Patel', email: 'priya.patel@example.com', phone: '+1 (312) 555-0178', dob: '1992-11-21', location: 'Chicago, IL', gender: ClientGender.female, ssn: '***-**-3344', img: 44),
    (id: 'c4', fullName: 'David Nguyen', email: 'd.nguyen@example.com', phone: '+1 (713) 555-0119', dob: '1980-02-17', location: 'Houston, TX', gender: ClientGender.male, ssn: '***-**-9087', img: 33),
    (id: 'c5', fullName: 'Sofia Ramirez', email: 'sofia.r@example.com', phone: '+1 (305) 555-0166', dob: '1995-06-29', location: 'Miami, FL', gender: ClientGender.female, ssn: '***-**-2210', img: 49),
    (id: 'c6', fullName: "James O'Connor", email: 'james.oc@example.com', phone: '+1 (617) 555-0188', dob: '1969-12-05', location: 'Boston, MA', gender: ClientGender.male, ssn: '***-**-5567', img: 15),
    (id: 'c7', fullName: 'Ayesha Khan', email: 'ayesha.k@example.com', phone: '+1 (206) 555-0144', dob: '1990-08-14', location: 'Seattle, WA', gender: ClientGender.female, ssn: '***-**-1199', img: 48),
    (id: 'c8', fullName: 'Liam Anderson', email: 'liam.a@example.com', phone: '+1 (303) 555-0157', dob: '1983-03-23', location: 'Denver, CO', gender: ClientGender.male, ssn: '***-**-8821', img: 60),
    (id: 'c9', fullName: 'Chloe Williams', email: 'chloe.w@example.com', phone: '+1 (404) 555-0102', dob: '1998-10-09', location: 'Atlanta, GA', gender: ClientGender.female, ssn: '***-**-4477', img: 45),
    (id: 'c10', fullName: 'Noah Bennett', email: 'noah.b@example.com', phone: '+1 (602) 555-0131', dob: '1972-07-01', location: 'Phoenix, AZ', gender: ClientGender.nonBinary, ssn: '***-**-6630', img: 11),
  ];

  static const _dependentPool = [
    (name: 'Tashya Walton', relation: 'Spouse', img: 32),
    (name: 'Robert Fox', relation: 'Child', img: 12),
    (name: 'Mia Rivera', relation: 'Child', img: 16),
    (name: 'Diane Bennett', relation: 'Parent', img: 36),
  ];

  static final List<Client> clients = List.generate(_base.length, (i) {
    final c = _base[i];
    final memberships = <ClientMembership>[
      ClientMembership(
        id: '${c.id}-m1',
        plan: 'Recommended Individual Offering',
        carrier: 'Blue Shield',
        memberId: 'BS${100000 + i}',
        status: ClientMembershipStatus.submitted,
        benefitDate: '2026-01-25',
        cost: 300,
        costUnit: 'per individual per month',
        tier: 'Primary',
        nextBillingDate: '2026-06-01',
        note:
            'Primary individual plan. Auto-renews monthly on the 1st. Includes preventive visits and 80% co-insurance after deductible.',
      ),
      if (i % 3 == 0)
        ClientMembership(
          id: '${c.id}-m2',
          plan: 'Dental Plus',
          carrier: 'Delta Dental',
          memberId: 'DD${20000 + i}',
          status: ClientMembershipStatus.completed,
          benefitDate: '2026-03-15',
          cost: 41.99,
          costUnit: 'per individual per month',
          tier: 'Primary',
          nextBillingDate: '2026-06-15',
          note:
              'Dental add-on. Covers two cleanings/year and 50% on major procedures.',
        ),
      if (i % 4 == 0)
        ClientMembership(
          id: '${c.id}-m3',
          plan: 'Vision Care',
          carrier: 'VSP',
          memberId: 'VSP${30000 + i}',
          status: ClientMembershipStatus.approved,
          benefitDate: '2026-06-01',
          cost: 18.5,
          costUnit: 'per individual per month',
          tier: 'Primary',
          nextBillingDate: '2026-07-01',
          note: 'Annual eye exam + frames allowance up to \$200.',
        ),
      ClientMembership(
        id: '${c.id}-m4',
        plan: 'Telehealth Add-on',
        carrier: 'MDLive',
        memberId: 'MDL${40000 + i}',
        status: ClientMembershipStatus.cancelled,
        benefitDate: '2025-11-01',
        cost: 12,
        costUnit: 'per individual per month',
        tier: 'Primary',
        nextBillingDate: '—',
        note:
            'Cancelled by member on 2026-02-14. No refund issued; access ended at period close.',
      ),
    ];

    final dependents = i % 2 == 0
        ? [
            ClientDependent(
              id: '${c.id}-d1',
              name: _dependentPool[0].name,
              relation: _dependentPool[0].relation,
              avatarUrl: _avatar(_dependentPool[0].img),
            ),
            ClientDependent(
              id: '${c.id}-d2',
              name: _dependentPool[1].name,
              relation: _dependentPool[1].relation,
              avatarUrl: _avatar(_dependentPool[1].img),
            ),
          ]
        : i % 3 == 0
            ? [
                ClientDependent(
                  id: '${c.id}-d1',
                  name: _dependentPool[2].name,
                  relation: _dependentPool[2].relation,
                  avatarUrl: _avatar(_dependentPool[2].img),
                ),
              ]
            : [
                ClientDependent(
                  id: '${c.id}-d1',
                  name: _dependentPool[1].name,
                  relation: _dependentPool[1].relation,
                  avatarUrl: _avatar(_dependentPool[1].img),
                ),
                ClientDependent(
                  id: '${c.id}-d2',
                  name: _dependentPool[2].name,
                  relation: _dependentPool[2].relation,
                  avatarUrl: _avatar(_dependentPool[2].img),
                ),
                ClientDependent(
                  id: '${c.id}-d3',
                  name: _dependentPool[3].name,
                  relation: _dependentPool[3].relation,
                  avatarUrl: _avatar(_dependentPool[3].img),
                ),
              ];

    return Client(
      id: c.id,
      fullName: c.fullName,
      email: c.email,
      phone: c.phone,
      avatarUrl: _avatar(c.img),
      dob: c.dob,
      location: c.location,
      gender: c.gender,
      ssn: c.ssn,
      memberships: memberships,
      dependents: dependents,
      paymentMethods: [
        ClientPaymentMethod(
          id: '${c.id}-pm1',
          type: ClientPaymentMethodType.creditDebitCard,
          label: 'Visa ending in 4242',
          last4: '4242',
          isPrimary: true,
        ),
        ClientPaymentMethod(
          id: '${c.id}-pm2',
          type: ClientPaymentMethodType.bankTransfer,
          label: 'Chase Checking',
          last4: '8821',
        ),
      ],
      billings: [
        ClientBilling(
          id: '${c.id}-b2',
          description: 'Monthly premium — April',
          amount: 348.5,
          dueDate: '2026-04-01',
          status: i % 2 == 0
              ? ClientBillingStatus.pending
              : ClientBillingStatus.paid,
          paymentMethodId: '${c.id}-pm1',
        ),
        ClientBilling(
          id: '${c.id}-b3',
          description: 'Copay reconciliation',
          amount: 75,
          dueDate: '2026-05-12',
          status: i % 5 == 0
              ? ClientBillingStatus.overdue
              : ClientBillingStatus.pending,
        ),
      ],
      transactions: [
        ClientTransaction(
          id: '${c.id}-t1',
          membershipTitle: 'Recommended Individual Offering',
          date: '2026-04-01',
          dateTime: '2026-04-01T09:14:00Z',
          payDate: '2026-04-01',
          amount: 300,
          status: ClientTransactionStatus.succeeded,
          paymentMethodLabel: 'Visa •• 4242',
          reference: 'TXN${1000 + i}A',
          description:
              'Monthly membership premium covering April benefit period.',
          dependentName: c.fullName,
          dependentRelation: 'Self',
        ),
        ClientTransaction(
          id: '${c.id}-t2',
          membershipTitle: 'Dental Plus',
          date: '2026-03-15',
          dateTime: '2026-03-15T15:42:00Z',
          payDate: '2026-03-15',
          amount: 41.99,
          status: i % 2 == 0
              ? ClientTransactionStatus.failed
              : ClientTransactionStatus.succeeded,
          paymentMethodLabel: 'Visa •• 4242',
          reference: 'TXN${1000 + i}B',
          description: 'Dental membership recurring premium.',
          note: i % 2 == 0 ? 'Card declined by issuer.' : null,
          dependentName: _dependentPool[0].name,
          dependentRelation: 'Spouse',
        ),
        ClientTransaction(
          id: '${c.id}-t3',
          membershipTitle: 'Vision Care',
          date: '2026-02-12',
          dateTime: '2026-02-12T11:05:00Z',
          payDate: '2026-02-13',
          amount: 18.5,
          status: ClientTransactionStatus.onHold,
          paymentMethodLabel: 'Chase Checking',
          reference: 'TXN${1000 + i}C',
          description: 'Vision Care monthly premium.',
          note: 'Awaiting bank confirmation.',
          dependentName: _dependentPool[1].name,
          dependentRelation: 'Child',
        ),
        ClientTransaction(
          id: '${c.id}-t4',
          membershipTitle: 'Recommended Individual Offering',
          date: '2026-01-05',
          dateTime: '2026-01-05T08:22:00Z',
          payDate: '2026-01-05',
          amount: 300,
          status: ClientTransactionStatus.failed,
          paymentMethodLabel: 'Visa •• 4242',
          reference: 'TXN${1000 + i}D',
          description: 'Monthly premium retry attempt failed.',
          note: 'Insufficient funds — please update payment method.',
          dependentName: c.fullName,
          dependentRelation: 'Self',
        ),
      ],
      cases: [
        ClientCase(
          id: '${c.id}-case1',
          caseId: 'CS-${2400 + i * 3 + 1}',
          title: 'Claim denial appeal — MRI',
          status: ClientCaseStatus.inProgress,
          updatedAt: '2026-05-15',
          createdAt: '2026-04-22',
        ),
        ClientCase(
          id: '${c.id}-case2',
          caseId: 'CS-${2400 + i * 3 + 2}',
          title: 'Out-of-network billing review',
          status: i % 2 == 0
              ? ClientCaseStatus.requested
              : ClientCaseStatus.resolved,
          updatedAt: '2026-05-08',
          createdAt: '2026-04-10',
        ),
        ClientCase(
          id: '${c.id}-case3',
          caseId: 'CS-${2400 + i * 3 + 3}',
          title: 'Prior authorization follow-up',
          status: i % 3 == 0
              ? ClientCaseStatus.resolved
              : ClientCaseStatus.requested,
          updatedAt: '2026-05-02',
          createdAt: '2026-03-28',
        ),
      ],
      files: [
        ClientFile(
          id: '${c.id}-f0',
          name: 'Agreement_Signed.pdf',
          size: '198 KB',
          uploadedAt: '2026-01-08',
          url:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          mime: 'application/pdf',
        ),
        ClientFile(
          id: '${c.id}-f1',
          name: 'Insurance_Card_Front.jpg',
          size: '1.2 MB',
          uploadedAt: '2026-01-10',
          url: 'https://picsum.photos/seed/${c.id}a/800/600',
          mime: 'image/jpeg',
        ),
        ClientFile(
          id: '${c.id}-f2',
          name: 'EOB_March_2026.pdf',
          size: '284 KB',
          uploadedAt: '2026-04-02',
          url:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          mime: 'application/pdf',
        ),
        ClientFile(
          id: '${c.id}-f3',
          name: 'Referral_Cardiology.png',
          size: '512 KB',
          uploadedAt: '2026-04-18',
          url: 'https://picsum.photos/seed/${c.id}b/800/600',
          mime: 'image/png',
        ),
      ],
    );
  });

  static List<ClientListItem> get listItems => clients
      .map(
        (c) => ClientListItem(
          id: c.id,
          fullName: c.fullName,
          email: c.email,
          phone: c.phone,
          location: c.location,
          avatarUrl: c.avatarUrl,
        ),
      )
      .toList();

  static Client? getById(String id) {
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  static List<ClientListItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return listItems;
    return listItems.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.location.toLowerCase().contains(q);
    }).toList();
  }
}
