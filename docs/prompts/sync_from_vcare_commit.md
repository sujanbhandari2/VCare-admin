Sync Flutter with vcare-agent-app-2.0 (mobile UI) updates.

Source repo: `vcareAdmin-web/vcare-agent-app-2.0`  
Target repo: `vcare2.0-admin`

Commit range: `{{FROM_COMMIT}}..{{TO_COMMIT}}`  
Feature scope: `{{FEATURE_SCOPE}}`

Use these generated artifacts:
- `docs/sync/last_sync_changed_files.txt`
- `docs/sync/last_sync_commit_log.txt`
- `docs/sync/last_sync_web.diff`

Reference docs:
- `docs/sync/ui_design_sync_reference.md`
- `docs/sync/ui_sync_agent_rule.md`
- `Agents.md`

Tasks:
1) Analyze all source changes in the commit range.
2) Map each relevant web change to Flutter equivalents (mobile view only).
3) Implement only parity updates relevant to the selected feature scope.
4) Follow architecture + naming conventions from `Agents.md`.
5) Run formatter and lint checks on touched Flutter files.
6) Summarize:
   - synced items
   - intentionally skipped items
   - manual follow-ups needed
7) Avoid unrelated refactors or cleanup outside this sync.

Generate audit artifacts first:
```bash
./scripts/sync_audit.sh {{FROM_COMMIT}} {{TO_COMMIT}}
```
