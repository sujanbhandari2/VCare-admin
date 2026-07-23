# Health Messenger integration (VCare Admin)

This folder hosts the **Messages** tab integration with the local `health_messenger_ui` package (`chat_app_package`). Production UX is **Live Chat** (`LiveChatScreen`); the older mock `MessagesScreen` remains in-tree but is no longer routed from the bottom nav.

Bootstrap role defaults to **`AGENT`** (client app uses `CLIENT`).

Identity for chat bootstrap:

| Field | Source |
|-------|--------|
| API / socket / key | `.env` via `HealthMessengerEnv` |
| `externalTenantId` | `user.currentTenant.id` from login / `auth/me` (+ flavor prefix) |
| `externalUserId` | `StorageKeys.loggedInUserUuid` (from `auth/me` / login) |
| `email` / display name | Auth storage + optional `UserProfile` |
| `externalUserRole` | Default `AGENT` |

Session lifecycle:

| Event | Action |
|-------|--------|
| Authenticated shell mounts | `fetchMe` then `healthMessengerSessionProvider.ensureStarted()` |
| Messages tab opens | `HealthMessengerChatNotifier.bootstrap()` |
| Logout | `stopSession()` from `clearUserSession` |

Push (FCM) is wired after session bootstrap via `HealthMessengerPush` when Firebase is initialized; chat still works without push.
