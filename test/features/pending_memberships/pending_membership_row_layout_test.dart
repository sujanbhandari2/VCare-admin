import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_row.dart';

PendingMembership _membership() {
  return PendingMembership(
    id: 'enr-1',
    clientId: 'client-1',
    client: const MembershipClient(
      id: 'client-1',
      firstName: 'Flynn',
      lastName: 'Mccray',
      email: 'pratik+flynn.mccray@vitafyhealth.com',
    ),
    offering: const MembershipOffering(
      id: 'off-1',
      name: 'VCare Advocacy Individual (Annually) with Reg Fee',
      fee: 10,
      registrationFee: 5,
      billingInterval: 'YEARLY',
    ),
    enrollmentType: MembershipEnrollmentType.primary,
    status: MembershipStatus.submitted,
    enrollmentDisplayLabel: 'Primary',
    benefitStartDate: DateTime(2026, 8, 13),
  );
}

Future<void> _pumpRow(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PendingMembershipRow(
              membership: _membership(),
              onTap: () {},
              onApprove: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('row fits without overflow on a narrow phone', (tester) async {
    await _pumpRow(tester, 320);

    expect(tester.takeException(), isNull);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Benefit date 08/13/2026'), findsOneWidget);
  });

  testWidgets('row fits without overflow on a large phone', (tester) async {
    await _pumpRow(tester, 430);

    expect(tester.takeException(), isNull);
    expect(find.text('Submitted'), findsOneWidget);
  });
}
