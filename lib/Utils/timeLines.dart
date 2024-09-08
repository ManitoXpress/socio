import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/statusUtils.dart';

import 'package:timeline_tile/timeline_tile.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;
  final String workerId;

  final List<String> images; // Parámetro images

  const ServiceFormWithTimeline({
    required this.serviceRequest,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,

    required this.workerId,
    required this.images, // Asegurarse de que el parámetro esté presente
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
  late String _currentStatus;

  final Map<String, String> statusNames = {
    "available": "Disponible",
    "offer": "Ofertado",
    "in_progress": "En curso",
    "completed": "Completado",
    "cancelled": "Cancelado",
    "blocked": "Bloqueado",
  };

  @override
  void initState() {
    super.initState();
    _cancelReasonController = TextEditingController();
    _priceController = TextEditingController();
    _serviceRequestStream = FirebaseFirestore.instance
        .collection('services')
        .doc(widget.serviceRequest.id)
        .snapshots();
    _fetchOfferedPrice();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _blockUserParticipation() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({
        'blockedUsers': FieldValue.arrayUnion([widget.workerId])
      });

      widget.onStatusChanged('blocked');
      widget.onComplete('blocked');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al bloquear la participación del usuario: $e');
    }
  }

  void _showNoParticipationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Participar en el Trabajo'),
          content: Text('¿Estás seguro de que no quieres participar en este trabajo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _blockUserParticipation,
              child: Text('Confirmar No Participar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchOfferedPrice() async {
    try {
      final offeredPrice = await fetchOfferedPrice(widget.serviceRequest.id);
      setState(() {
        _fetchedOfferedPrice = offeredPrice;
        _priceController.text = offeredPrice != null ? offeredPrice.toString() : '';
      });
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
  }

  Future<double?> fetchOfferedPrice(String serviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        final offeredPrice = offerData['offeredPrice'];
        return offeredPrice != null ? double.tryParse(offeredPrice.toString()) : null;
      }
    } catch (e) {
      print('Error al obtener el precio ofertado: $e');
    }
    return null;
  }

  void _showProposalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enviar Propuesta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ingrese su precio ofertado:'),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Precio ofertado',
                ),
              ),
            ],
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
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'offer', 'offeredPrice': offeredPrice});

      await ApiService().sendProposalToFirestore(
        widget.serviceRequest,
        widget.userData.getToken!,
        offeredPrice.toString(),
        widget.workerId,
      );

      setState(() {
        _fetchedOfferedPrice = offeredPrice;
        _priceController.text = offeredPrice.toString();
      });

      widget.onStatusChanged('offer');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al enviar la propuesta: $e');
    }
  }

  void _showCompleteJobDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Completar Trabajo'),
          content: Text('¿Estás seguro de que deseas completar este trabajo? El cliente deberá confirmar para finalizar.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _completeJob,
              child: Text('Completar Trabajo'),
            ),
          ],
        );
      },
    );
  }

  void _completeJob() async {
    try {
      // Actualizar estado a "pending_confirmation" mientras se espera la confirmación del cliente
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .update({'status': 'pending_confirmation'});

      widget.onStatusChanged('pending_confirmation');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al completar el trabajo: $e');
    }
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

        final serviceData = snapshot.data?.data();
        if (serviceData == null) {
          return Center(child: Text('No se encontraron datos del servicio'));
        }

        _currentStatus = serviceData['status'] ?? 'available';
        List<String> imageFiles =
            List<String>.from(serviceData['images'] ?? []);

        return Scaffold(
          appBar: AppBar(
            title: Text('Detalles del Servicio'),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción: ${serviceData['description'] ?? ''}'),
                SizedBox(height: 16.0),
                Text('Ubicación: ${serviceData['location'] ?? ''}'),
                SizedBox(height: 16.0),
                Text(
                    'Precio Ofertado: ${_fetchedOfferedPrice ?? 'No ofertado'}'),
                SizedBox(height: 16.0),
                Text('Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}'),
                SizedBox(height: 16.0),
                Text('Imágenes:'),
                Expanded(
                  child: ListView.builder(
                    itemCount: imageFiles.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.network(
                          imageFiles[index],
                          height: 80, // Reducción del tamaño de la imagen
                          width: 80, // Reducción del tamaño de la imagen
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16.0),
                // Mostrar botones dependiendo del estado
                if (_currentStatus == 'available') ...[
                  ElevatedButton(
                    onPressed: () {
                      _showProposalDialog(context);
                    },
                    child: Text('Enviar Propuesta'),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _showNoParticipationDialog(context);
                    },
                    child: Text('No Participar en el Trabajo'),
                  ),
                ] else if (_currentStatus == 'offer') ...[
                  ElevatedButton(
                    onPressed: () {
                      _showNoParticipationDialog(context);
                    },
                    child: Text('No Participar en el Trabajo'),
                  ),
                ] else if (_currentStatus == 'in_progress') ...[
                  ElevatedButton(
                    onPressed: () {
                      _showNoParticipationDialog(context);
                    },
                    child: Text('No Participar en el Trabajo'),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _showCompleteJobDialog(context);
                    },
                    child: Text('Completar Trabajo'),
                  ),
                ] else if (_currentStatus == 'pending_confirmation') ...[
                  Text('Esperando la confirmación del cliente...'),
                ] else if (_currentStatus == 'completed') ...[
                  Text('Este trabajo ha sido completado.'),
                ] else if (_currentStatus == 'cancelled') ...[
                  Text('Este trabajo ha sido cancelado.'),
                ] else if (_currentStatus == 'blocked') ...[
                  Text('No participarás en este trabajo.'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<String>> _getImageUrls(List<String> imageNames) async {
    List<String> imageUrls = [];
    final apiService = ApiService2();

    for (String imageName in imageNames) {
      try {
        // Llamada a getImageUrls usando ApiService2
        String imageUrl = await apiService.getImageUrls(
            widget.serviceRequest.userId, imageName);
        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      } catch (e) {
        print('Error al obtener la URL de la imagen $imageName: $e');
      }
    }

    return imageUrls;
  }

}
