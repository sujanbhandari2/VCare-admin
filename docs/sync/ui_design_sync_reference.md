# UI Design Sync Reference

Source of truth for mobile UI parity between the agent web app and Flutter.

| | Path |
|---|---|
| **Web (mobile source)** | `vcareAdmin-web/vcare-agent-app-2.0` |
| **Flutter target** | `vcare2.0-admin` |
| **Architecture** | `Agents.md`, `docs/feature_implementation_reference.md` |

## Token mapping (index.css → Flutter)

| CSS variable | HSL / value | `VCareColors` | Notes |
|---|---|---|---|
| `--background` | `0 0% 100%` | `background` | Scaffold |
| `--foreground` | `181 47% 17%` | `foreground` | Body text |
| `--card` | `220 16% 98.5%` | `card` | Cards, nav pill |
| `--primary` | `181 100% 31%` | `primary` | Teal brand |
| `--secondary` / `--accent` | `20 82% 55%` | `secondary`, `accent` | Terracotta |
| `--muted` | `220 14% 95%` | `muted` | Subtle fills |
| `--muted-foreground` | `181 25% 32%` | `mutedForeground` | Secondary text |
| `--success` | `160 60% 40%` | `success` | Success states |
| `--destructive` | `0 70% 55%` | `destructive` | Errors |
| `--border` | `220 13% 94%` | `border` | Dividers |
| `--teal-light` | `181 30% 95%` | `tealLight` | Tint surfaces |
| `--terracotta-light` | `20 60% 96%` | `terracottaLight` | Warm tint |
| `--radius` | `1rem` | `radius` (16) | Base radius |
| Login card inline | `#fbfbfc` | `loginCardSurface` | Auth card only |

## Gradient mapping

| CSS utility | `VCareColors` |
|---|---|
| `--gradient-hero` | `gradientHero` |
| `--gradient-teal` | `gradientTeal` |
| `--gradient-card` | `gradientCard` |
| `--gradient-warm` | `gradientWarm` |
| `--gradient-sunset` | `gradientSunset` |
| `--gradient-action` | `gradientAction` |

## Mobile layout constants

| Web (Tailwind) | Flutter (`VCareLayout`) | Value |
|---|---|---|
| `px-5` | `pageHorizontalPadding` | 20 |
| `rounded-2xl` | `cardRadius2xl` | 16 |
| `rounded-3xl` | `cardRadius3xl` | 24 |
| `rounded-[2rem]` | `loginCardRadius` | 32 |
| Bottom nav max width | `bottomNavMaxWidth` | 480 |
| Home FAB | `bottomNavHomeFabSize` | 52 |
| Bottom nav pill radius | `bottomNavPillRadius` | 26 |
| Sheet top radius | `sheetTopRadius` | 24 |
| Mobile breakpoint | `mobileBreakpoint` | 768 |

## Shadow policy

Web `index.css` disables all shadows globally. Flutter parity:

- Use `elevation: 0` and no `BoxShadow` on cards, login shell, bottom nav, referral card.
- Elevation comes from surface contrast (`background` vs `card`) and borders only.
- Use `VCareShadows.none` when a decoration requires an explicit empty shadow list.

## Shell component mapping

| Web | Flutter |
|---|---|
| `src/components/MobileShell.tsx` | `features/main_wrapper/.../vcare_bottom_navigation.dart` |
| `src/components/PageHeader.tsx` | `shared/widgets/vcare_page_header.dart` |
| `src/features/home/components/HomePageHeader.tsx` | `features/home/.../home_page_header.dart` |
| `src/features/auth/components/LoginShell.tsx` | `features/auth/.../login_shared_widgets.dart` |
| `src/components/StickySearchBar.tsx` | `shared/widgets/vcare_sticky_search_bar.dart` |

## Feature screen mapping (mobile)

| Web route | Web file | Flutter file |
|---|---|---|
| `/login` | `pages/Login.tsx` | `features/auth/.../vcare_login_screen.dart` |
| `/` | `pages/Home.tsx` | `features/home/.../home_screen.dart` |
| `/clients` | `pages/Clients.tsx` | `features/clients/.../clients_screen.dart` |
| `/home/id-card` | `pages/IdCard.tsx` | `features/home/.../id_card_screen.dart` |
| Referral card | `features/id-card/components/VCareReferralCard.tsx` | `features/home/.../vcare_referral_card.dart` |

## Sync workflow

1. Run `scripts/sync_audit.sh FROM_COMMIT TO_COMMIT` to generate diff artifacts.
2. Read changed web files under `src/` (mobile: ignore `md:` desktop-only blocks).
3. Update `VCareColors` / `VCareLayout` before widgets.
4. Implement in `lib/features/<feature>/presentation/widgets/`.
5. Annotate: `// parity: vcare-agent-app-2.0/<web-path>`
6. Run `dart format` + `flutter analyze` on touched files.
7. Update `docs/sync/vcare_last_synced_commit.txt`.

## Intentionally deferred

- Add Client drawer (`AddClientDrawer.tsx`) — separate phase
- Desktop sidebar (`md+` in `MobileShell.tsx`)
- `/commissions`, `/billings/pending` routes
- `vcare_parity_screens.dart` monolith migration

## Forgot password route

Legacy `/forgot_password` redirects to `/login` with in-flow forgot steps (web parity).
