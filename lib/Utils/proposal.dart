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
    required double extraCosts, // Añadido parámetro para costos extra
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
          .update({
        'status': 'offer',
        'visibility': ['available', 'offer'], // Agregar visibilidad
        'offeredPrice': offeredPrice,
        'workerId': workerId, // Añade el workerId al documento
      });

      // Enviar la propuesta usando el ApiService
      await ApiService().sendProposalToFirestore(
        serviceRequest,
        userData.getToken!,
        offeredPrice.toString(),
        extraCosts, // Pasa los costos extra
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
