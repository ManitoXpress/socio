import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../ServiceResponse/post.dart';
import '../ServiceResponse/request.dart';
import '../ServiceResponse/requestUserData.dart';




class ProposalService {
  final BuildContext context;
  final ServiceRequest serviceRequest;
  final String workerId;
  final UserData userData;
  final String token;

  ProposalService({
    required this.context,
    required this.serviceRequest,
    required this.workerId,
    required this.userData,
    required this.token,
  });

  static Future<bool> checkExistingProposal({
    required String serviceRequestId,
    required String workerId,
  }) async {
    try {
      return await ApiService().checkProposalExists(
        serviceRequestId,
        workerId,
      );
    } catch (e) {
      debugPrint('Error verificando propuesta: $e');
      return false;
    }
  }

  /// Devuelve true si envía la propuesta, false si ya existía o falló.
  Future<bool> sendProposal({
    required double offeredPrice,
    required double extraCosts,
  }) async {
    // 1) loader de verificación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2) verifico existencia
      final alreadyExists = await ApiService().checkProposalExists(
        serviceRequest.id,
        workerId,
      );
      Navigator.of(context).pop(); // cierro verificación

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has enviado una propuesta para este servicio')),
        );
        return false;
      }

      // 3) envío real
      await ApiService().sendProposalToServer(
        serviceRequest,
        token,
        offeredPrice.toString(),
        extraCosts,
        workerId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta enviada exitosamente')),
      );
      return true;
    } catch (e) {
      Navigator.of(context).pop(); // cierro loader
      debugPrint('Error al enviar la propuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la propuesta: $e')),
      );
      return false;
    }
  }
}
