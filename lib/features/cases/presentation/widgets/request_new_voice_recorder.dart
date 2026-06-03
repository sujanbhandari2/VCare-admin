import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/cases/presentation/widgets/request_new_dashed_border.dart';

/// Parity with vcareapp `VoiceRecorder` (non-compact) on request new step 3.
class RequestNewVoiceRecorder extends StatefulWidget {
  const RequestNewVoiceRecorder({super.key, required this.onRecorded});

  final void Function({
    required String name,
    required String dataUrl,
    required int size,
  })
  onRecorded;

  @override
  State<RequestNewVoiceRecorder> createState() =>
      _RequestNewVoiceRecorderState();
}

class _RequestNewVoiceRecorderState extends State<RequestNewVoiceRecorder> {
  bool _recording = false;
  int _elapsedMs = 0;

  String _formatTime(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _start() {
    setState(() {
      _recording = true;
      _elapsedMs = 0;
    });
  }

  void _stop({required bool save}) {
    if (save) {
      widget.onRecorded(
        name: 'Voice note ${_formatTime(_elapsedMs)}.m4a',
        dataUrl: 'data:audio/mp4;base64,',
        size: 12000,
      );
    }
    setState(() {
      _recording = false;
      _elapsedMs = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    if (_recording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VCareColors.destructive.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VCareColors.destructive.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: VCareColors.destructive,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Recording…',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(_elapsedMs),
              style: TextStyle(
                fontSize: 14,
                color: vcare.mutedForeground,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _stop(save: false),
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: vcare.mutedForeground,
              ),
              visualDensity: VisualDensity.compact,
            ),
            FilledButton.icon(
              onPressed: () => _stop(save: true),
              style: FilledButton.styleFrom(
                backgroundColor: VCareColors.destructive,
                foregroundColor: VCareColors.destructiveForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(LucideIcons.square, size: 14),
              label: const Text('Stop', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Material(
      color: vcare.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _start,
        borderRadius: BorderRadius.circular(16),
        child: RequestNewDashedBorder(
          color: vcare.border,
          radius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(LucideIcons.mic, size: 20, color: vcare.mutedForeground),
                const SizedBox(height: 6),
                Text(
                  'Voice note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: vcare.mutedForeground,
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
