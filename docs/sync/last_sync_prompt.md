# Last UI sync (2026-06-23)

Scope: ui, theme, auth, referral

## Synced
- Design token foundation (`VCareColors`, `VCareLayout`, extended `VCare ThemeExtension`)
- Login shell flat white layout with logo above card
- Bottom nav metrics (52px FAB, 26px pill radius, no shadow)
- In-login forgot password flow (4 steps)
- Referral card editable slug with local persistence
- Sync documentation and audit script

## Skipped
- Add Client drawer (explicit deferral)
- Desktop sidebar
- Commissions / billings routes

## Manual follow-ups
- Side-by-side visual QA at 390x844 against web devtools
- Wire referral slug into share actions if API slug endpoint lands
