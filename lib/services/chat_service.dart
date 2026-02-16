import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String uid1, String uid2) {
    return (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('ts', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> markAsRead(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'readAt': FieldValue.serverTimestamp()});
  }

  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList(),
        )
        .handleError((error) {
          print('Error fetching users: $error');
          return <UserModel>[];
        });
  }

  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting user by UID ($uid): $e');
    }
    return null;
  }

  Future<UserModel?> getUserByIdentification(String idNumber) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('identificationNumber', isEqualTo: idNumber)
          .limit(1)
          .get();
      if (result.docs.isNotEmpty) {
        return UserModel.fromMap(result.docs.first.data());
      }
    } catch (e) {
      print('Error getting user by ID number ($idNumber): $e');
    }
    return null;
  }
}
