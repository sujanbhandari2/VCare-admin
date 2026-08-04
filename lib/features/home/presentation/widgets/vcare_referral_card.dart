import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/home/presentation/providers/agent_code_state_provider.dart';
import 'package:vcare_admin/features/home/presentation/widgets/referral_qr_code.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Full referral card with inline-editable agent code.
/// parity: vcare-agent-app-2.0/src/features/id-card/components/VCareReferralCard.tsx
class VcareReferralCard extends ConsumerStatefulWidget {
  const VcareReferralCard({
    super.key,
    required this.profile,
    this.hideInternalLabel = false,
    this.cardCaptureKey,
    this.onShareLink,
  });

  final LocalProfile profile;
  final bool hideInternalLabel;
  final GlobalKey? cardCaptureKey;
  final VoidCallback? onShareLink;

  @override
  ConsumerState<VcareReferralCard> createState() => _VcareReferralCardState();
}

class _VcareReferralCardState extends ConsumerState<VcareReferralCard> {
  bool _copied = false;
  bool _editing = false;
  String? _localError;
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;

  String get _referralUrl => resolveReferralUrl(
    email: widget.profile.email,
    referralLink: widget.profile.referralLink,
  );

  ReferralUrlParts get _urlParts => splitReferralUrl(
    _referralUrl,
    agentCode: widget.profile.agentCode,
  );

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: _urlParts.code);
    _codeFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VcareReferralCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        (oldWidget.profile.agentCode != widget.profile.agentCode ||
            oldWidget.profile.referralLink != widget.profile.referralLink ||
            oldWidget.profile.email != widget.profile.email)) {
      _codeController.text = _urlParts.code;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _copyReferral() async {
    await Clipboard.setData(ClipboardData(text: _referralUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    context.showVcareToast(
      title: 'Referral link copied',
      variant: VcareToastVariant.success,
    );
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _localError = null;
      _codeController.text = _urlParts.code;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _localError = null;
      _codeController.text = _urlParts.code;
    });
  }

  Future<void> _onSave() async {
    final updating = ref.read(agentCodeStateProvider).updating;
    if (updating) return;

    final draft = _codeController.text;
    final error = validateAgentCode(draft);
    if (error != null) {
      setState(() => _localError = error);
      return;
    }

    final nextCode = normalizeAgentCode(draft);
    if (nextCode == _urlParts.code.toLowerCase()) {
      setState(() {
        _editing = false;
        _localError = null;
      });
      return;
    }

    await ref.read(agentCodeStateProvider.notifier).updateAgentCode(
      agentCode: nextCode,
      onCompleted: (result) {
        if (!mounted) return;
        if (result != null) {
          setState(() {
            _editing = false;
            _localError = null;
          });
          context.showVcareToast(
            title: 'Referral code updated',
            variant: VcareToastVariant.success,
          );
        } else {
          final message = ref.read(agentCodeStateProvider).error;
          context.showVcareToast(
            title: message ?? 'Could not update referral code',
            variant: VcareToastVariant.destructive,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final updating = ref.watch(agentCodeStateProvider).updating;
    final formattedPhone = AuthPhoneFormatter.formatInternationalDisplay(
      widget.profile.phone,
    );
    final agencyName = widget.profile.agencyName?.trim();
    final showAgency = widget.profile.hasAgencyGroup;
    final parts = _urlParts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: widget.cardCaptureKey,
          // 4px inset so save/share captures don't clip rounded edges.
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: vcare.gradientCard,
                borderRadius: BorderRadius.circular(VCareLayout.cardRadius3xl),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VCareLayout.cardRadius3xl),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: -64,
                      top: -64,
                      child: Container(
                        width: 224,
                        height: 224,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -48,
                      bottom: -80,
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  VCareAssets.vIcon,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (!widget.hideInternalLabel)
                                Text(
                                  'MY REFERRAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.profile.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (widget.profile.email.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.profile.email,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (formattedPhone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedPhone,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  Text(
                                    'SCAN TO JOIN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ReferralQrCode(
                                    data: _referralUrl,
                                    size: 112,
                                    padding: 6,
                                    borderRadius: 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (showAgency) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.building2,
                                      size: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AGENCY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (agencyName != null &&
                                            agencyName.isNotEmpty)
                                          Text(
                                            agencyName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(VCareLayout.cardRadius2xl),
            border: Border.all(color: vcare.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Referral link',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.onShareLink != null)
                      TextButton.icon(
                        onPressed: widget.onShareLink,
                        icon: const Icon(LucideIcons.share2, size: 12),
                        label: const Text(
                          'Share link',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: VCareColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: vcare.muted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vcare.border),
                  ),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: Row(
                                      children: [
                                        if (parts.prefix.isNotEmpty)
                                          Text(
                                            parts.prefix,
                                            softWrap: false,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: vcare.mutedForeground,
                                            ),
                                          ),
                                        if (_editing)
                                          IntrinsicWidth(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minWidth: 112,
                                              ),
                                              child: CallbackShortcuts(
                                                bindings: {
                                                  const SingleActivator(
                                                    LogicalKeyboardKey.escape,
                                                  ): _cancelEditing,
                                                },
                                                child: TextField(
                                                  controller: _codeController,
                                                  focusNode: _codeFocusNode,
                                                  enabled: !updating,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                    isDense: true,
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .deny(
                                                      RegExp(r'\s'),
                                                    ),
                                                  ],
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  autocorrect: false,
                                                  enableSuggestions: false,
                                                  onChanged: (_) {
                                                    if (_localError != null) {
                                                      setState(
                                                        () =>
                                                            _localError = null,
                                                      );
                                                    }
                                                  },
                                                  onSubmitted: (_) => _onSave(),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            parts.code,
                                            softWrap: false,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_editing) ...[
                          _LinkBarAction(
                            label: 'Cancel',
                            onPressed: updating ? null : _cancelEditing,
                            bordered: true,
                          ),
                          _LinkBarAction(
                            label: updating ? 'Saving…' : 'Save',
                            onPressed: updating ? null : _onSave,
                            filled: true,
                          ),
                        ] else ...[
                          _LinkBarIconButton(
                            icon: LucideIcons.pencil,
                            tooltip: 'Edit referral code',
                            onPressed: _startEditing,
                          ),
                          _LinkBarIconButton(
                            icon: _copied
                                ? LucideIcons.check
                                : LucideIcons.copy,
                            tooltip: 'Copy referral link',
                            onPressed: _copyReferral,
                            filled: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _localError ??
                      (_editing
                          ? 'Only the code can be changed (3–64 letters, numbers, or hyphens).'
                          : 'Share this link or scan the QR on your card to refer a friend.'),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: _localError != null
                        ? Theme.of(context).colorScheme.error
                        : vcare.mutedForeground,
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

class _LinkBarAction extends StatelessWidget {
  const _LinkBarAction({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.bordered = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: filled ? VCareColors.primary : vcare.card,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: bordered
                ? Border(left: BorderSide(color: vcare.border))
                : filled
                ? Border(left: BorderSide(color: vcare.border))
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled
                  ? Colors.white
                  : onPressed == null
                  ? vcare.mutedForeground
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkBarIconButton extends StatelessWidget {
  const _LinkBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? VCareColors.primary : Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: filled
                  ? null
                  : Border(left: BorderSide(color: vcare.border)),
            ),
            child: Icon(
              icon,
              size: 16,
              color: filled ? Colors.white : vcare.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
