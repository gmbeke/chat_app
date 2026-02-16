import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final String identificationNumber;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    required this.identificationNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final String email = map['email'] ?? '';
    final String displayName = map['displayName'] ?? '';

    return UserModel(
      uid: map['uid'] ?? '',
      displayName: displayName.isEmpty ? email : displayName,
      email: email,
      photoUrl: map['photoUrl'],
      isOnline: map['online'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'],
      identificationNumber: map['identificationNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'online': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
      'identificationNumber': identificationNumber,
    };
  }
}
