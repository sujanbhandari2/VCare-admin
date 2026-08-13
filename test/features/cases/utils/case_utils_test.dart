import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';

void main() {
  group('CaseStatus', () {
    test('maps API values to enums', () {
      expect(CaseStatus.fromApi('NEW'), CaseStatus.newCase);
      expect(CaseStatus.fromApi('REQUESTED'), CaseStatus.requested);
      expect(CaseStatus.fromApi('IN_PROGRESS'), CaseStatus.inProgress);
      expect(CaseStatus.fromApi('CLOSED'), CaseStatus.closed);
      expect(CaseStatus.fromApi('DELETED'), CaseStatus.deleted);
      expect(CaseStatus.fromApi(null), CaseStatus.newCase);
    });

    test('exposes api and multipart values', () {
      expect(CaseStatus.inProgress.apiValue, 'IN_PROGRESS');
      expect(CaseStatus.inProgress.multipartValue, 'in_progress');
      expect(CaseStatus.newCase.multipartValue, 'new');
    });
  });

  group('CasePriority', () {
    test('maps API values to enums', () {
      expect(CasePriority.fromApi('URGENT'), CasePriority.urgent);
      expect(CasePriority.fromApi('HIGH'), CasePriority.high);
      expect(CasePriority.fromApi('MEDIUM'), CasePriority.medium);
      expect(CasePriority.fromApi('LOW'), CasePriority.low);
      expect(CasePriority.fromApi(null), CasePriority.medium);
    });
  });

  group('case_utils', () {
    test('formatCaseNumber uses first 8 chars uppercased', () {
      expect(
        formatCaseNumber('abcdef12-3456-7890'),
        'ABCDEF12',
      );
      expect(formatCaseNumber('ab'), 'AB');
      expect(formatCaseNumber(''), '');
    });

    test('formatCaseNumberShort uses last 4 chars', () {
      expect(formatCaseNumberShort('ABCDEF12'), 'EF12');
      expect(formatCaseNumberShort('ABC'), 'ABC');
      expect(formatCaseNumberShort(''), '');
    });

    test('formatCaseIdShort uses last 4 chars of raw id', () {
      expect(
        formatCaseIdShort('5a2a3f5d-f282-4f67-9d50-129f6859b7ad'),
        'b7ad',
      );
      expect(formatCaseIdShort('ab'), 'ab');
      expect(formatCaseIdShort(''), '');
    });

    test('resolveCaseTypeLabel fuzzy-matches known types', () {
      expect(
        resolveCaseTypeLabel('care coordination'),
        'Care Coordination',
      );
      expect(resolveCaseTypeLabel('Unknown Type'), 'Unknown Type');
      expect(resolveCaseTypeLabel(null), '');
    });

    test('mapCaseTypeLabelToApi truncates to 32 chars', () {
      final long = 'A' * 40;
      expect(mapCaseTypeLabelToApi(long).length, 32);
    });

    test('formatMention and mention regex round-trip', () {
      final token = formatMention('Jane Doe', 'jane@example.com');
      expect(token, '@[Jane Doe](jane@example.com)');
      final match = mentionTokenRegex.firstMatch(token);
      expect(match?.group(1), 'Jane Doe');
      expect(match?.group(2), 'jane@example.com');
    });

    test('toggleNoteAccessType flips INTERNAL/EXTERNAL', () {
      expect(toggleNoteAccessType('INTERNAL'), noteAccessTypePublic);
      expect(toggleNoteAccessType('EXTERNAL'), noteAccessTypePrivate);
      expect(toggleNoteAccessType('PUBLIC'), noteAccessTypePrivate);
      expect(isPublicNoteAccessType('PUBLIC'), isTrue);
      expect(isPublicNoteAccessType('INTERNAL'), isFalse);
    });

    test('resolveLatestCaseNoteStatus uses newest note carrying a status', () {
      CaseNote note(String createdAt, {CaseStatus? status}) => CaseNote(
        id: createdAt,
        content: createdAt,
        createdAt: createdAt,
        status: status,
      );

      expect(
        resolveLatestCaseNoteStatus(
          [
            note('2024-03-01T00:00:00Z'),
            note('2024-02-01T00:00:00Z', status: CaseStatus.inProgress),
            note('2024-01-01T00:00:00Z', status: CaseStatus.closed),
          ],
          CaseStatus.newCase,
        ),
        CaseStatus.inProgress,
      );
      expect(
        resolveLatestCaseNoteStatus(
          [note('2024-01-01T00:00:00Z'), note('2024-02-01T00:00:00Z')],
          CaseStatus.closed,
        ),
        CaseStatus.closed,
      );
      expect(
        resolveLatestCaseNoteStatusOrNull([note('2024-01-01T00:00:00Z')]),
        isNull,
      );
    });

    test('sortCaseNotesChronologically puts oldest first', () {
      CaseNote note(String id, String createdAt) => CaseNote(
        id: id,
        content: id,
        createdAt: createdAt,
      );

      final sorted = sortCaseNotesChronologically([
        note('b', '2024-02-01T00:00:00Z'),
        note('a', '2024-01-01T00:00:00Z'),
        note('c', '2024-03-01T00:00:00Z'),
      ]);

      expect(sorted.map((n) => n.id).toList(), ['a', 'b', 'c']);
    });

    test('mergeReferralCaseDetail preserves client when patch omits it', () {
      const previousClient = ReferralCaseClient(
        id: 'c1',
        firstName: 'Sujan',
        lastName: 'Bhandari',
        email: 'sujan@example.com',
        phone: '555',
      );
      final previous = ReferralCase(
        id: 'case-1',
        caseNumber: 'ABCDEF12',
        title: 'Care Coordination',
        status: CaseStatus.inProgress,
        priority: CasePriority.medium,
        caseType: 'Care Coordination',
        clientId: 'c1',
        client: previousClient,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
        createdBy: 'Admin User',
      );
      final incoming = previous.copyWith(
        client: const ReferralCaseClient(id: 'c1', firstName: '', lastName: ''),
        createdBy: '—',
        status: CaseStatus.closed,
      );

      final merged = mergeReferralCaseDetail(previous, incoming);
      expect(merged.status, CaseStatus.closed);
      expect(merged.client.firstName, 'Sujan');
      expect(merged.client.email, 'sujan@example.com');
      expect(merged.createdBy, 'Admin User');
    });

    test('initialsFromDisplayName uses first and last tokens', () {
      expect(initialsFromDisplayName('VCARE ADVOCACY PLATFORM'), 'VP');
      expect(initialsFromDisplayName('Admin'), 'A');
      expect(initialsFromDisplayName(''), '?');
    });

    test('truncateWords limits word count', () {
      expect(truncateWords('One Two Three Four', 3), 'One Two Three…');
      expect(truncateWords('One Two', 3), 'One Two');
    });
  });

  group('CasesListRequest', () {
    test('toQueryParameters includes defaults and filters', () {
      final params = const CasesListRequest(
        page: 2,
        limit: 25,
        search: '  alice  ',
        status: CaseStatus.inProgress,
        priority: CasePriority.high,
        bookmarkedOnly: true,
      ).toQueryParameters();

      expect(params['page'], 2);
      expect(params['limit'], 25);
      expect(params['search'], 'alice');
      expect(params['status'], 'IN_PROGRESS');
      expect(params['priority'], 'HIGH');
      expect(params['sortBy'], 'createdAt');
      expect(params['sortOrder'], 'desc');
      expect(params['bookmarkedFirst'], true);
      expect(params['bookmarkedOnly'], true);
    });

    test('omits empty optional filters', () {
      final params = const CasesListRequest().toQueryParameters();
      expect(params.containsKey('search'), isFalse);
      expect(params.containsKey('status'), isFalse);
      expect(params.containsKey('priority'), isFalse);
      expect(params.containsKey('bookmarkedOnly'), isFalse);
    });
  });
}
