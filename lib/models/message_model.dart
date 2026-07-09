import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderRole;
  final DateTime? timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.timestamp,
    required this.read,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    // El backend guarda el timestamp como Firestore Timestamp o como String ISO.
    // Cuando viene por REST puede ser un Map con _seconds/_nanoseconds.
    DateTime? ts;
    final raw = data['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is Map) {
      // Firestore Timestamp serializado como JSON: { "_seconds": N, "_nanoseconds": N }
      final secs = raw['_seconds'] ?? raw['seconds'];
      if (secs != null) {
        ts = DateTime.fromMillisecondsSinceEpoch((secs as int) * 1000,
            isUtc: true);
      }
    } else if (raw is String) {
      ts = DateTime.tryParse(raw);
    }

    return MessageModel(
      id: id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      // El backend guarda 'rol'; fallback a 'senderRole' por compatibilidad
      senderRole: data['rol'] ?? data['senderRole'] ?? '',
      timestamp: ts,
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'rol': senderRole,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'read': read,
    };
  }
}
