import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_activity_builder.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_transaction_receipt_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class HomeActivityScreen extends StatelessWidget {
  const HomeActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = defaultRecentActivity();
    final vcare = context.vcare;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(title: 'Recent Activity', showBack: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: vcare.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: vcare.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (item.kind == ActivityKind.transaction &&
                            item.transaction != null) {
                          showHomeTransactionReceiptSheet(
                            context,
                            item.transaction!,
                          );
                          return;
                        }
                        if (item.kind == ActivityKind.request) {
                          context.pushNamed(
                            AppRouter.requestDetailName,
                            pathParameters: {'id': item.id},
                          );
                          return;
                        }
                        context.pushNamed(AppRouter.messages.toPathName);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (item.kind == ActivityKind.message &&
                                item.photoAsset != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  item.photoAsset!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (item.kind == ActivityKind.transaction)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: vcare.muted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  LucideIcons.receipt,
                                  size: 16,
                                  color: vcare.mutedForeground,
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: vcare.muted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  LucideIcons.inbox,
                                  size: 16,
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
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatWhen(item.when),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: vcare.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: vcare.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: items.length),
            ),
          ),
        ],
      ),
    );
  }
}
