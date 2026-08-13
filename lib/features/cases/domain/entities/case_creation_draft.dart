import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';

/// Draft state for the multi-step case creation wizard.
class CaseCreationDraft {
  const CaseCreationDraft({
    this.selectedClient,
    this.initialNote = '',
    this.noteConfirmed = false,
    this.selectedAssignee,
    this.selectedType,
    this.showSummary = false,
    this.currentStep = 0,
  });

  final CaseCreationClient? selectedClient;
  final String initialNote;
  final bool noteConfirmed;
  final CaseAssignee? selectedAssignee;
  final String? selectedType;
  final bool showSummary;
  final int currentStep;

  bool get canProceedFromClient => selectedClient != null;

  bool get canProceedFromNote => noteConfirmed;

  bool get canProceedFromDetails =>
      selectedType != null && selectedType!.trim().isNotEmpty;

  CaseCreationDraft copyWith({
    CaseCreationClient? selectedClient,
    bool clearClient = false,
    String? initialNote,
    bool? noteConfirmed,
    CaseAssignee? selectedAssignee,
    bool clearAssignee = false,
    String? selectedType,
    bool clearType = false,
    bool? showSummary,
    int? currentStep,
  }) {
    return CaseCreationDraft(
      selectedClient: clearClient
          ? null
          : (selectedClient ?? this.selectedClient),
      initialNote: initialNote ?? this.initialNote,
      noteConfirmed: noteConfirmed ?? this.noteConfirmed,
      selectedAssignee: clearAssignee
          ? null
          : (selectedAssignee ?? this.selectedAssignee),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      showSummary: showSummary ?? this.showSummary,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Minimal client selection for case creation.
class CaseCreationClient {
  const CaseCreationClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.phone = '',
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }
}

/// Body for `POST /api/v1/referral-cases`.
class CreateCaseBody {
  const CreateCaseBody({
    required this.clientId,
    this.status = 'NEW',
    this.type,
    this.priority,
    this.assignedTo,
    this.notes,
  });

  final String clientId;
  final String status;
  final String? type;
  final String? priority;
  final String? assignedTo;
  final List<CreateCaseNoteBody>? notes;

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'status': status,
      if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
      if (priority != null && priority!.trim().isNotEmpty)
        'priority': priority!.trim(),
      if (assignedTo != null && assignedTo!.trim().isNotEmpty)
        'assignedTo': assignedTo!.trim(),
      if (notes != null && notes!.isNotEmpty)
        'notes': notes!.map((n) => n.toJson()).toList(),
    };
  }
}

class CreateCaseNoteBody {
  const CreateCaseNoteBody({
    required this.note,
    this.accessType = 'INTERNAL',
  });

  final String note;
  final String accessType;

  Map<String, dynamic> toJson() => {
    'note': note,
    'accessType': accessType,
  };
}

/// Body for `PATCH /api/v1/referral-cases/{id}`.
class UpdateCaseBody {
  const UpdateCaseBody({
    this.status,
    this.type,
    this.priority,
    this.assignedTo,
    this.clearAssignedTo = false,
  });

  final String? status;
  final String? type;
  final String? priority;
  final String? assignedTo;
  final bool clearAssignedTo;

  Map<String, dynamic> toJson() {
    return {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (clearAssignedTo)
        'assignedTo': null
      else if (assignedTo != null)
        'assignedTo': assignedTo,
    };
  }
}
