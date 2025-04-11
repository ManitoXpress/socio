import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io'; // Para manejar archivos locales
import 'package:image_picker/image_picker.dart';

import 'package:socio/Metods/imagePreview.dart';
import 'package:socio/Metods/jobComplete.dart';
import 'package:socio/Screens/Chatscreen.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/ServiceResponse/requestWorker.dart';
import 'package:socio/Utils/fullMap.dart';
import 'package:socio/Utils/proposal.dart';
import 'package:socio/Utils/styles.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ServiceFormWithTimeline extends StatefulWidget {
  final ServiceRequest serviceRequest;

  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;
  final String workerId;
  final WorkerDetails? workerDetails;
  final List<Offer> offers;
  final ApiService apiService;
  final ApiService2 apiService2;

  final List<String> images; // Parámetro images

  const ServiceFormWithTimeline({
    required this.serviceRequest,

    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
    required this.images, // Asegurarse de que el parámetro esté presente
    required this.workerDetails,
    required this.offers,
    required this.apiService,
    required this.apiService2,
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
  File? _image; // Variable para almacenar la imagen seleccionada
  final ImagePicker _picker = ImagePicker();
  String? _selectedImageUrl;
  double? _workerOfferedPrice;
  bool _isSendingProposal = false;
  bool _isCompletingJob = false;

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
    _fetchWorkerOffer();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkerOffer() async {
    try {
      final offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: widget.serviceRequest.id)
          .where('workerId', isEqualTo: widget.workerId)
          .get();

      if (offerSnapshot.docs.isNotEmpty) {
        setState(() {
          _workerOfferedPrice =
              offerSnapshot.docs.first.data()['offeredPrice']?.toDouble();
        });
      } else {
        setState(() {
          _workerOfferedPrice = null;
        });
      }
    } catch (e) {
      print('Error al obtener la oferta del trabajador: $e');
      setState(() {
        _workerOfferedPrice = null;
      });
    }
  }

  void _initializeMap() {
    // Si los datos de ubicación están presentes en la solicitud de servicio, los usa; si no, se usa una ubicación predeterminada.
    double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
    double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

    // Inicializa la posición usando los valores de latitud y longitud obtenidos.
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
      print('Error al bloquear la participación del usuario: $e');
    }
  }

  void _showNoParticipationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'No Participar en el Trabajo',
            style: MyTextStyles.linkTextStyle,
          ),
          content: Text(
            '¿Estás seguro de que no quieres participar en este trabajo?',
            style: MyTextStyles.ButtonTextStyle,
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.dangerous, color: Color(0xFF84090D)),
              label: Text(
                "Cancelar",
                style: GoogleFonts.karla(
                  color: Color(0xFF84090D),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _blockUserParticipation,
              icon: Icon(Icons.check_circle, color: Color(0xFF84090D)),
              label: Text(
                "Confirmar No Participar",
                style: GoogleFonts.karla(
                  color: Color(0xFF84090D),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
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
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(
                'Enviar Propuesta',
                style: MyTextStyles.linkTextStyle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ingrese el precio que va a ofertar:',
                      style: MyTextStyles.ButtonTextStyle,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Precio Ofertado",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      focusColor: Color(0xFF830A09),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF830A09),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: _isSendingProposal
                      ? null
                      : () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.dangerous, color: Color(0xFF84090D)),
                  label: Text(
                    "Cancelar",
                    style: GoogleFonts.karla(
                      color: Color(0xFF84090D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(0xFF84090D)),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSendingProposal
                      ? null
                      : () async {
                    setStateDialog(() {
                      _isSendingProposal = true;
                    });

                    await _sendProposal();

                    setStateDialog(() {
                      _isSendingProposal = false;
                    });

                    Navigator.of(context).pop();
                  },
                  icon: _isSendingProposal
                      ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF84090D),
                      ),
                    ),
                  )
                      : Icon(Icons.check_circle, color: Color(0xFF84090D)),
                  label: Text(
                    _isSendingProposal ? "Enviando..." : "Enviar Propuesta",
                    style: GoogleFonts.karla(
                      color: Color(0xFF84090D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(0xFF84090D)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _sendProposal() async {
    double offeredPrice = double.tryParse(_priceController.text) ?? 0.0;
    double extraCosts = 3.0;
    String? workerId = await getCurrentWorkerId();

    if (workerId == null || workerId.isEmpty) {
      print('No se pudo obtener el workerId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener el ID del trabajador')),
      );
      return;
    }

    ProposalService proposalService = ProposalService(
      context: context,
      serviceRequest: widget.serviceRequest,
      workerId: workerId,
      userData: widget.userData,
    );

    await proposalService.sendProposal(
      offeredPrice: offeredPrice,
      extraCosts: extraCosts,
      onStatusChanged: widget.onStatusChanged,
      priceController: _priceController,
      setFetchedOfferedPrice: (double price) {
        setState(() {
          _fetchedOfferedPrice = price;
        });
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Propuesta enviada exitosamente')),
    );
  }


  void _showPendingConfirmation2Dialog(BuildContext context) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('offers')
      .where('serviceId', isEqualTo: widget.serviceRequest.id)
      .limit(1)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    var offerData = querySnapshot.docs.first.data();
    var offeredPrice = offerData['offeredPrice'];
    var clientNIT = offerData['clientNIT'] ?? 'NIT no disponible'; // Obtener el NIT de la oferta

    // Verifica el tipo de dato y realiza la conversión si es necesario.
    if (offeredPrice is String) {
      offeredPrice = double.tryParse(offeredPrice.toString()) ?? 0.0;
    } else if (offeredPrice is! double) {
      offeredPrice = 0.0;
    }

    // Define la comisión y los gastos informáticos.
    double commission = offeredPrice * 0.10; // Comisión del 10%.
    double extraCosts = 3.0;
    double totalPrice = offeredPrice + extraCosts; // Precio total.

    String paymentStatus = 'pagado';

    // Muestra el diálogo con el NIT obtenido
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación de la Oferta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Oferta del servicio:'),
              Text('Precio ofertado: Bs ${offeredPrice}'),
              SizedBox(height: 16.0),
              Text('NIT del cliente: $clientNIT'), // Mostrar el NIT
              SizedBox(height: 16.0),
              Text('Se agregarán Bs $extraCosts en gastos informáticos.'),
              SizedBox(height: 16.0),
              Text('Nuevo precio total: Bs ${totalPrice.toStringAsFixed(2)}'),
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
              onPressed: () {
                // Llamar a la función para manejar la aceptación
                _handleAcceptButton(
                  querySnapshot,
                  offeredPrice,
                  commission,
                  extraCosts,
                  totalPrice,
                  paymentStatus,
                  clientNIT, // Pasar el NIT a la función
                );
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  } else {
    print('No se encontró una oferta para el serviceId proporcionado');
  }
}

  void _handleAcceptButton(
      QuerySnapshot querySnapshot,
      double offeredPrice,
      double commission,
      double extraCost,
      double totalPrice,
      String paymentStatus,
      String clientNIT, // Recibir el NIT como parámetro
      ) async {
    try {
      final offerRef = FirebaseFirestore.instance
          .collection('offers')
          .doc(querySnapshot.docs.first.id);

      final serviceRef = FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final offerDoc = await transaction.get(offerRef);
        final serviceDoc = await transaction.get(serviceRef);

        if (offerDoc.exists && serviceDoc.exists) {
          // Actualiza el precio ofertado y el estado en 'offers'
          transaction.update(offerRef, {
            'offeredPrice': offeredPrice,
            'commission': commission,
            'extraCosts': extraCost,
            'totalPrice': totalPrice,
            'status': 'completed',
            'clientNIT': clientNIT, // Guardar el NIT
            'paymentStatus': 'debe', // Nuevo campo
          });

          // Actualiza el precio ofertado, costos extras, comisión, estado y estado de pago en 'services'
          transaction.update(serviceRef, {
            'commission': commission,
            'extraCosts': extraCost,
            'totalPrice': totalPrice,
            'status': 'completed',
            'clientNIT': clientNIT, // Guardar el NIT
            'paymentStatus': 'debe', // Nuevo campo
          });
        } else {
          throw Exception(
              'No se encontró el documento de la oferta o del servicio');
        }
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oferta y servicio actualizados con estado de pago: $paymentStatus',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  void _showCompleteJobDialog(BuildContext context) {
    final offer = widget.offers.isNotEmpty ? widget.offers.first : null; // Usa la primera oferta si está disponible, de lo contrario, null

    if (widget.serviceRequest.status == 'pending_confirmation2') {
      _showPendingConfirmation2Dialog(context);
    } else {
      CompleteJobDialog(
        context: context,
        serviceRequest: widget.serviceRequest,
        offer: offer, // Pasa la oferta aquí
        onStatusChanged: widget.onStatusChanged,
        apiService: widget.apiService,
        apiService2: widget.apiService2,
      ).show();
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
        final List<String> images =
            List<String>.from(serviceData['images'] ?? []);
        double latitude = widget.serviceRequest.location['lat'] ?? 0.0;
        double longitude = widget.serviceRequest.location['lng'] ?? 0.0;

        _initialPosition = LatLng(latitude, longitude);

        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Detalles del Servicio',
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
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
                    // Estado del servicio
                    Text(
                      'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    SizedBox(height: 16.0),

                    // Descripción del servicio
                    Text.rich(
                      TextSpan(
                        text: 'Descripción: ',
                        style: MyTextStyles.inputTextStyle6,
                        children: [
                          TextSpan(
                            text: serviceData['description'] ?? '',
                            style: MyTextStyles.inputTextStyle1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0),

                    // Ubicación del servicio
                    Text(
                      'Ubicación:',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    GestureDetector(
                      onTap: () => _openFullMap(context),
                      child: Container(
                        height: 200,
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
                            onTap: (_) => _openFullMap(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),

                    // Imágenes del servicio
                    Text(
                      'Imágenes:',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    if (images.isNotEmpty)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200.0,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          aspectRatio: 16 / 9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enableInfiniteScroll: true,
                          autoPlayAnimationDuration:
                              Duration(milliseconds: 800),
                          viewportFraction: 0.8,
                        ),
                        items: images.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ImageViewer(imageUrl: url),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: url,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),

                    SizedBox(height: 16.0),

                    // Precio ofertado
                    Text(
                      'Precio Ofertado: ${_workerOfferedPrice != null ? '\$${_workerOfferedPrice!.toStringAsFixed(2)}' : 'No ofertado'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    SizedBox(height: 16.0),

                    // Botones dependiendo del estado
                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      alignment: WrapAlignment.center,
                      children: [_buildActionButtons()],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Método para construir los botones de acción según el estado
  Widget _buildActionButtons() {
    switch (_currentStatus) {
      case 'available':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showProposalDialog(context),
              icon: Icon(Icons.add_business, color: Color(0xFFB00020)),
              label: Text(
                "Enviar Propuesta",
                style: GoogleFonts.karla(
                  color: Color(0xFFB00020),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(color: Color(0xFFB00020)),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showNoParticipationDialog(context),
              icon: Icon(Icons.dangerous, color: Color(0xFFB00020)),
              label: Text(
                "No Participar",
                style: GoogleFonts.karla(
                  color: Color(0xFFB00020),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(color: Color(0xFFB00020)),
                ),
              ),
            ),
          ],
        );
      case 'offer':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showNoParticipationDialog(context),
              icon: Icon(Icons.dangerous, color: Colors.white),
              label: Text(
                "No Participar",
                style: GoogleFonts.karla(
                  color: Color(0xFFB00020),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB00020),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
          ],
        );
      case 'in_progress':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showCompleteJobDialog(context),
                  icon: Icon(Icons.architecture_sharp, color: Color(0xFFB00020)),
                  label: Text(
                    "Completar trabajo",
                    style: GoogleFonts.karla(
                      color: Color(0xFFB00020),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(0xFFB00020)),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNoParticipationDialog(context),
                  icon: Icon(Icons.dangerous, color: Color(0xFFB00020)),
                  label: Text(
                    "No Participar",
                    style: GoogleFonts.karla(
                      color: Color(0xFFB00020),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(0xFFB00020)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Espacio entre los botones
            ElevatedButton.icon(
              onPressed: () =>
                  _openChat(widget.workerId, widget.serviceRequest.userId),
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                "Chat",
                style: GoogleFonts.karla(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB00020),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        );

      case 'pending_confirmation2':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_currentStatus == 'pending_confirmation2')
                  ElevatedButton.icon(
                    onPressed: () => _showPendingConfirmation2Dialog(context),
                    icon: Icon(Icons.check_circle, color: Color(0xFFB00020)),
                    label: Text(
                      "Pago Aceptado",
                      style: GoogleFonts.karla(
                        color: Color(0xFFB00020),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Color(0xFFB00020)),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showNoParticipationDialog(context),
                  icon: Icon(Icons.dangerous, color: Color(0xFFB00020)),
                  label: Text(
                    "No Participar",
                    style: GoogleFonts.karla(
                      color: Color(0xFFB00020),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(color: Color(0xFFB00020)),
                    ),
                  ),
                ),

              ],
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _openChat(widget.workerId, widget.serviceRequest.userId),
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                "Chat",
                style: GoogleFonts.karla(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        );
      case 'pending_confirmation':
        return Text('Esperando la confirmación del cliente...');
      case 'completed':
        return Text('Este trabajo ha sido completado.');
      case 'cancelled':
        return Text('Este trabajo ha sido cancelado.');
      case 'blocked':
        return Text('No participarás en este trabajo.');
      default:
        return Container(); // En caso de que no se cumpla ninguno de los casos anteriores
    }
  }

  void _openChat(String workerId, String userId) async {
    final chatId = _generateChatId(workerId, userId);

    // Referencia al documento del chat
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Verifica si el chat ya existe
    final chatSnapshot = await chatDoc.get();

    if (!chatSnapshot.exists) {
      // Si el chat no existe, lo crea con información inicial
      await chatDoc.set({
        'chatId': chatId,
        'participants': [userId, workerId],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Navegar a la pantalla de chat (debes implementar esta pantalla)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          userId: userId,
          workerId: workerId,
        ),
      ),
    );
  }

  String _generateChatId(String workerId, String userId) {
    // Generar un ID único basado en los IDs de los participantes
    return workerId.hashCode <= userId.hashCode
        ? '$workerId\_$userId'
        : '$userId\_$workerId';
  }
}