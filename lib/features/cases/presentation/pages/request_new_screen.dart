import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_new_footer.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_new_progress.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_new_step_attachments.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_new_step_category.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/request_new_step_description.dart';
import 'package:vcare_admin/features/cases/utils/request_new_utils.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class RequestNewScreen extends StatefulWidget {
  const RequestNewScreen({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  State<RequestNewScreen> createState() => _RequestNewScreenState();
}

class _RequestNewScreenState extends State<RequestNewScreen> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  int _step = 1;
  String _selectedType = '';
  final List<RequestAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      _descriptionController.text = prompt;
    }
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? get _suggestedType {
    final text = _descriptionController.text;
    if (text.trim().length < 8) return null;
    return suggestRequestType(text);
  }

  void _appendVoiceTranscript() {
    const sample =
        "I got a \$4,200 ER bill from St. Mary's and some charges look duplicated.";
    final current = _descriptionController.text;
    final next = current.isEmpty
        ? sample
        : '$current ${current.endsWith(' ') ? '' : ' '}$sample';
    _descriptionController.text = next.length > requestNewMaxDescriptionLength
        ? next.substring(0, requestNewMaxDescriptionLength)
        : next;
    _descriptionController.selection = TextSelection.collapsed(
      offset: _descriptionController.text.length,
    );
  }

  void _addAttachment({
    required String name,
    required String dataUrl,
    required int size,
  }) {
    setState(() {
      _attachments.add(
        RequestAttachment(
          id: 'att-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          dataUrl: dataUrl,
          size: size,
        ),
      );
    });
  }

  Future<void> _onFileBytes({
    required String name,
    required List<int> bytes,
    required String mime,
  }) async {
    if (bytes.length > requestNewMaxAttachmentBytes) {
      _showError('Max 5MB per file.');
      return;
    }
    final baseName = name.trim().isEmpty ? 'attachment' : name;
    final displayName = mime.startsWith('image/')
        ? '${baseName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg'
        : baseName;
    _addAttachment(
      name: displayName,
      dataUrl: 'data:$mime;base64,${base64Encode(bytes)}',
      size: bytes.length,
    );
  }

  Future<void> _pickImage({required ImageSource source}) async {
    final image = await _picker.pickImage(source: source);
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    await _onFileBytes(name: image.name, bytes: bytes, mime: 'image/jpeg');
  }

  Future<void> _pickFile() async {
    const typeGroups = [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'],
        mimeTypes: ['image/*'],
      ),
      XTypeGroup(
        label: 'Documents',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
      ),
      XTypeGroup(
        label: 'Audio',
        extensions: ['mp3', 'm4a', 'wav', 'webm', 'ogg', 'aac'],
        mimeTypes: ['audio/*'],
      ),
    ];
    final file = await openFile(acceptedTypeGroups: typeGroups);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final mime = _mimeForFile(file.name);
    await _onFileBytes(name: file.name, bytes: bytes, mime: mime);
  }

  String _mimeForFile(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'pdf' => 'application/pdf',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'wav' => 'audio/wav',
      'webm' => 'audio/webm',
      'ogg' => 'audio/ogg',
      'aac' => 'audio/aac',
      _ => 'application/octet-stream',
    };
  }

  void _addVoiceAttachment({
    required String name,
    required String dataUrl,
    required int size,
  }) {
    _addAttachment(name: name, dataUrl: dataUrl, size: size);
  }

  void _showError(String message) {
    context.showVcareToast(
      title: message,
      variant: VcareToastVariant.destructive,
    );
  }

  void _goNext() {
    if (_step == 1) {
      if (_descriptionController.text.trim().length < 5) {
        _showError('Describe what you need help with.');
        return;
      }
      if (_selectedType.isEmpty && _suggestedType != null) {
        setState(() => _selectedType = _suggestedType!);
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      final effectiveType = _selectedType.isEmpty
          ? (_suggestedType ?? '')
          : _selectedType;
      if (effectiveType.isEmpty) {
        _showError('Choose what best fits your need.');
        return;
      }
      if (_selectedType.isEmpty) {
        setState(() => _selectedType = effectiveType);
      }
      setState(() => _step = 3);
    }
  }

  void _goBack() {
    if (_step > 1) setState(() => _step -= 1);
  }

  void _submit() {
    if (_selectedType.isEmpty) return;
    context.showVcareToast(
      title: 'Request submitted',
      description: 'Your advocate will respond soon.',
      variant: VcareToastVariant.success,
    );
    context.goNamed(AppRouter.requests.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    final displayType = _selectedType.isEmpty
        ? (_suggestedType ?? '')
        : _selectedType;

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: 'New request',
            showBack: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RequestNewProgress(step: _step),
                  const SizedBox(height: 20),
                  if (_step == 1)
                    RequestNewStepDescription(
                      controller: _descriptionController,
                      onSpeakInstead: _appendVoiceTranscript,
                      onFieldVoiceAction: _appendVoiceTranscript,
                    ),
                  if (_step == 2)
                    RequestNewStepCategory(
                      selectedType: displayType,
                      suggestedType: _suggestedType,
                      onTypeSelected: (value) =>
                          setState(() => _selectedType = value),
                    ),
                  if (_step == 3)
                    RequestNewStepAttachments(
                      attachments: _attachments,
                      description: _descriptionController.text,
                      categoryValue: _selectedType,
                      onPickImage: () => _pickImage(source: ImageSource.camera),
                      onPickFile: _pickFile,
                      onVoiceRecorded: _addVoiceAttachment,
                      onRemove: (id) => setState(
                        () => _attachments.removeWhere((a) => a.id == id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          RequestNewFooter(
            step: _step,
            onBack: _goBack,
            onContinue: _goNext,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
