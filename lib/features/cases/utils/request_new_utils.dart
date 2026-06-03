import 'package:flutter_template/features/vcare_sync/data/vcare_catalog.dart';

const requestNewTotalSteps = 3;
const requestNewMaxDescriptionLength = 2000;
const requestNewMaxAttachmentBytes = 5 * 1024 * 1024;

/// Parity with vcareapp `requests-store` `suggestRequestType`.
String suggestRequestType(String text) {
  final t = text.toLowerCase();
  var best = 'other';
  var bestScore = 0;

  for (final type in _requestTypeKeywords) {
    var score = 0;
    for (final keyword in type.keywords) {
      if (t.contains(keyword)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = type.value;
    }
  }
  return best;
}

String? requestTypeLabel(String value) {
  for (final type in VCareCatalog.requestTypes) {
    if (type.value == value) return type.label;
  }
  return null;
}

/// Keywords aligned with vcareapp `REQUEST_TYPES` in requests-store.ts.
const _requestTypeKeywords = <_RequestTypeKeywords>[
  _RequestTypeKeywords('insurance_navigation', [
    'insurance',
    'policy',
    'enroll',
    'enrollment',
    'plan',
    'marketplace',
    'medicare',
    'medicaid',
    'coverage options',
  ]),
  _RequestTypeKeywords('benefit_navigation', [
    'benefit',
    'copay',
    'deductible',
    'out of pocket',
    'coverage',
    'covered',
    'in-network',
    'out of network',
    'hsa',
    'fsa',
  ]),
  _RequestTypeKeywords('provider_search', [
    'doctor',
    'provider',
    'specialist',
    'find',
    'dermatologist',
    'cardiologist',
    'pediatrician',
    'clinic',
    'hospital',
    'referral',
  ]),
  _RequestTypeKeywords('procedure_cost', [
    'cost',
    'price',
    'estimate',
    'how much',
    'procedure',
    'surgery',
    'mri',
    'ct scan',
    'quote',
    'compare',
  ]),
  _RequestTypeKeywords('care_coordination', [
    'appointment',
    'schedule',
    'records',
    'transfer',
    'coordinate',
    'follow up',
    'follow-up',
    'between doctors',
  ]),
  _RequestTypeKeywords('claims_assistance', [
    'claim',
    'bill',
    'eob',
    'statement',
    'charge',
    'error',
    'duplicate',
    'billing',
    'understand',
    'explain',
  ]),
  _RequestTypeKeywords('bill_negotiation', [
    'negotiate',
    'reduce',
    'settle',
    'lower',
    'discount',
    'too high',
    'expensive',
    'payment plan',
  ]),
  _RequestTypeKeywords('appeals_grievances', [
    'denied',
    'denial',
    'appeal',
    'grievance',
    'rejected',
    'overturn',
    'complaint',
  ]),
  _RequestTypeKeywords('other', []),
];

class _RequestTypeKeywords {
  const _RequestTypeKeywords(this.value, this.keywords);

  final String value;
  final List<String> keywords;
}
