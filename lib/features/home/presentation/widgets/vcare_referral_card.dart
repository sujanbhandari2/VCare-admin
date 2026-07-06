import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/vcare_assets.dart';
import 'package:vcare_admin/features/home/presentation/providers/referral_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/widgets/referral_qr_code.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';

/// Agency label on referral card — parity with vcareapp [VCareReferralCard].
const kReferralAgencyName = 'BlueShield National';

/// Full referral card + editable slug block.
/// parity: vcare-agent-app-2.0/src/features/id-card/components/VCareReferralCard.tsx
class VcareReferralCard extends ConsumerStatefulWidget {
  const VcareReferralCard({
    super.key,
    required this.profile,
    this.hideInternalLabel = false,
  });

  final LocalProfile profile;
  final bool hideInternalLabel;

  @override
  ConsumerState<VcareReferralCard> createState() => _VcareReferralCardState();
}

class _VcareReferralCardState extends ConsumerState<VcareReferralCard> {
  late String _slug;
  late final TextEditingController _draftController;
  bool _isEditing = false;
  bool _copied = false;
  bool _saving = false;
  String? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _slug = referralUsernameFromEmail(widget.profile.email);
    _draftController = TextEditingController(text: _slug);
    if (_hasApiReferralLink) {
      _loaded = true;
    } else {
      _loadSlug();
    }
  }

  Future<void> _loadSlug() async {
    final stored = await ref.read(referralRepositoryProvider).readSlug();
    if (!mounted) return;
    if (stored != null && stored.isNotEmpty) {
      setState(() {
        _slug = stored;
        _draftController.text = stored;
      });
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  bool get _hasApiReferralLink {
    final link = widget.profile.referralLink?.trim();
    return link != null && link.isNotEmpty;
  }

  String get _referralUrl {
    if (_hasApiReferralLink) {
      return widget.profile.referralLink!.trim();
    }
    return referralUrlFromSlug(_slug);
  }

  void _startEdit() {
    setState(() {
      _draftController.text = _slug;
      _error = null;
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _draftController.text = _slug;
      _error = null;
      _isEditing = false;
    });
  }

  void _onDraftChanged(String value) {
    final cleaned = sanitizeReferralSlug(value);
    _draftController.value = TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
    setState(() => _error = validateReferralSlug(cleaned));
  }

  Future<void> _saveSlug() async {
    final draft = _draftController.text;
    final validationError = validateReferralSlug(draft);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(referralRepositoryProvider).saveSlug(draft);
      if (!mounted) return;
      setState(() {
        _slug = draft;
        _isEditing = false;
        _saving = false;
      });
      Fluttertoast.showToast(msg: 'Referral username updated');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      Fluttertoast.showToast(msg: "Couldn't save username");
    }
  }

  Future<void> _copyReferral() async {
    if (_isEditing) return;
    await Clipboard.setData(ClipboardData(text: _referralUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    Fluttertoast.showToast(msg: 'Referral link copied');
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
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
                                const SizedBox(height: 4),
                                Text(
                                  '@$_slug',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.profile.phone,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.building2,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(
                                    kReferralAgencyName,
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
                  ),
                ),
              ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Referral link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!_isEditing && !_hasApiReferralLink)
                      TextButton.icon(
                        onPressed: _startEdit,
                        icon: const Icon(LucideIcons.pencil, size: 12),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: VCareColors.primary,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: _cancelEdit,
                        icon: const Icon(LucideIcons.x, size: 12),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: vcare.mutedForeground,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isEditing) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: vcare.muted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _error != null
                            ? VCareColors.destructive
                            : vcare.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            referralUrlPrefix,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: vcare.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _draftController,
                            autofocus: true,
                            onChanged: _onDraftChanged,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 11,
                        color: VCareColors.destructive,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving || _error != null ? null : _saveSlug,
                      style: FilledButton.styleFrom(
                        backgroundColor: VCareColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save username'),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: vcare.muted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              _referralUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: VCareColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _copyReferral,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _copied
                                      ? LucideIcons.check
                                      : LucideIcons.copy,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _copied ? 'Copied' : 'Copy',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Share this link or scan the QR on your card to refer a friend.',
                  style: TextStyle(
                    fontSize: 11,
                    color: vcare.mutedForeground,
                    height: 1.35,
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
