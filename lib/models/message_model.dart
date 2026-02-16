import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String fromUid;
  final String toUid;
  final DateTime? timestamp;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.text,
    required this.fromUid,
    required this.toUid,
    this.timestamp,
    this.readAt,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      text: map['text'] ?? '',
      fromUid: map['from'] ?? '',
      toUid: map['to'] ?? '',
      timestamp: (map['ts'] as Timestamp?)?.toDate(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'from': fromUid,
      'to': toUid,
      'ts': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}
