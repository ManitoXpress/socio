import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/statusUtils.dart';

import 'package:timeline_tile/timeline_tile.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;
  final String workerId;

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId, required List<String> images,
  });

  @override
  _ServiceFormWithTimelineState createState() =>
      _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> {
  late TextEditingController _cancelReasonController;
  late TextEditingController _priceController;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _serviceRequestStream;
  double? _fetchedOfferedPrice;

  // Mapa de IDs de estado a nombres de estado
  final Map<String, String> statusNames = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
  };

  @override
  void initState() {
    super.initState();
    _cancelReasonController = TextEditingController();
    _priceController = TextEditingController();

    // Cargar el stream en tiempo real desde Firestore
    _serviceRequestStream = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceRequest.id)
        .snapshots();

    // Obtener el precio ofertado inicial
    _fetchOfferedPrice();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchOfferedPrice() async {
    try {
      final offeredPrice = await fetchOfferedPrice(widget.serviceRequest.id);
      setState(() {
        _fetchedOfferedPrice = offeredPrice;
        _priceController.text =
            offeredPrice != null ? offeredPrice.toString() : '';
      });
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
  }

  Future<double?> fetchOfferedPrice(String serviceId) async {
    try {
      // Consultar Firestore en la colección 'offers'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Obtener el precio ofertado
        final offerData = querySnapshot.docs.first.data();
        final offeredPrice = offerData['offeredPrice'];

        // Verificar si el precio ofertado es válido
        return offeredPrice != null ? double.tryParse(offeredPrice.toString()) : null;
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancelar Trabajo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Coloque su motivo de cancelación de trabajo:'),
              SizedBox(height: 10),
              TextField(
                controller: _cancelReasonController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escriba su motivo aquí',
                ),
              ),
              SizedBox(height: 10),
              Text('Ejemplos de cancelación de servicio:'),
              _buildCancelReasonButton('No puedo continuar con el trabajo'),
              _buildCancelReasonButton('Emergencia inesperada'),
              _buildCancelReasonButton('Otro motivo'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCancelReasonButton(String reason) {
    return ElevatedButton(
      onPressed: () {
        _cancelJobWithReason(reason);
      },
      child: Text(reason),
    );
  }

  void _cancelJobWithReason(String reason) async {
    try {
      final Status cancelledStatus = Status(id: 'cancelled', name: 'Cancelado');
      // Actualiza el estado en Firestore
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({
        'status': cancelledStatus.id,
        'cancelReason': reason,
      });

      widget.onComplete(cancelledStatus.id);
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al cancelar el trabajo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cancelar el trabajo'),
      ));
    }
  }

  void _showProposalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enviar Propuesta'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio Ofertado:'),
                SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ingrese el precio ofertado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _sendProposal,
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _sendProposal() async {
    double offeredPrice = double.tryParse(_priceController.text) ?? 0.0;
    final Status offerStatus = Status(id: 'offer', name: 'Ofertado');
    try {
      // Cambia el estado a "offer" y actualiza el precio ofertado en Firestore
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({
        'status': offerStatus.id,
        'offeredPrice': offeredPrice,
      });

      // Envía la propuesta al backend
      await ApiService().sendProposalToFirestore(
        widget.serviceRequest,
        widget.userData.getToken!,
        offeredPrice.toString(),
        widget.workerId,
      );

      setState(() {
        // Actualiza la UI con el nuevo precio
        _priceController.text = offeredPrice.toString();
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Propuesta enviada con éxito'),
      ));
    } catch (error) {
      _showErrorSnackBar('Error al enviar la propuesta: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _serviceRequestStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar los datos del servicio'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Obtener los datos del servicio desde Firestore
        final serviceData = snapshot.data?.data();

        if (serviceData == null) {
          return Center(child: Text('No se encontraron datos del servicio'));
        }

          // Obtener el status actual desde los datos del servicio
        final String currentStatusId = serviceData['status'] ?? '';

        // Actualiza los valores de estado y precio ofertado en tiempo real
        final String currentStatusName = statusNames[currentStatusId] ?? 'Disponible';
        final double? offeredPrice = _fetchedOfferedPrice;

        return AlertDialog(
          title: Text('Detalles del Servicio'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha y Hora: ${widget.serviceRequest.serviceDateTime}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Descripción: ${widget.serviceRequest.description}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Container(
                  height: 280,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seguimiento del Servicio',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('Estado: $currentStatusName'),
                        SizedBox(height: 10),
                        Text(
                          'Precio Ofertado: ${offeredPrice != null ? '\$${offeredPrice.toString()}' : 'No se ha ofertado un precio'}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showCancelDialog(context),
                          child: Text('Cancelar Trabajo'),
                        ),
                        ElevatedButton(
                          onPressed: () => _showProposalDialog(context),
                          child: Text('Enviar Propuesta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
