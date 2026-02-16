Functions setup

1. Install dependencies

```bash
cd functions
npm install
```

2. Deploy functions (requires firebase CLI and project configured)

```bash
firebase deploy --only functions
```

What the functions do:
- `onMessageCreate`: when a Firestore message is created under `chats/{chatId}/messages`, the function looks up the recipient's `fcmToken` in `users/{uid}` and sends an FCM notification.
- `onStatusWrite`: mirrors Realtime Database `/status/{uid}` changes into `users/{uid}` Firestore documents (`online` and `lastSeen`).

Notes:
- Make sure your Firebase project has both Firestore and Realtime Database enabled.
- Deploying these functions requires the Firebase project to be set (`firebase use <project>`).
