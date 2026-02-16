import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  void startTracking() {
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
  }

  void stopTracking() {
    WidgetsBinding.instance.removeObserver(this);
    _updateStatus(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else {
      _updateStatus(false);
    }
  }

  Future<void> _updateStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final usersDoc = _firestore.collection('users').doc(user.uid);
    final statusRef = _database.ref('status/${user.uid}');

    if (isOnline) {
      await usersDoc.set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await statusRef.set({'online': true, 'lastSeen': ServerValue.timestamp});
      statusRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } else {
      await usersDoc.set({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await statusRef.set({'online': false, 'lastSeen': ServerValue.timestamp});
    }
  }

  Stream<bool> isUserOnline(String uid) {
    return _database.ref('status/$uid/online').onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }
}
