import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final double offeredPrice;
  final String workerId;
  final String userToken;
  final String serviceId;
  final bool hasOffer;
  final double extraCosts;
  final double totalPrice;
  final DateTime? createdAt;  // No es nullable

  Offer({
    required this.offeredPrice,
    required this.workerId,
    required this.userToken,
    required this.serviceId,
    required this.hasOffer,
    required this.extraCosts,
    required this.totalPrice,
    DateTime? createdAt,  // Usamos DateTime? para que sea opcional
  }) : createdAt = createdAt ?? DateTime.now();  // Asignar el valor predeterminado

  // Método para convertir los datos de Firestore a un objeto Offer
  factory Offer.fromFirestore(Map<String, dynamic> data) {
    return Offer(
      serviceId: data['serviceId'] ?? '',
      workerId: data['workerId'] ?? '',
      hasOffer: data['hasOffer'] ?? false,
      offeredPrice: (data['offeredPrice'] ?? 0.0).toDouble(),
      extraCosts: (data['extraCosts'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      userToken: data['userToken'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
