// lib/models/offer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/Utils/serviceFetcher.dart';


class OfferModel {
  final String id;
  final String serviceId;
  final String workerId;
  final double offeredPrice;
  final String status;
  final String clientNIT;
  final double? commission;
  final double? extraCosts;
  final double? totalPrice;
  final String? paymentStatus;
  final String? completionImageUrl;
  final List<Expertise> expertises;
  final String subcategoryName;

  OfferModel({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.offeredPrice,
    required this.status,
    required this.clientNIT,
    this.commission,
    this.extraCosts,
    this.totalPrice,
    this.paymentStatus,
    this.completionImageUrl,
    required this.expertises,
    required this.subcategoryName,
  });

  /// Construye un OfferModel directamente desde un DocumentSnapshot de Firestore
  factory OfferModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Si tu utilería `serviceFetcher.dart` ofrece un método específico:
    // return ServiceFetcher.parseOfferDocument(doc);
    //
    // Si no, lo parseamos manualmente:
    final rawExpertises = (data['expertises'] as List<dynamic>? ?? [])
        .map((e) => Expertise.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return OfferModel(
      id: doc.id,
      serviceId: data['serviceId'] as String? ?? '',
      workerId: data['workerId'] as String? ?? '',
      offeredPrice:
          (data['offeredPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? '',
      clientNIT: data['clientNIT'] as String? ?? '',
      commission: (data['commission'] as num?)?.toDouble(),
      extraCosts: (data['extraCosts'] as num?)?.toDouble(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      paymentStatus: data['paymentStatus'] as String?,
      completionImageUrl: data['completionImageUrl'] as String?,
      expertises: rawExpertises,
      subcategoryName: data['subcategoryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'workerId': workerId,
      'offeredPrice': offeredPrice,
      'status': status,
      'clientNIT': clientNIT,
      'commission': commission,
      'extraCosts': extraCosts,
      'totalPrice': totalPrice,
      'paymentStatus': paymentStatus,
      'completionImageUrl': completionImageUrl,
      'expertises': expertises.map((e) => e.toMap()).toList(),
      'subcategoryName': subcategoryName,
    };
  }
}
