import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/widgets/client_status_chip.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

enum ClientReceiptStatus { paid, pending, failed }

class ClientTransactionReceiptInfo {
  const ClientTransactionReceiptInfo({
    required this.id,
    required this.membership,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    required this.periodStart,
    required this.periodEnd,
    required this.payerName,
    required this.method,
    required this.invoiceNumber,
  });

  factory ClientTransactionReceiptInfo.fromTransaction({
    required ClientTransaction transaction,
    required String payerName,
  }) {
    return ClientTransactionReceiptInfo(
      id: transaction.id,
      membership: transaction.membershipTitle,
      amount: transaction.amount,
      currency: 'USD',
      status: switch (transaction.status) {
        ClientTransactionStatus.succeeded => ClientReceiptStatus.paid,
        ClientTransactionStatus.failed => ClientReceiptStatus.failed,
        ClientTransactionStatus.onHold ||
        ClientTransactionStatus.pending => ClientReceiptStatus.pending,
      },
      paidAt: transaction.dateTime,
      periodStart: transaction.date,
      periodEnd: transaction.payDate,
      payerName: payerName,
      method: transaction.paymentMethodLabel ?? '—',
      invoiceNumber: transaction.reference,
    );
  }

  final String id;
  final String membership;
  final double amount;
  final String currency;
  final ClientReceiptStatus status;
  final String paidAt;
  final String periodStart;
  final String periodEnd;
  final String payerName;
  final String method;
  final String invoiceNumber;

  String get statusLabel => switch (status) {
    ClientReceiptStatus.paid => 'Paid',
    ClientReceiptStatus.pending => 'Pending',
    ClientReceiptStatus.failed => 'Failed',
  };

  Future<void> downloadPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      final money = _formatMoney(amount, currency);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(56),
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Invoice #$invoiceNumber',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Status: $statusLabel',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),
                pw.Text(
                  membership,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Billed to: $payerName',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Payment method: $method',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Service period: ${_formatDate(periodStart)} — ${_formatDate(periodEnd)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Paid on: ${_formatDateTime(paidAt)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Description',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Amount',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$membership membership',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(money, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      money,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Thank you for your membership.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt-$invoiceNumber.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Receipt $invoiceNumber',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      context.showVcareToast(
        title: 'Could not download receipt',
        variant: VcareToastVariant.destructive,
      );
    }
  }
}

class ClientTransactionReceiptSheet extends StatelessWidget {
  const ClientTransactionReceiptSheet({super.key, required this.receipt});

  final ClientTransactionReceiptInfo receipt;

  static Future<void> show(
    BuildContext context, {
    required ClientTransactionReceiptInfo receipt,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return SizedBox(
          height: height,
          child: ClientTransactionReceiptSheet(receipt: receipt),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: vcare.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Text(
              'Receipt',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice',
                              style: TextStyle(
                                fontSize: 12,
                                color: vcare.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${receipt.invoiceNumber}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClientStatusChip(
                        label: receipt.statusLabel,
                        tone: switch (receipt.status) {
                          ClientReceiptStatus.paid => ClientChipTone.success,
                          ClientReceiptStatus.failed =>
                            ClientChipTone.destructive,
                          ClientReceiptStatus.pending => ClientChipTone.warning,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: vcare.border),
                  const SizedBox(height: 16),
                  Text(
                    receipt.membership,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Billed to ${receipt.payerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receipt.method,
                    style: TextStyle(
                      fontSize: 12,
                      color: vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ReceiptMeta(
                          label: 'Service period',
                          value:
                              '${_formatDate(receipt.periodStart)} — ${_formatDate(receipt.periodEnd)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReceiptMeta(
                          label: 'Paid on',
                          value: _formatDateTime(receipt.paidAt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: vcare.border),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatMoney(receipt.amount, receipt.currency),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: vcare.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => receipt.downloadPdf(context),
                icon: const Icon(LucideIcons.download, size: 18),
                label: const Text('Download PDF receipt'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMeta extends StatelessWidget {
  const _ReceiptMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

String _formatMoney(double amount, String currency) {
  return NumberFormat.simpleCurrency(name: currency).format(amount);
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return formatDisplayDate(parsed.toLocal());
  }
  return value;
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return DateFormat('MMM d, yyyy, h:mm a').format(parsed.toLocal());
  }
  return value;
}
