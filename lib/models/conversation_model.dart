import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String serviceId;
  final String clientId;
  final String workerId;
  final String clientName;
  final String workerName;
  final int unreadClient;
  final int unreadWorker;
  final String lastMessage;
  final DateTime? lastAt;

  ConversationModel({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.workerId,
    required this.clientName,
    required this.workerName,
    required this.unreadClient,
    required this.unreadWorker,
    required this.lastMessage,
    this.lastAt,
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> data) {
    return ConversationModel(
      id: id,
      serviceId: data['serviceId'] ?? '',
      clientId: data['clientId'] ?? '',
      workerId: data['workerId'] ?? '',
      clientName: data['clientName'] ?? 'Cliente',
      workerName: data['workerName'] ?? 'Trabajador',
      unreadClient: data['unreadClient'] ?? 0,
      unreadWorker: data['unreadWorker'] ?? 0,
      lastMessage: data['lastMessage'] ?? '',
      lastAt: data['lastAt'] != null
          ? (data['lastAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'clientId': clientId,
      'workerId': workerId,
      'clientName': clientName,
      'workerName': workerName,
      'unreadClient': unreadClient,
      'unreadWorker': unreadWorker,
      'lastMessage': lastMessage,
      'lastAt': lastAt != null ? Timestamp.fromDate(lastAt!) : FieldValue.serverTimestamp(),
    };
  }
}
