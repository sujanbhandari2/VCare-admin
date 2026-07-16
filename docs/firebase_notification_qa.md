# Firebase Notification Manual QA

## Prerequisites

- Physical device or emulator with Google Play services (Android) or APNs configured (iOS)
- Valid backend credentials and FCM device/inbox endpoints deployed
- Firebase project linked to the active flavor (`google-services.json` / `GoogleService-Info.plist`)

## Test Matrix

| Scenario | Steps | Expected |
|----------|-------|----------|
| Fresh install Android 13+ | Install app, log in, reach main shell | Permission prompt appears; FCM token registers after login |
| Foreground push (Android) | Send FCM with `notification` payload while app is open | Local notification appears in tray with title/body |
| Background push | Send FCM while app is backgrounded | Notification appears; tapping opens app (no route jump yet) |
| Killed-state push | Send FCM while app is terminated | Notification appears; tapping launches app |
| Login token sync | Log in after granting permission | `fcm-device-register/` or `fcm-device-update/` called once per user/token change |
| User switch | Log out and log in as different user | Token re-synced for new user |
| Logout cleanup | Trigger session expiry or logout | FCM sync keys cleared; best-effort `DELETE fcm-device/` sent |
| Notifications screen | Open Profile → Notifications | Inbox loads from `GET notifications/` with loading/error/empty states |
| Mark as read | Tap unread inbox item | `POST notifications/{id}/read/` called; unread dot removed; badge count decreases |
| Home badge | Return to home after reading notifications | Bell badge reflects `notifications/unread-count/` or derived count |
| Permission denied | Deny notification permission | Open-app listeners still wired; token sync skipped until permission granted |

## Payload Notes

- Android foreground/background local notifications include `message.data` as JSON payload for future deep-linking.
- Push tap routing is intentionally deferred; logs only when non-empty data is received.

## iOS Checklist (manual)

- Push Notifications capability enabled in Xcode
- `remote-notification` background mode present in `Info.plist`
- APNs auth key uploaded to Firebase Console for the project
