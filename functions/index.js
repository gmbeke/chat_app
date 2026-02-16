const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onMessageCreate = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const msg = snap.data();
        const toUid = msg.to;
        const fromUid = msg.from;
        if (!toUid) return null;

        const userDoc = await admin.firestore().doc(`users/${toUid}`).get();
        const token = userDoc.exists ? userDoc.data()?.fcmToken : null;
        if (!token) return null;

        const senderDoc = await admin.firestore().doc(`users/${fromUid}`).get();
        const senderName = senderDoc.exists ? senderDoc.data()?.displayName : 'New Message';

        const message = {
            token: token,
            notification: {
                title: senderName,
                body: msg.text,
            },
            data: {
                chatId: context.params.chatId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'chat_messages',
                },
            },
        };

        try {
            await admin.messaging().send(message);
            console.log('Successfully sent message:', message);
        } catch (error) {
            console.log('Error sending message:', error);
        }
        return null;
    });

exports.onStatusWrite = functions.database
    .ref('/status/{uid}')
    .onWrite(async (change, context) => {
        const val = change.after.val();
        if (!val) return null;
        const uid = context.params.uid;
        return admin.firestore().doc(`users/${uid}`).set({
            online: !!val.online,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
