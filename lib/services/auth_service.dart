import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _syncUserProfile(cred.user!, displayName: displayName);
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _syncUserProfile(cred.user!);
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'configuration-not-found':
        print('Error: Firebase Check SHA-1 fingerprint in Console.');
        break;
      case 'invalid-credential':
        print('Error: Invalid email or password.');
        break;
      case 'user-not-found':
        print('Error: No user found for this email.');
        break;
      case 'wrong-password':
        print('Error: Wrong password.');
        break;
      case 'email-already-in-use':
        print('Error: The email address is already in use by another account.');
        break;
      default:
        print('FirebaseAuth Error (${e.code}): ${e.message}');
    }
  }

  Future<void> ensureUserExists() async {
    if (currentUser != null) {
      await _syncUserProfile(currentUser!);
    }
  }

  Future<void> _syncUserProfile(User user, {String? displayName}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();

      final fcmToken = await NotificationService().getToken();

      // If doc doesn't exist or is missing identificationNumber OR token is different, populate/update it
      if (!userDoc.exists ||
          data == null ||
          data['identificationNumber'] == null ||
          data['fcmToken'] != fcmToken) {
        final idNumber =
            data?['identificationNumber'] ?? await _generateUniqueIdNumber();

        final userModel = UserModel(
          uid: user.uid,
          displayName:
              displayName ??
              user.displayName ??
              data?['displayName'] ??
              user.email ??
              '',
          email: user.email ?? data?['email'] ?? '',
          photoUrl: user.photoURL ?? data?['photoUrl'],
          identificationNumber: idNumber,
          fcmToken: fcmToken,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap(), SetOptions(merge: true));

        print('User profile synced with FCM token: ${user.uid}');
      }
    } catch (e) {
      print('Error syncing user profile: $e');
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('User profile updated for: $uid');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String> _generateUniqueIdNumber() async {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded similar looking chars like I, O, 1, 0
    final rnd = Random();
    String code;
    bool exists = true;

    do {
      code = List.generate(
        6,
        (index) => chars[rnd.nextInt(chars.length)],
      ).join();
      print('Checking ID uniqueness for: $code...');
      try {
        final result = await _firestore
            .collection('users')
            .where('identificationNumber', isEqualTo: code)
            .get();
        exists = result.docs.isNotEmpty;
      } catch (e) {
        print('Error checking unique ID: $e');
        rethrow;
      }
    } while (exists);

    return code;
  }
}
