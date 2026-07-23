import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_activity_status_chip.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';

class TodoListRow extends StatelessWidget {
  const TodoListRow({super.key, required this.item, this.onTap});

  final TodoItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: switch (item.type) {
            TodoType.paymentFailed =>
              _PaymentFailedRow(item: item, vcare: vcare),
            TodoType.w9FormMissing => _W9FormRow(item: item, vcare: vcare),
            TodoType.unknown => _GenericRow(item: item, vcare: vcare),
          },
        ),
      ),
    );
  }
}

class _PaymentFailedRow extends StatelessWidget {
  const _PaymentFailedRow({required this.item, required this.vcare});

  final TodoItem item;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    final details = item.paymentFailedDetails;
    final amount = details == null
        ? null
        : NumberFormat.simpleCurrency(
            name: details.currency,
          ).format(details.amount);
    final error = Theme.of(context).colorScheme.error;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(LucideIcons.alertTriangle, size: 20, color: error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (amount != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: error,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const HomeActivityStatusChip(label: 'Failed'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatWhen(item.occurredAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _W9FormRow extends StatelessWidget {
  const _W9FormRow({required this.item, required this.vcare});

  final TodoItem item;
  final VCareThemeExtension vcare;

  static const _orange = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.fileText, size: 20, color: _orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatWhen(item.occurredAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const HomeActivityStatusChip(label: 'Action needed'),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenericRow extends StatelessWidget {
  const _GenericRow({required this.item, required this.vcare});

  final TodoItem item;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: vcare.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.listChecks,
            size: 20,
            color: vcare.mutedForeground,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatWhen(item.occurredAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
