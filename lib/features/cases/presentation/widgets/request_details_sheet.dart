import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/data/requests_mock_data.dart';
import 'package:flutter_template/features/cases/utils/cases_utils.dart';
import 'package:flutter_template/features/cases/utils/request_new_utils.dart';
import 'package:flutter_template/features/home/data/home_models.dart';

/// Parity with vcareapp `RequestDetailsSheet` (`SheetContent side="right"`).
class RequestDetailsSheet extends StatelessWidget {
  const RequestDetailsSheet({super.key, required this.request});

  final CareRequest request;

  /// Web `sm:max-w-md` (28rem).
  static const _maxPanelWidth = 448;

  static Future<void> show(BuildContext context, CareRequest request) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return RequestDetailsSheet(request: request);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(slide),
          child: child,
        );
      },
    );
  }

  int _attachmentCount() {
    return request.messages.fold<int>(
      0,
      (count, message) => count + (message.attachments?.length ?? 0),
    );
  }

  String _caseIdLabel() {
    final slice = request.id.length > 6
        ? request.id.substring(request.id.length - 6)
        : request.id;
    return '#${slice.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = math.min(screenWidth, _maxPanelWidth.toDouble());
    final typeLabel = requestTypeLabel(request.type) ?? request.type;
    final events = _buildTimeline(request);
    final attachmentCount = _attachmentCount();

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: panelWidth,
        height: double.infinity,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 16,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          child: SafeArea(
            left: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Request details',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: VCareColors.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: vcare.muted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  icon: LucideIcons.tag,
                                  label: 'Category',
                                  value: Text(typeLabel),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.clock,
                                  label: 'Status',
                                  value: _RequestDetailStatusBadge(
                                    status: request.status,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.user,
                                  label: 'Assigned to',
                                  value: const Text(
                                    RequestsMockData.assignedAdvocateLabel,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.calendar,
                                  label: 'Created',
                                  value: Text(
                                    _formatDateTime(request.createdAt),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.clock,
                                  label: 'Last update',
                                  value: Text(_relative(request.updatedAt)),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.messageSquare,
                                  label: 'Messages',
                                  value: Text(
                                    '${request.messages.length} · $attachmentCount attachment${attachmentCount == 1 ? '' : 's'}',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: LucideIcons.tag,
                                  label: 'Case ID',
                                  value: Text(_caseIdLabel()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ACTIVITY TIMELINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: vcare.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActivityTimeline(
                            events: events,
                            resolved: request.status == RequestStatus.resolved,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Web `Badge` + `statusVariant()` + `text-[10px]` in RequestDetailsSheet.
class _RequestDetailStatusBadge extends StatelessWidget {
  const _RequestDetailStatusBadge({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final label = casesStatusLabel(status);

    final Color bg;
    final Color fg;
    final Border? border;

    switch (status) {
      case RequestStatus.newRequest:
        bg = VCareColors.primary;
        fg = VCareColors.primaryForeground;
        border = null;
      case RequestStatus.inReview:
        bg = VCareColors.secondary;
        fg = VCareColors.secondaryForeground;
        border = null;
      case RequestStatus.actionNeeded:
        bg = VCareColors.destructive;
        fg = VCareColors.destructiveForeground;
        border = null;
      case RequestStatus.resolved:
        bg = Colors.transparent;
        fg = VCareColors.foreground;
        border = Border.all(color: vcare.border);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            LucideIcons.x,
            size: 16,
            color: context.vcare.mutedForeground.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.id,
    required this.label,
    required this.at,
    required this.kind,
    this.detail,
  });

  final String id;
  final String label;
  final DateTime at;
  final String kind;
  final String? detail;
}

List<_TimelineEvent> _buildTimeline(CareRequest request) {
  final events = <_TimelineEvent>[
    _TimelineEvent(
      id: 'created',
      label: 'Request submitted',
      at: request.createdAt,
      kind: 'created',
    ),
  ];

  for (final message in request.messages) {
    if (message.sender == 'advocate' &&
        !events.any((event) => event.id == 'in-progress')) {
      events.add(
        _TimelineEvent(
          id: 'in-progress',
          label: 'Advocate responded',
          at: message.createdAt,
          kind: 'status',
          detail: RequestsMockData.assignedAdvocateLabel,
        ),
      );
    }
    final attachments = message.attachments;
    if (attachments != null && attachments.isNotEmpty) {
      events.add(
        _TimelineEvent(
          id: 'att-${message.id}',
          label:
              '${attachments.length} attachment${attachments.length > 1 ? 's' : ''} shared',
          at: message.createdAt,
          kind: 'attachment',
          detail: attachments.map((a) => a.name).join(', '),
        ),
      );
    }
  }

  if (request.status == RequestStatus.resolved) {
    events.add(
      _TimelineEvent(
        id: 'resolved',
        label: casesStatusLabel(request.status),
        at: request.updatedAt,
        kind: 'status',
      ),
    );
  }

  events.sort((a, b) => b.at.compareTo(a.at));
  return events;
}

/// Web `ol.border-l` — newest event first (matches product screenshot).
class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({
    required this.events,
    required this.resolved,
  });

  final List<_TimelineEvent> events;
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 4,
            bottom: 4,
            child: Container(width: 1, color: vcare.border),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < events.length; i++)
                _TimelineEventRow(
                  event: events[i],
                  isLatest: i == 0,
                  resolved: resolved,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: vcare.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: VCareColors.foreground,
                ),
                child: value,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.isLatest, this.showCheck = false});

  final bool isLatest;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (showCheck) {
      return Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: vcare.accent, width: 2),
        ),
        child: Icon(LucideIcons.check, size: 8, color: vcare.accent),
      );
    }

    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: isLatest ? vcare.accent : vcare.border,
          width: 2,
        ),
      ),
      child: isLatest
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
          : Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: vcare.mutedForeground, width: 1.5),
              ),
            ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    required this.event,
    required this.isLatest,
    required this.resolved,
  });

  final _TimelineEvent event;
  final bool isLatest;
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final showCheck = isLatest && resolved;

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -23,
            top: 2,
            child: _TimelineDot(isLatest: isLatest, showCheck: showCheck),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: VCareColors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatDateTime(event.at)} · ${_relative(event.at)}',
                style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
              ),
              if (event.detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime date) =>
    DateFormat('MMM d, yyyy, h:mm a').format(date);

String _relative(DateTime date) {
  final diff = DateTime.now().difference(date);
  final minutes = diff.inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '${minutes}m ago';
  final hours = diff.inHours;
  if (hours < 24) return '${hours}h ago';
  final days = diff.inDays;
  if (days < 30) return '${days}d ago';
  return _formatDateTime(date);
}
