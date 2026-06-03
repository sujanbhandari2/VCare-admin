Sync Flutter with vcareapp updates.

Source repo: `/Users/sujan/Desktop/vcare2.0/vcareapp`  
Target repo: `/Users/sujan/Desktop/vcare2.0/flutter_template-enhancement`

Commit range: `{{FROM_COMMIT}}..{{TO_COMMIT}}`  
Feature scope: `{{FEATURE_SCOPE}}`

Use these generated artifacts:
- `docs/sync/last_sync_changed_files.txt`
- `docs/sync/last_sync_commit_log.txt`
- `docs/sync/last_sync_web.diff`

Tasks:
1) Analyze all source changes in the commit range.
2) Map each relevant web change to Flutter equivalent files and widgets.
3) Implement only parity updates relevant to the selected feature scope.
4) Follow architecture + naming conventions from `Agents.md`.
5) Run formatter and lint checks on touched Flutter files.
6) Summarize:
   - synced items
   - intentionally skipped items
   - manual follow-ups needed
7) Avoid unrelated refactors or cleanup outside this sync.
