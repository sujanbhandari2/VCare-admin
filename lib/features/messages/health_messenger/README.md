# Health Messenger integration (VCare Admin)

This folder hosts the **Messages** tab integration with the local `health_messenger_ui` package (`chat_app_package`). Production UX is **Live Chat** (`LiveChatScreen`); the older mock `MessagesScreen` remains in-tree but is no longer routed from the bottom nav.

Bootstrap role defaults to **`AGENT`** when no admin role is available (client app uses `CLIENT`).

Identity for chat bootstrap (aligned with admin web identify):

| Field | Source |
|-------|--------|
| API / socket / key | `.env` via `HealthMessengerEnv` |
| `externalTenantId` | Prefer `adminAuthSessionProvider.user.currentTenant.id`, then `auth/me` tenant, then `StorageKeys.loggedInUserTenantId` (+ flavor prefix) |
| `externalUserId` | Prefer `StorageKeys.loggedInUserUuid` (set on admin login + `auth/me`), then admin session `user.id`, then `loggedInUserProfileId`, then legacy int id |
| `email` / display name | Auth storage, then admin session, then optional `UserProfile` |
| `externalUserRole` | Prefer `adminAuthSessionProvider.user.currentRoles[0]`, else default `AGENT` |

Session lifecycle:

| Event | Action |
|-------|--------|
| Authenticated shell mounts | `fetchMe` then `healthMessengerSessionProvider.ensureStarted()` |
| Messages tab opens | `HealthMessengerChatNotifier.bootstrap()` |
| Logout | `stopSession()` from `clearUserSession` |

Push (FCM) is wired after session bootstrap via `HealthMessengerPush` when Firebase is initialized; chat still works without push.
