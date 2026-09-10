# ConnectCall — Architecture & Tech Stack Plan

## 1. Tech Stack Decision

| Layer | Choice | Why |
|---|---|---|
| **Calling SDK** | **Agora RTC (agora_rtc_engine)** | Generous free tier (10,000 min/month), excellent Flutter SDK with a clean high-level API, handles the messy parts of WebRTC (NAT traversal, signaling, reconnection) for you, and is one of the most commonly expected answers in these assignments — reviewers know it well, which makes the "why did you choose X" interview question easy to answer credibly. Raw WebRTC is more impressive on paper but is a multi-week signaling/STUN/TURN project on its own — too risky for an internship timeline. |
| **Auth + Backend** | **Firebase** (Auth + Cloud Firestore + Cloud Functions for call signaling triggers) | One SDK covers auth, database, and push notifications (FCM) — minimizes moving parts. Firestore's real-time listeners are perfect for "incoming call" documents and online/offline presence. |
| **State Management** | **Riverpod** | Testable, no BuildContext needed for reading state (useful in services), compile-safe providers, easy to explain in an interview ("providers expose services/streams, widgets watch them, no boilerplate classes like Bloc"). |
| **Push notifications (bonus)** | **Firebase Cloud Messaging** | Needed to wake the app for incoming calls when backgrounded — pairs naturally with Firebase backend. |
| **Local call ringing UI (bonus)** | `flutter_callkit_incoming` | Gives native-feeling full-screen incoming call UI even when app is backgrounded/killed — a strong bonus-marks item. |

**Alternative considered:** LiveKit (self-hosted, more control, but requires you to run/maintain a server — adds ops overhead not worth it for this timeline). Stream Video is also solid but Agora's free tier and docs are the easiest path to a working demo fast.

---

## 2. High-Level System Flow

1. **Auth**: Firebase Auth (email/password). On successful login, create/update a `users/{uid}` Firestore doc with `name`, `email`, `photoUrl`, `isOnline`, `lastSeen`.
2. **Presence**: Update `isOnline` on app lifecycle changes (`AppLifecycleState`) and on connect/disconnect (Firestore `onDisconnect`-style pattern isn't native to Firestore like RTDB — so either use **Realtime Database just for presence**, or approximate with periodic heartbeat + `lastSeen` timestamp).
3. **Call signaling** (this is the part people get wrong — Agora handles media, NOT call setup):
   - Caller writes a doc to `calls/{callId}` with `callerId`, `calleeId`, `channelName`, `type` (audio/video), `status: "ringing"`.
   - Callee's app listens to `calls` where `calleeId == myUid && status == "ringing"` → shows Incoming Call screen.
   - Callee accepts → updates `status: "accepted"` → both sides join the Agora channel using `channelName`.
   - Callee rejects → `status: "rejected"` → caller's listener reacts, shows "Call declined."
   - Either side ends → `status: "ended"`, write `duration`, `endedAt` → both leave Agora channel → write to `call_history`.
4. **Call History**: A Firestore collection populated when a call ends, queried per-user, sorted by timestamp, with `type`, `direction` (incoming/outgoing), `duration`, `missed` flag.

---

## 3. Call State Machine (what you'll actually implement)

```
idle → calling → ringing (remote) → connected → in_call → ended
                              ↘ rejected
                    (timeout) ↘ missed
                     (no net) ↘ failed
```

Model this as an enum + a single `CallSession` object held in a Riverpod `StateNotifier`, not scattered booleans. This is the #1 thing reviewers probe on ("how do you detect when a call ends") — being able to point to one state machine, not five `if` flags, will make that answer effortless.

---

## 4. Folder Structure (adapted from the brief)

```
lib/
├── core/
│   ├── constants/          # channel name generation, collection names
│   ├── theme/               # light + dark ThemeData
│   └── utils/                # permission helpers, duration formatters
├── models/
│   ├── user_model.dart
│   ├── call_model.dart
│   └── call_state.dart      # enum + CallSession class
├── services/
│   ├── auth_service.dart     # Firebase Auth wrapper
│   ├── user_service.dart     # Firestore user CRUD + presence
│   ├── call_signaling_service.dart   # Firestore call docs, listeners
│   └── agora_service.dart    # Agora engine init, join/leave, mute, camera
├── providers/                # Riverpod providers wiring services → UI
├── screens/
│   ├── splash/
│   ├── auth/ (login, register)
│   ├── home/
│   ├── contacts/
│   ├── profile/
│   ├── call/ (audio_call_screen, video_call_screen, incoming_call_screen)
│   └── history/
├── widgets/
│   ├── user_tile.dart
│   ├── call_button.dart
│   └── common_button.dart
└── main.dart
```

---

## 5. Suggested Build Order (so you always have something demoable)

1. Firebase project setup + Auth (login/register/logout) → Splash/Login/Home shell
2. Firestore user list + presence + Contacts screen
3. Call signaling service (Firestore docs) + Incoming Call screen listener — **test this before touching Agora**, since it's the trickiest logic
4. Agora integration for audio calls only (mute, speaker, end)
5. Extend to video (camera toggle, switch camera)
6. Call history writes + history screen
7. Permission handling + error/empty/loading states polish
8. Bonus features if time remains (dark mode and FCM push notifications are the best marks-per-hour)

---

## 6. Risks / Things to Get Right Early

- **Agora App ID + token server**: Agora requires a token for secure channels. For a demo you can use the "temp token" from the Agora console (expires in 24h) to avoid building a token server — mention this as a known limitation in your README.
- **Permissions**: request mic/camera *before* joining the Agora channel, not after — handle denied/permanently-denied with a dialog directing to app settings.
- **Missed call detection**: if the callee doesn't respond within N seconds (e.g. 30s), the caller-side should auto-transition the call doc to `status: "missed"` — implement this as a `Future.delayed` cancelable timer tied to the call session, not a server-side function (keeps it simple for this scope).

---

## Next Steps

Once you're happy with this plan, I can scaffold the actual Flutter project — starting with `pubspec.yaml`, the models, and the auth flow — and we can build it screen by screen.
