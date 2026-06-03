import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_mock_data.dart';
import 'package:flutter_template/features/home/presentation/widgets/care_avatar.dart';
import 'package:flutter_template/features/vcare_sync/data/vcare_catalog.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class FindCareCategoryScreen extends StatelessWidget {
  const FindCareCategoryScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final category = VCareCatalog.categoryBySlug(slug);
    final providers = VCareCatalog.providers
        .where((provider) => provider.category == slug)
        .toList();

    return _VcareScaffold(
      title: category?.label ?? 'Category',
      subtitle: category?.blurb ?? 'Browse matching providers',
      showBack: true,
      children: [
        if (category == null)
          const _EmptyPanel(
            icon: LucideIcons.searchX,
            title: 'Category not found',
            subtitle: 'Try another care category from Find Care.',
          )
        else ...[
          _CategoryHero(category: category),
          const SizedBox(height: 14),
          _SectionLabel('${providers.length} providers nearby'),
          const SizedBox(height: 10),
          for (final provider in providers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProviderResultCard(provider: provider),
            ),
        ],
      ],
    );
  }
}

class FindCareSearchScreen extends StatefulWidget {
  const FindCareSearchScreen({super.key});

  @override
  State<FindCareSearchScreen> createState() => _FindCareSearchScreenState();
}

class _FindCareSearchScreenState extends State<FindCareSearchScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final results = VCareCatalog.providers.where((provider) {
      if (query.isEmpty) return true;
      return provider.name.toLowerCase().contains(query) ||
          provider.specialty.toLowerCase().contains(query) ||
          provider.city.toLowerCase().contains(query);
    }).toList();

    return _VcareScaffold(
      title: 'Search Providers',
      subtitle: 'Name, specialty, facility, or city',
      showBack: true,
      children: [
        _SearchBox(
          controller: _queryController,
          hint: 'Search providers',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        _SectionLabel('${results.length} results'),
        const SizedBox(height: 10),
        if (results.isEmpty)
          const _EmptyPanel(
            icon: LucideIcons.searchX,
            title: 'No providers found',
            subtitle:
                'Try a specialty like Pediatrics, Therapy, or Urgent Care.',
          )
        else
          for (final provider in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProviderResultCard(provider: provider),
            ),
      ],
    );
  }
}

class CostLookupScreen extends StatefulWidget {
  const CostLookupScreen({super.key});

  @override
  State<CostLookupScreen> createState() => _CostLookupScreenState();
}

class _CostLookupScreenState extends State<CostLookupScreen> {
  final _queryController = TextEditingController();
  final _money = NumberFormat.simpleCurrency(decimalDigits: 0);

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final procedures = VCareCatalog.procedures.where((procedure) {
      if (query.isEmpty) return true;
      return procedure.name.toLowerCase().contains(query) ||
          procedure.category.toLowerCase().contains(query);
    }).toList();

