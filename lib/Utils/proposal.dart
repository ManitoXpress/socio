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

  ProposalService({
    required this.context,
    required this.serviceRequest,
    required this.workerId,
    required this.userData,
  });

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
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Actualizar los datos del servicio en Firestore
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceRequest.id)
          .update({
        'offeredPrice': offeredPrice,
      });



      // Llamar al servicio API para enviar la propuesta
      await ApiService().sendProposalToFirestore(
        serviceRequest,
        userData.getToken!,
        offeredPrice.toString(),
        extraCosts,
        workerId,
      );

      // Actualizar el estado local después de enviar la propuesta
      setFetchedOfferedPrice(offeredPrice);
      priceController.text = offeredPrice.toString();

      // Cerrar el indicador de carga y el diálogo de propuesta
      Navigator.of(context).pop(); // Cerrar el indicador de carga
      Navigator.of(context).pop(); // Cerrar el diálogo de propuesta
    } catch (e) {
      print('Error al enviar la propuesta: $e');
      Navigator.of(context).pop(); // Cerrar el indicador de carga

      // Mostrar un mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la propuesta: $e')),
      );
    }
  }

}