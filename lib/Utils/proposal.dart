import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
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

  // Método estático para verificar propuestas existentes
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

  Future<void> sendProposal({
    required double offeredPrice,
    required double extraCosts,
    required Function(String) onStatusChanged,
    required TextEditingController priceController,
    required Function(double) setFetchedOfferedPrice,
  }) async {
    // Mostrar un indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Verificar si el worker ya envió una propuesta
      bool alreadyExists = await ApiService().checkProposalExists(
        serviceRequest.id,
        workerId,
      );

      // Cerrar el indicador de carga de la verificación
      Navigator.of(context).pop();

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya has enviado una propuesta para este servicio'),
          ),
        );
        return;
      }

      // Llamar al servicio API para enviar la propuesta, usando el token pasado
      await ApiService().sendProposalToServer(
        serviceRequest,
        token,
        offeredPrice.toString(),
        extraCosts,
        workerId,
      );

      // Actualizar el estado local después de enviar la propuesta
      setFetchedOfferedPrice(offeredPrice);
      priceController.text = offeredPrice.toString();

      // Cerrar indicadores y diálogos
      Navigator.of(context).pop(); // Cerrar loader
      Navigator.of(context).pop(); // Cerrar diálogo de propuesta
    } catch (e) {
      debugPrint('Error al enviar la propuesta: $e');
      Navigator.of(context).pop(); // Cerrar loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar la propuesta: $e'),
        ),
      );
    }
  }
}