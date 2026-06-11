import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

enum CardEditMethod { unset, camera, gallery, manual }

class CardEditScreen extends StatefulWidget {
  const CardEditScreen({super.key, this.cardId});

  final String? cardId;

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  CardEditMethod _method = CardEditMethod.unset;
  bool _extracting = false;

  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _memberIdController = TextEditingController();
  final _notesController = TextEditingController();

  String? _frontPath;
  String? _backPath;

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null) {
      _method = CardEditMethod.manual;
      // Mock existing data
      _titleController.text = 'Dental Plus';
      _issuerController.text = 'BlueShield National';
      _memberIdController.text = 'VC-8472-1903';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _memberIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _runExtraction() {
    setState(() => _extracting = true);
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _titleController.text = 'Anthem Blue Cross';
        _issuerController.text = 'Anthem BCBS';
        _memberIdController.text = 'ABC123456789';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details extracted with AI ✨')),
      );
    });
  }

  void _save() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card saved successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.cardId == null;

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: isNew ? 'Add Card' : 'Edit Card',
            subtitle: 'Insurance, dental, vision, and more',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: _method == CardEditMethod.unset && isNew
                  ? _MethodChooser(onSelect: (m) => setState(() => _method = m))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_method == CardEditMethod.camera ||
                            _method == CardEditMethod.gallery) ...[
                          _PhotoSection(
                            frontPath: _frontPath,
                            backPath: _backPath,
                            extracting: _extracting,
                            onPickFront: () =>
                                setState(() => _frontPath = 'mock_path'),
                            onPickBack: () =>
                                setState(() => _backPath = 'mock_path'),
                            onClearFront: () =>
                                setState(() => _frontPath = null),
                            onClearBack: () => setState(() => _backPath = null),
                            onRunExtraction: _runExtraction,
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel('Card Details'),
                          const SizedBox(height: 12),
                        ],
                        _CardFormFields(
                          titleController: _titleController,
                          issuerController: _issuerController,
                          memberIdController: _memberIdController,
                          notesController: _notesController,
                        ),
                        const SizedBox(height: 32),
                        _PrimaryButton(label: 'Save card', onPressed: _save),
                        if (!isNew) ...[
                          const SizedBox(height: 12),
                          _SecondaryButton(
                            label: 'Delete card',
                            color: VCareColors.destructive,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChooser extends StatelessWidget {
  const _MethodChooser({required this.onSelect});

  final ValueChanged<CardEditMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to add this card? AI will read photos for you and pre-fill the form.',
          style: TextStyle(
            fontSize: 14,
            color: vcare.mutedForeground.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _ChoiceTile(
          icon: LucideIcons.camera,
          title: 'Take a picture',
          subtitle: "Snap the front and back. We'll auto-fill the details.",
          onTap: () => onSelect(CardEditMethod.camera),
        ),
        const SizedBox(height: 12),
        _ChoiceTile(
          icon: LucideIcons.image,
          title: 'Upload from gallery',
          subtitle: 'Pick front and back photos from your device.',
          onTap: () => onSelect(CardEditMethod.gallery),
        ),
        const SizedBox(height: 12),
        _ChoiceTile(
          icon: LucideIcons.edit3,
          title: 'Enter manually',
          subtitle: 'Type the details yourself, no photo needed.',
          onTap: () => onSelect(CardEditMethod.manual),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VCareColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: VCareColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.frontPath,
    required this.backPath,
    required this.extracting,
    required this.onPickFront,
    required this.onPickBack,
    required this.onClearFront,
    required this.onClearBack,
    required this.onRunExtraction,
  });

  final String? frontPath;
  final String? backPath;
  final bool extracting;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final VoidCallback onClearFront;
  final VoidCallback onClearBack;
  final VoidCallback onRunExtraction;

  @override
  Widget build(BuildContext context) {
    final bothCaptured = frontPath != null && backPath != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PhotoSlot(
                label: 'Front',
                hasPath: frontPath != null,
                onPick: onPickFront,
                onClear: onClearFront,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhotoSlot(
                label: 'Back',
                hasPath: backPath != null,
                onPick: onPickBack,
                onClear: onClearBack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!bothCaptured)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Capture both front and back for the most accurate AI read.',
              style: TextStyle(
                fontSize: 11,
                color: context.vcare.mutedForeground.withValues(alpha: 0.8),
              ),
            ),
          ),
        const SizedBox(height: 16),
        _ExtractionButton(
          enabled: bothCaptured && !extracting,
          loading: extracting,
          onTap: onRunExtraction,
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.hasPath,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final bool hasPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: vcare.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: vcare.border,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPath
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: vcare.muted,
                          child: const Icon(LucideIcons.image, size: 32),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: onPick,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.camera,
                          color: vcare.mutedForeground,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add $label',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: vcare.mutedForeground,
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

class _ExtractionButton extends StatelessWidget {
  const _ExtractionButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: context.vcare.border),
          backgroundColor: context.vcare.card,
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.sparkles, size: 16),
                  const SizedBox(width: 8),
                  const Text('Extract details with AI'),
                ],
              ),
      ),
    );
  }
}

class _CardFormFields extends StatelessWidget {
  const _CardFormFields({
    required this.titleController,
    required this.issuerController,
    required this.memberIdController,
    required this.notesController,
  });

  final TextEditingController titleController;
  final TextEditingController issuerController;
  final TextEditingController memberIdController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormInput(
          controller: titleController,
          label: 'Title',
          hint: 'e.g. Blue Cross PPO',
        ),
        const SizedBox(height: 16),
        _FormInput(
          controller: issuerController,
          label: 'Issuer (optional)',
          hint: 'e.g. Anthem, Delta Dental',
        ),
        const SizedBox(height: 16),
        _FormInput(
          controller: memberIdController,
          label: 'Member / Policy ID (optional)',
          hint: 'e.g. XJK123456789',
        ),
        const SizedBox(height: 16),
        _FormInput(
          controller: notesController,
          label: 'Notes (optional)',
          hint: 'Group, RX BIN, phone...',
          maxLines: 3,
        ),
      ],
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: vcare.mutedForeground.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.vcare.mutedForeground,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: VCareColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
