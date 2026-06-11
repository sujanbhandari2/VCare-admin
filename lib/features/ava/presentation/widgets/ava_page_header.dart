import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

/// Sticky frosted header matching vcareapp [AvaPageHeader] + [PageHeader].
class AvaPageHeader extends StatelessWidget {
  const AvaPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final safeTop = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(color: background.withValues(alpha: 0.95)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: safeTop),
              const VcarePageHeader(
                title: 'AVA',
                subtitle: 'Advocate Virtual Assistant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
