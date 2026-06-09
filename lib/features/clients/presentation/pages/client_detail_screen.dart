import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/clients/data/clients_mock_data.dart';
import 'package:flutter_template/features/clients/domain/entities/client.dart';
import 'package:flutter_template/features/clients/presentation/widgets/client_detail_tab_bar.dart';
import 'package:flutter_template/features/clients/presentation/widgets/client_detail_tabs.dart';
import 'package:flutter_template/features/clients/presentation/widgets/client_details_drawer.dart';
import 'package:flutter_template/features/clients/presentation/widgets/client_status_chip.dart';
import 'package:flutter_template/features/clients/utils/client_utils.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

/// Client detail — parity with vcareapp [ClientDetailPage].
class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientsMockData.getById(widget.clientId);
    if (client == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: VcarePageHeader(title: 'Client not found', showBack: true),
            ),
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "We couldn't find that client.",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to clients'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: client.fullName,
              showBack: true,
              action: IconButton(
                onPressed: () => ClientDetailsDrawer.show(context, client),
                icon: const Icon(LucideIcons.info, size: 18),
                tooltip: 'Client details',
              ),
            ),
          ),
          SliverToBoxAdapter(child: _IdentityCard(client: client)),
          SliverPersistentHeader(
            pinned: true,
            delegate: ClientDetailTabBarHeader(
              tabBar: ClientDetailTabBar(controller: _tabController),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            ClientMembershipsTab(
              client: client,
              onMembershipInfo: (m) => _showMembershipNote(context, m),
            ),
            ClientBillingTab(
              client: client,
              onTransactionTap: (t) =>
                  _showTransactionDetails(context, t, client.fullName),
            ),
            ClientCasesTab(client: client),
            ClientDocumentsTab(client: client),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    ClientTransaction transaction,
    String clientName,
  ) {
    context.showBottomSheet<void>(
      builder: (sheetContext) => _TransactionSheet(
        transaction: transaction,
        clientName: clientName,
        onClose: () => Navigator.pop(sheetContext),
      ),
    );
  }

  void _showMembershipNote(BuildContext context, ClientMembership membership) {
    context.showBottomSheet<void>(
      builder: (sheetContext) => _MembershipNoteSheet(
        membership: membership,
        onClose: () => Navigator.pop(sheetContext),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: vcare.muted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(
                    imageUrl: client.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => ColoredBox(
                      color: vcare.muted,
                      child: Center(
                        child: Text(
                          clientInitials(client.fullName),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLIENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: vcare.accent,
                      ),
                    ),
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      client.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _CircleAction(
                icon: LucideIcons.phone,
                filled: true,
                onTap: () => launchUrlString('tel:${client.phone}'),
              ),
              const SizedBox(width: 8),
              _CircleAction(
                icon: LucideIcons.mail,
                onTap: () => launchUrlString('mailto:${client.email}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: filled ? VCareColors.primary : vcare.card,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : vcare.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _TransactionSheet extends StatelessWidget {
  const _TransactionSheet({
    required this.transaction,
    required this.clientName,
    required this.onClose,
  });

  final ClientTransaction transaction;
  final String clientName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: vcare.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Transaction details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              Text(
                transaction.reference,
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
              const SizedBox(height: 8),
              ClientStatusChip.transaction(transaction.status),
              const SizedBox(height: 12),
              Text(
                transaction.membershipTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Billed to $clientName',
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
              const SizedBox(height: 12),
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (transaction.description != null) ...[
                const SizedBox(height: 8),
                Text(transaction.description!),
              ],
              if (transaction.note != null) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.note!,
                  style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipNoteSheet extends StatelessWidget {
  const _MembershipNoteSheet({required this.membership, required this.onClose});

  final ClientMembership membership;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Note Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: vcare.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    membership.note ?? 'No notes for this membership.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
