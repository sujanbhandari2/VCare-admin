# UI Sync Agent Rule

When syncing mobile UI from `vcareAdmin-web/vcare-agent-app-2.0` to `vcare2.0-admin`:

1. Read the web component first. Target mobile behavior (`<768px`, bottom sheets, `px-5`).
2. Update design.tokens in `lib/core/styles/vcare_colors.dart` before touching widgets.
3. Keep feature UI in `lib/features/<feature>/presentation/widgets/`.
4. Move to `lib/shared/widgets/` only after a second real usage.
5. Follow `Agents.md` 3-layer architecture for new state/API work.
6. Use `OperationState<T>` + Riverpod notifiers for async UI state.
7. No shadows on cards/nav/login unless web explicitly uses inline shadow.
8. Annotate parity: `// parity: vcare-agent-app-2.0/<path>`.
9. Do not refactor unrelated features during a sync.
10. Update `docs/sync/ui_design_sync_reference.md` when adding new token or component mappings.
