import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
class ProposalService {
  final BuildContext context;
  final ServiceRequest serviceRequest;
  final String workerId;
  final UserData userData;

  ProposalService({
    required this.context,
    required this.serviceRequest,
    required this.workerId,
    required this.userData,
  });

  Future<void> sendProposal({
    required double offeredPrice,
    required Function(String) onStatusChanged,
    required TextEditingController priceController,
    required Function setFetchedOfferedPrice,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Actualizar los datos en Firestore
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceRequest.id)
          .update({'status': 'offer', 'offeredPrice': offeredPrice});

      // Enviar la propuesta usando el ApiService
      await ApiService().sendProposalToFirestore(
        serviceRequest, // Pasar el objeto ServiceRequest completo
        userData.getToken!,
        offeredPrice.toString(),
        workerId,
      );

      // Actualizar el estado local después de enviar la propuesta
      setFetchedOfferedPrice(offeredPrice);
      priceController.text = offeredPrice.toString();

      onStatusChanged('offer');

      Navigator.of(context).pop(); // Cerrar el indicador de carga
      Navigator.of(context).pop(); // Cerrar el diálogo de propuesta
    } catch (e) {
      print('Error al enviar la propuesta: $e');
      Navigator.of(context).pop(); // Cerrar el indicador de carga
    }
  }
}