    return _VcareScaffold(
      title: 'Cost Lookup',
      subtitle: 'Compare common procedure estimates',
      showBack: true,
      children: [
        _SearchBox(
          controller: _queryController,
          hint: 'Search MRI, dental, therapy...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        for (final procedure in procedures)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _VcareCardButton(
              onTap: () => context.pushNamed(
                AppRouter.procedureDetailName,
                pathParameters: {'id': procedure.id},
              ),
              child: Row(
                children: [
                  _IconBubble(
                    icon: LucideIcons.receipt,
                    background: VCareColors.primary.withValues(alpha: 0.1),
                    color: VCareColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TinyLabel(procedure.category),
                        const SizedBox(height: 3),
                        Text(
                          procedure.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_money.format(procedure.costLow)}–${_money.format(procedure.costHigh)} · Avg ${_money.format(procedure.costAvg)}',
                          style: TextStyle(
                            color: context.vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: context.vcare.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ProcedureDetailScreen extends StatelessWidget {
  const ProcedureDetailScreen({super.key, required this.procedureId});

  final String procedureId;

  @override
  Widget build(BuildContext context) {
    final procedure = VCareCatalog.procedureById(procedureId);
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);

    return _VcareScaffold(
      title: 'Procedure',
      showBack: true,
      children: [
        if (procedure == null)
          const _EmptyPanel(
            icon: LucideIcons.searchX,
            title: 'Procedure not found',
            subtitle: 'Return to cost lookup and choose another item.',
          )
        else ...[
          _VcareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TinyLabel(procedure.category),
                const SizedBox(height: 6),
                Text(
                  procedure.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  procedure.description,
                  style: TextStyle(color: context.vcare.mutedForeground),
                ),
                const SizedBox(height: 18),
                _CostRangeBar(procedure: procedure),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _CostStat(
                      label: 'Low',
                      value: money.format(procedure.costLow),
                    ),
                    _CostStat(
                      label: 'Average',
                      value: money.format(procedure.costAvg),
                    ),
                    _CostStat(
                      label: 'High',
                      value: money.format(procedure.costHigh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Provider estimates'),
          const SizedBox(height: 10),
          for (var index = 0; index < 4; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EstimateRow(
                provider: VCareCatalog.providers[index],
                estimate: (procedure.costAvg * (0.7 + index * 0.18)).round(),
              ),
            ),
        ],
      ],
    );
  }
}

class MedicareProviderLookupScreen extends StatefulWidget {
  const MedicareProviderLookupScreen({super.key});

  @override
  State<MedicareProviderLookupScreen> createState() =>
      _MedicareProviderLookupScreenState();
}

class _MedicareProviderLookupScreenState
    extends State<MedicareProviderLookupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController(text: 'Patel');
  String _state = 'CA';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shownProviders = VCareCatalog.providers.take(5).toList();
    return _VcareScaffold(
      title: 'Medicare Lookup',
      subtitle: 'CMS-style provider search',
      showBack: true,
      children: [
        _InfoBanner(
          icon: LucideIcons.landmark,
          text:
              'Flutter parity uses the same interaction flow with local mock CMS results until the API layer is connected.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TextInput(
                controller: _firstNameController,
                label: 'First name',
                hint: 'Maya',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TextInput(
                controller: _lastNameController,
                label: 'Last name',
                hint: 'Patel',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _VcareCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _state,
              isExpanded: true,
              items: const ['CA', 'FL', 'NY', 'TX', 'WA']
                  .map(
                    (state) =>
                        DropdownMenuItem(value: state, child: Text(state)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _state = value ?? _state),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Results'),
        const SizedBox(height: 10),
        for (final provider in shownProviders)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProviderResultCard(
              provider: provider,
              routeName: AppRouter.medicareProviderDetailName,
              pathParameterKey: 'npi',
              pathParameterValue: '1245${provider.id.hashCode.abs()}',
            ),
          ),
      ],
    );
  }
}

class MedicareProviderDetailScreen extends StatelessWidget {
  const MedicareProviderDetailScreen({super.key, required this.npi});

  final String npi;

  @override
  Widget build(BuildContext context) {
    final provider = VCareCatalog
        .providers[npi.hashCode.abs() % VCareCatalog.providers.length];
    return _VcareScaffold(
      title: 'Medicare Provider',
      showBack: true,
      children: [
        _ProviderHero(provider: provider, eyebrow: 'CMS · Medicare'),
        const SizedBox(height: 14),
        _DetailList(
          rows: [
            _DetailRowData(
              icon: LucideIcons.badgeCheck,
              label: 'NPI',
              value: npi,
            ),
            _DetailRowData(
              icon: LucideIcons.mapPin,
              label: 'Location',
              value: '${provider.address} · ${provider.city}',
            ),
            _DetailRowData(
              icon: LucideIcons.stethoscope,
              label: 'Primary service',
              value: provider.specialty,
            ),
            _DetailRowData(
              icon: LucideIcons.shieldCheck,
              label: 'Medicare',
              value:
                  'Participating provider information shown from lookup result',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoBanner(
          icon: LucideIcons.info,
          text:
              'CMS details are informational and should be confirmed with the provider before booking.',
        ),
      ],
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _composer = TextEditingController();
  final List<String> _messages = [
    'Carmel: I can coordinate benefits and the dermatology appointment here.',
    'Keith: I’ll double-check the plan coverage before we book.',
  ];

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: 'Care group',
            subtitle: 'Shared care-team conversation',
            showBack: true,
            showBell: true,
            onBellTap: () => context.pushNamed(
              AppRouter.groupInfoName,
              pathParameters: {'id': widget.groupId},
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChatBubble(text: _messages[index], isMe: index.isOdd),
              ),
            ),
          ),
          _Composer(
            controller: _composer,
            onSend: () {
              final text = _composer.text.trim();
              if (text.isEmpty) return;
              setState(() {
                _messages.add('Alex: $text');
                _composer.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final members = HomeMockData.careTeam.take(3).toList();
    return _VcareScaffold(
      title: 'Group Info',
      subtitle: 'Case coordination · $groupId',
      showBack: true,
      children: [
        for (final member in members)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VcareCard(
              child: Row(
                children: [
                  CareAvatar(member: member, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          member.roleLabel,
                          style: TextStyle(
                            color: context.vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final documents = VCareCatalog.documents
        .where((document) => _filter == 'All' || document.kind == _filter)
        .toList();
    return _VcareScaffold(
      title: 'My Documents',
      subtitle: 'Files from requests, cards, and uploads',
      showBack: true,
      children: [
        Wrap(
          spacing: 8,
          children: ['All', 'Images', 'Voice', 'Files']
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          const _EmptyPanel(
            icon: LucideIcons.folderOpen,
            title: 'No documents here',
            subtitle: 'Uploads and case attachments will appear here.',
          )
        else
          for (final document in documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocumentRow(document: document),
            ),
      ],
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _VcareScaffold(
      title: 'Notifications',
      subtitle: 'Messages, reminders, tips, and billing updates',
      showBack: true,
      children: [
        for (final notification in VCareCatalog.notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VcareCardButton(
              onTap: () => _notificationTap(context, notification.type),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBubble(
                    icon: _notificationIcon(notification.type),
                    background: notification.read
                        ? context.vcare.muted
                        : VCareColors.primary.withValues(alpha: 0.1),
                    color: notification.read
                        ? context.vcare.mutedForeground
                        : VCareColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: context.vcare.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _TinyLabel(
                          DateFormat.MMMd().add_jm().format(
                            notification.createdAt.toLocal(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.read)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: VCareColors.destructive,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'message':
        return LucideIcons.messageCircle;
      case 'reminder':
        return LucideIcons.calendar;
      case 'tip':
        return LucideIcons.lightbulb;
      default:
        return LucideIcons.receipt;
    }
  }

  void _notificationTap(BuildContext context, String type) {
    if (type == 'message') {
      context.pushNamed(AppRouter.messages.toPathName);
    } else if (type == 'tip') {
      context.pushNamed(AppRouter.ava.toPathName);
    } else {
      context.pushNamed(AppRouter.requests.toPathName);
    }
  }
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final faqs = VCareCatalog.faqs.where((faq) {
      if (query.isEmpty) return true;
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);
    }).toList();

    return _VcareScaffold(
      title: 'Help & Support',
      subtitle: 'Answers and urgent contact options',
      showBack: true,
      children: [
        _InfoBanner(
          icon: LucideIcons.siren,
          text:
              'If this is a medical emergency, call 911. For urgent VCare support, call 1-800-555-0199.',
          danger: true,
        ),
        const SizedBox(height: 14),
        _SearchBox(
          controller: _queryController,
          hint: 'Search FAQs',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        for (final faq in faqs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VcareCard(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    faq.question,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.answer,
                        style: TextStyle(color: context.vcare.mutedForeground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometric = true;
  bool _twoFactor = false;
  bool _loginAlerts = true;
  bool _hidePhi = true;

  @override
  Widget build(BuildContext context) {
    return _VcareScaffold(
      title: 'Privacy & Security',
      subtitle: 'Control access and communication preferences',
      showBack: true,
      children: [
        _SwitchRow(
          title: 'Biometric unlock',
          value: _biometric,
          onChanged: (value) => setState(() => _biometric = value),
        ),
        _SwitchRow(
          title: 'Two-factor authentication',
          value: _twoFactor,
          onChanged: (value) => setState(() => _twoFactor = value),
        ),
        _SwitchRow(
          title: 'Login alerts',
          value: _loginAlerts,
          onChanged: (value) => setState(() => _loginAlerts = value),
        ),
        _SwitchRow(
          title: 'Hide sensitive health info in previews',
          value: _hidePhi,
          onChanged: (value) => setState(() => _hidePhi = value),
        ),
        const SizedBox(height: 12),
        const _SectionLabel('Active sessions'),
        const SizedBox(height: 10),
        const _SessionRow(
          device: 'iPhone 15 · Tampa, FL',
          active: 'Active now',
          current: true,
        ),
        const _SessionRow(device: 'MacBook Pro · Tampa, FL', active: '2h ago'),
        const _SessionRow(device: 'Chrome · Orlando, FL', active: '5 days ago'),
      ],
    );
  }
}

class FamilyMemberEditScreen extends StatelessWidget {
  const FamilyMemberEditScreen({super.key, this.memberId});

  final String? memberId;

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: memberId == null ? 'Add Family Member' : 'Edit Family Member',
      subtitle: 'Manage authorized family profiles',
      fields: const [
        _FieldSeed(label: 'Name', value: 'Jordan Rivera'),
        _FieldSeed(label: 'Relationship', value: 'Spouse'),
        _FieldSeed(label: 'Gender', value: 'Prefer not to say'),
        _FieldSeed(label: 'Date of birth', value: '1988-03-12'),
      ],
    );
  }
}

class CareTeamEditScreen extends StatelessWidget {
  const CareTeamEditScreen({super.key, this.memberId});

  final String? memberId;

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: memberId == null ? 'Add Contact' : 'Edit Contact',
      subtitle: 'Care team contact details',
      fields: const [
        _FieldSeed(label: 'Name', value: 'Carmel Hohmann'),
        _FieldSeed(label: 'Role', value: 'Advocate'),
        _FieldSeed(label: 'Email', value: 'carmel@vcare.com'),
        _FieldSeed(label: 'Phone', value: '(415) 555-0188'),
        _FieldSeed(
          label: 'Bio',
          value: '12+ years helping families navigate complex care decisions.',
        ),
      ],
    );
  }
}

class _FormScaffold extends StatefulWidget {
  const _FormScaffold({
    required this.title,
    required this.subtitle,
    required this.fields,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<_FieldSeed> fields;
  final Widget? footer;

  @override
  State<_FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends State<_FormScaffold> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((field) => TextEditingController(text: field.value))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VcareScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      showBack: true,
      bottom: _PrimaryBottomAction(
        label: 'Save changes',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved locally for this Flutter flow.'),
            ),
          );
          Navigator.maybePop(context);
        },
      ),
      children: [
        for (var index = 0; index < widget.fields.length; index++) ...[
          _TextInput(
            controller: _controllers[index],
            label: widget.fields[index].label,
            hint: widget.fields[index].label,
            minLines:
                widget.fields[index].label == 'Bio' ||
                    widget.fields[index].label == 'Notes'
                ? 3
                : 1,
          ),
          const SizedBox(height: 12),
        ],
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}

class _FieldSeed {
  const _FieldSeed({required this.label, required this.value});

  final String label;
  final String value;
}

class _VcareScaffold extends StatelessWidget {
  const _VcareScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.showBack = false,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottomWidget = bottom;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: title,
              subtitle: subtitle,
              showBack: showBack,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom == null ? 40 : 120),
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
        ],
      ),
      bottomNavigationBar: bottomWidget == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: bottomWidget,
            ),
    );
  }
}

class _PrimaryBottomAction extends StatelessWidget {
  const _PrimaryBottomAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: VCareColors.primary,
        foregroundColor: VCareColors.primaryForeground,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label),
    );
  }
}

class _VcareCard extends StatelessWidget {
  const _VcareCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: vcare.border),
      ),
      child: child,
    );
  }
}

class _VcareCardButton extends StatelessWidget {
  const _VcareCardButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _VcareCardButton(
      onTap: onTap,
      child: Row(
        children: [
          _IconBubble(
            icon: icon,
            background: selected
                ? VCareColors.primary.withValues(alpha: 0.12)
                : context.vcare.muted,
            color: selected
                ? VCareColors.primary
                : context.vcare.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: context.vcare.mutedForeground),
                ),
              ],
            ),
          ),
          Icon(
            selected ? LucideIcons.checkCircle : LucideIcons.circle,
            color: selected
                ? VCareColors.primary
                : context.vcare.mutedForeground,
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(LucideIcons.search, color: context.vcare.mutedForeground),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 8,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: context.vcare.mutedForeground,
      ),
    );
  }
}

class _TinyLabel extends StatelessWidget {
  const _TinyLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: VCareColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    this.danger = false,
  });

  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? VCareColors.destructive : VCareColors.primary;
    return _VcareCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.vcare.mutedForeground,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderResultCard extends StatelessWidget {
  const _ProviderResultCard({
    required this.provider,
    this.routeName = AppRouter.providerDetailName,
    this.pathParameterKey = 'id',
    this.pathParameterValue,
  });

  final VCareProvider provider;
  final String routeName;
  final String pathParameterKey;
  final String? pathParameterValue;

  @override
  Widget build(BuildContext context) {
    return _VcareCardButton(
      onTap: () => context.pushNamed(
        routeName,
        pathParameters: {pathParameterKey: pathParameterValue ?? provider.id},
      ),
      child: Row(
        children: [
          _IconBubble(
            icon: LucideIcons.stethoscope,
            background: VCareColors.primary.withValues(alpha: 0.1),
            color: VCareColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TinyLabel(provider.specialty),
                const SizedBox(height: 2),
                Text(
                  provider.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      LucideIcons.star,
                      size: 13,
                      color: context.vcare.accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${provider.rating}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${provider.distanceMi} mi · ${provider.city}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.vcare.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: context.vcare.mutedForeground),
        ],
      ),
    );
  }
}

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.category});

  final VCareProviderCategory category;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      child: Row(
        children: [
          _IconBubble(
            icon: category.icon,
            background: category.iconBackground,
            color: category.iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  category.blurb,
                  style: TextStyle(color: context.vcare.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderHero extends StatelessWidget {
  const _ProviderHero({required this.provider, required this.eyebrow});

  final VCareProvider provider;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TinyLabel(eyebrow),
          const SizedBox(height: 6),
          Text(
            provider.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            provider.specialty,
            style: TextStyle(color: context.vcare.mutedForeground),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.calendarPlus, size: 18),
                label: const Text('Book'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.phone, size: 18),
                label: const Text('Call'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.rows});

  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[index].icon, size: 18, color: VCareColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TinyLabel(rows[index].label),
                        const SizedBox(height: 2),
                        Text(rows[index].value),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < rows.length - 1)
              Divider(height: 1, color: context.vcare.border),
          ],
        ],
      ),
    );
  }
}

class _CostRangeBar extends StatelessWidget {
  const _CostRangeBar({required this.procedure});

  final VCareProcedure procedure;

  @override
  Widget build(BuildContext context) {
    final range = procedure.costHigh - procedure.costLow;
    final averagePosition = range == 0
        ? 0.5
        : (procedure.costAvg - procedure.costLow) / range;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 12, color: context.vcare.muted),
          FractionallySizedBox(
            widthFactor: averagePosition.clamp(0.0, 1.0),
            child: Container(height: 12, color: VCareColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CostStat extends StatelessWidget {
  const _CostStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TinyLabel(label),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({required this.provider, required this.estimate});

  final VCareProvider provider;
  final int estimate;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    return _VcareCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  provider.specialty,
                  style: TextStyle(color: context.vcare.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            money.format(estimate),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document});

  final VCareDocumentItem document;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      child: Row(
        children: [
          _IconBubble(
            icon: document.kind == 'Images'
                ? LucideIcons.image
                : document.kind == 'Voice'
                ? LucideIcons.mic
                : LucideIcons.fileText,
            background: context.vcare.muted,
            color: VCareColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${document.sourceLabel} · ${document.sizeLabel} · ${DateFormat.MMMd().format(document.createdAt)}',
                  style: TextStyle(color: context.vcare.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _VcareCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.device,
    required this.active,
    this.current = false,
  });

  final String device;
  final String active;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _VcareCard(
        child: Row(
          children: [
            Icon(LucideIcons.monitorSmartphone, color: VCareColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    active,
                    style: TextStyle(color: context.vcare.mutedForeground),
                  ),
                ],
              ),
            ),
            if (current) const _TinyLabel('Current'),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.active, required this.total});

  final int active;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        total,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
            height: 6,
            decoration: BoxDecoration(
              color: index <= active
                  ? VCareColors.primary
                  : context.vcare.muted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _VcareCard(
      child: Column(
        children: [
          _IconBubble(
            icon: icon,
            background: VCareColors.primary.withValues(alpha: 0.1),
            color: VCareColors.primary,
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isMe});

  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? VCareColors.primary : context.vcare.card,
          borderRadius: BorderRadius.circular(18),
          border: isMe ? null : Border.all(color: context.vcare.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? VCareColors.primaryForeground
                : VCareColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _VcareCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Message care team...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: onSend,
              icon: Icon(LucideIcons.send, color: VCareColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
