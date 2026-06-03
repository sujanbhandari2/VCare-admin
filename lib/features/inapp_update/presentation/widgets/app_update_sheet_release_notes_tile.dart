import 'package:flutter/material.dart';

import '../../../../shared/utils/extension_functions.dart';
import '../../../../shared/widgets/custom_expansion_builder.dart';
import '../../domain/entities/remote_config_app_update_info.dart';

class AppUpdateSheetReleaseNotesTile extends StatelessWidget {
  const AppUpdateSheetReleaseNotesTile({super.key, required this.info});

  final RemoteConfigAppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    return CustomExpansionBuilder(
      initiallyExpanded: false,
      builder: (_, animation, expanded, onToggle) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.appLocalization.whats_new,
                style: context.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${context.appLocalization.updated_on} '
                '${info.releaseDate?.toddMMMYYYY ?? info.releaseDate ?? ''}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                onPressed: onToggle,
                splashRadius: 24,
                padding: EdgeInsets.zero,
                icon: RotatedBox(
                  quarterTurns: expanded ? 2 : 0,
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ),
            Flexible(
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: Text(
                  info.releaseNotes ?? '',
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
