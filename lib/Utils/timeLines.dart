import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/fullMap.dart';
import 'package:socio/Utils/statusUtils.dart';
import 'package:socio/Utils/styles.dart';

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
  late LatLng _initialPosition;

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
  void _initializeMap() {
  // Si los datos de ubicación están presentes en la solicitud de servicio, los usa; si no, se usa una ubicación predeterminada.
  double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
  double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

  // Inicializa la posición usando los valores de latitud y longitud obtenidos.
  _initialPosition = LatLng(latitude, longitude);
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
          content: Text(
              '¿Estás seguro de que no quieres participar en este trabajo?'),
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
  void _openFullMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullMapScreen(initialPosition: _initialPosition),
      ),
    );
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        final offeredPrice = offerData['offeredPrice'];
        return offeredPrice != null
            ? double.tryParse(offeredPrice.toString())
            : null;
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
          content: Text(
              '¿Estás seguro de que deseas completar este trabajo? El cliente deberá confirmar para finalizar.'),
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
        List<String> imageFiles = List<String>.from(serviceData['images'] ?? []);
        double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
        double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

        _initialPosition = LatLng(latitude, longitude);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Detalles del Servicio',
              style: MyTextStyles.ButtonTextStyle,
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF84090D), width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  SizedBox(height: 16.0),
                  Text.rich(
                    TextSpan(
                      text: 'Descripción: ', // Este texto tendrá su propio estilo
                      style: MyTextStyles.formServiceTextStyle,
                      children: [
                        TextSpan(
                          text: serviceData['description'] ?? '', // Este texto tendrá otro estilo
                          style: MyTextStyles.inputTextStyle, // Aplica un estilo diferente aquí
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.0),
                  Text(
                    'Ubicación:',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  GestureDetector(
                    onTap: () => _openFullMap(context),  // Abre el mapa completo
                    child: Container(
                      height: 200,  // Tamaño pequeño del mapa
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition,
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('serviceLocation'),
                              position: _initialPosition,
                            ),
                          },
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          onTap: (_) => _openFullMap(context),  // Abre el mapa completo
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                  
                  Text(
                    'Imágenes:',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: imageFiles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Image.network(
                            imageFiles[index],
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Precio Ofertado: ${_fetchedOfferedPrice ?? 'No ofertado'}',
                    style: MyTextStyles.formServiceTextStyle,
                  ),
                  SizedBox(height: 16.0),
                  // Mostrar botones dependiendo del estado
                  if (_currentStatus == 'available') ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _showProposalDialog(context);
                      },
                      icon: Icon(Icons.add_business, color: Colors.white),
                      label: Text(
                    "Enviar Propuesta",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB00020),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showNoParticipationDialog(context);
                      },
                      icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "No Participar",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB00020),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                    ),
                  ] else if (_currentStatus == 'offer') ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _showNoParticipationDialog(context);
                      },
                     icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "No Participar",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB00020),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                    ),
                  ] else if (_currentStatus == 'in_progress') ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _showNoParticipationDialog(context);
                      },
                      icon: Icon(Icons.dangerous, color: Colors.white),
                      label: Text(
                    "No Participar",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB00020),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showCompleteJobDialog(context);
                      },
                      icon: Icon(Icons.architecture_sharp, color: Colors.white),
                      label: Text(
                    "Completar trabajo",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB00020),
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  ),
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
          ),
        );
      },
    );
  }
}
