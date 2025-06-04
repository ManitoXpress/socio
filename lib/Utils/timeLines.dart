import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io'; // Para manejar archivos locales
import 'package:image_picker/image_picker.dart';
import 'package:socio/Controller/jobComplete.dart';
import 'package:socio/Screens/Chatscreen.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/ServiceResponse/requestWorker.dart';
import 'package:socio/Utils/authUtils.dart';
import 'package:socio/Utils/fullMap.dart';
import 'package:socio/Utils/proposal.dart';
import 'package:socio/Utils/styles.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socio/Controller/imagePreview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
class ServiceFormWithTimeline extends StatefulWidget {
  static final Set<String> _proposalsSentForServiceIds = {}; // ✅ corregido
  final ServiceRequest serviceRequest;
  final Offer offer;
  String displayName;
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
  final String userId;

  ServiceFormWithTimeline({
    required this.offer,
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
    required this.userId,
    required this.displayName,
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
  String? phoneNumber;
  String? displayName;
  String? _selectedImageUrl;
  double? _workerOfferedPrice;
  bool _isSendingProposal = false;
  bool _isCompletingJob = false;
  final Set<String> _proposalsSentForServiceIds = {};
  bool _isSubmitting = false;
  bool _proposalSent = false;
  String? _uploadedImageUrl;

  bool _isProcessing = false;

  // Define the comentarios variable as a list of maps
  List<Map<String, String>> comentarios = [];

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
    _checkExistingProposal();
    _fetchUserInfo();
    _loadServiceComments();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _priceController.dispose();
    super.dispose();
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

  /// Pide los comentarios actuales del servicio y los pone en comentarios
  Future<void> _loadServiceComments() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceRequest.id)
          .get();

      final data = doc.data();
      if (data == null || data['comments'] == null) {
        comentarios = [];
      } else {
        final raw = data['comments'] as List<dynamic>;
        comentarios = raw.map((c) => Map<String, String>.from(c)).toList();
      }

      setState(() {});
    } catch (e) {
      print('Error cargando comentarios desde Firestore: $e');
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (workerDoc.exists) {
        setState(() {
          displayName = workerDoc['displayName'];
          phoneNumber = workerDoc['phoneNumber'];
        });
      }
    } catch (e) {
      print('Error al obtener datos del trabajador: $e');
    }
  }

  Future<void> _checkExistingProposal() async {
    final workerId = await getCurrentWorkerId();
    if (workerId == null || workerId.isEmpty) return;

    bool exists = await ProposalService.checkExistingProposal(
      serviceRequestId: widget.serviceRequest.id,
      workerId: workerId,
    );

    if (mounted) {
      setState(() {
        _proposalSent = exists;
      });
    }
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

  void _mostrarComentarios(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final _comentarioController = TextEditingController();
    final api = ApiService2();
    final sr = widget.serviceRequest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // imprescindible para que ocupe todo el alto disponible
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Aquí envolvemos TODO en un Padding que responde al teclado:
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: api.fetchSingleService(
              'userId',
              sr.userId,
              'status',
              sr.devicesId,
              sr.id,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error cargando comentarios:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final serviceJson = snap.data!;
              final List<Map<String, String>> comentarios =
              (serviceJson['comments'] as List<dynamic>? ?? [])
                  .map((e) => Map<String, String>.from(e as Map))
                  .toList();

              return DraggableScrollableSheet(
                expand: false,
                builder: (context, scrollController) {
                  return StatefulBuilder(builder: (context, setModalState) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            'Comentarios (${comentarios.length})',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Divider(),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: comentarios.length,
                              itemBuilder: (ctx, i) {
                                final c = comentarios[i];
                                final isClient = c['rol'] == 'cliente';
                                final alignment = isClient
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start;
                                final color = isClient ? Colors.blue : Colors.red;
                                final textAlign = isClient
                                    ? TextAlign.end
                                    : TextAlign.start;
                                final nombre = isClient ? 'Cliente' : 'Trabajador';

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.person, size: 18),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: alignment,
                                    children: [
                                      Text(
                                        nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        c['hora'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    c['mensaje'] ?? '',
                                    textAlign: textAlign,
                                  ),
                                );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _comentarioController,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe un comentario...',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.send),
                                onPressed: () async {
                                  // dentro de onPressed:
                                  final text = _comentarioController.text.trim();
                                  if (text.isEmpty) return;

// obtengo el uid actual
                                  final currentUid = user?.uid;

// determino rol comparando con los IDs de la solicitud
                                  final rol = (currentUid == sr.userId)
                                      ? 'cliente'
                                      : (currentUid == sr.workerId)
                                      ? 'trabajador'
                                      : 'desconocido';

// nombre según rol (aquí podrías usar user.displayName o un campo que guardes)
                                  final nombre = (rol == 'cliente')
                                      ? 'Cliente'
                                      : (rol == 'trabajador')
                                      ? 'Trabajador'
                                      : 'Anónimo';

                                  final now = TimeOfDay.now();
                                  final hora = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

                                  final nuevo = {
                                    'nombre': nombre,
                                    'mensaje': text,
                                    'hora': hora,
                                    'rol': rol,
                                  };


                                  try {
                                    comentarios.add(nuevo);
                                    await api.patchServiceComments(
                                        sr.id, comentarios);
                                    setModalState(() {});
                                  } catch (e) {
                                    print('Error enviando comentario: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                        Text('No se pudo enviar el comentario'),
                                      ),
                                    );
                                  }

                                  _comentarioController.clear();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            },
          ),
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

  void _showProposalDialog(BuildContext context, String serviceId) {
    // Verificamos si ya se envió una propuesta para este servicio
    if (_proposalsSentForServiceIds.contains(serviceId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya enviaste una propuesta para este servicio')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        bool _isSendingProposal = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title:
              Text('Enviar Propuesta', style: MyTextStyles.linkTextStyle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingrese el precio que va a ofertar:',
                      style: MyTextStyles.ButtonTextStyle),
                  SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Precio Ofertado",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF830A09)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: _isSendingProposal
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.dangerous, color: Color(0xFF84090D)),
                  label: Text("Cancelar",
                      style: GoogleFonts.karla(
                          color: Color(0xFF84090D),
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Color(0xFF84090D)),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSendingProposal
                      ? null
                      : () async {
                    setStateDialog(() => _isSendingProposal = true);
                    final success = await _sendProposal(); // tu función

                    setStateDialog(() => _isSendingProposal = false);

                    if (success) {
                      _proposalsSentForServiceIds.add(
                          serviceId); // 🚫 ya no podrá volver a enviar
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error al enviar propuesta')),
                      );
                    }
                  },
                  icon: _isSendingProposal
                      ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation(Color(0xFF84090D)),
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
                      borderRadius: BorderRadius.circular(10),
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

  Future<bool> _sendProposal() async {
    // Protección extra: si ya envié, abortar
    if (_proposalSent) return false;

    final offeredPrice = double.tryParse(_priceController.text) ?? 0.0;
    const extraCosts = 3.0;
    final workerId = await getCurrentWorkerId();

    if (workerId == null || workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener el ID del trabajador')),
      );
      return false;
    }

    // 1) Mostrar loader de verificación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2) Verificar en servidor si ya existe
      final alreadyExists = await ApiService().checkProposalExists(
        widget.serviceRequest.id,
        workerId,
      );

      Navigator.of(context).pop(); // cerrar loader

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya has enviado una propuesta para este servicio'),
          ),
        );
        return false;
      }

      // 3) Enviar propuesta al servidor
      await ApiService().sendProposalToServer(
        widget.serviceRequest,
        '',
        offeredPrice.toString(),
        extraCosts,
        workerId,
      );

      // 4) Actualizar UI local
      setState(() {
        _fetchedOfferedPrice = offeredPrice;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propuesta enviada exitosamente')),
      );

      return true;
    } catch (e) {
      Navigator.of(context).pop(); // cerrar loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la propuesta: $e')),
      );
      return false;
    }
  }
  Future<void> _showUploadCompletionImageDialog() async {
    XFile? picked;
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text('Subir foto de trabajo terminado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (picked == null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.photo),
                    label: Text('Seleccionar imagen'),
                    onPressed: () async {
                      picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      setSt(() {});
                    },
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(picked!.path),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: (picked == null || isUploading) ? null : () async {
                  setSt(() => isUploading = true);

                  // Obtener token
                  final token = await AuthUtils.getToken();
                  if (token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: usuario no autenticado')),
                    );
                    return;
                  }

                  // 1) Subir al backend usando tu método
                  try {
                    await widget.apiService.uploadImageToBackend(
                      picked!.path,
                      widget.serviceRequest.id,
                      token,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error subiendo imagen: $e')),
                    );
                    setSt(() => isUploading = false);
                    return;
                  }

                  Navigator.of(ctx).pop();
                  // 2) Tras subir la imagen, continuar con completar y aceptar
                  await _completeAndAccept();
                },
                child: isUploading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _completeAndAccept() async {
  setState(() => _isProcessing = true);

  try {
    // 1) Traer oferta del backend
    final offer = await widget.apiService2.getOfferByServiceId(widget.serviceRequest.id);
    final offerId = offer['id'] as String;

    // 2) Calcular montos
    final raw = offer['offeredPrice'];
    final offeredPrice = raw is num
        ? raw.toDouble()
        : double.tryParse(raw.toString()) ?? 0.0;
    final extraCosts = 3.0;
    final commission = offeredPrice * 0.10;
    final totalPrice = offeredPrice + extraCosts;
    final clientNIT = offer['clientNIT'] as String? ?? '';
    final paymentStatus = 'debe';

    // Suponiendo que tras subir la imagen guardaste la URL aquí:
    final String? completionImageUrl = _uploadedImageUrl;

    // 3) Parchar oferta (ahora con completionImageUrl)
    final offerPayload = {
      'offeredPrice': offeredPrice,
      'commission': commission,
      'extraCosts': extraCosts,
      'totalPrice': totalPrice,
      'status': 'completed',
      'clientNIT': clientNIT,
      'paymentStatus': paymentStatus,
      'completionImageUrl': completionImageUrl,
    };
    print('🔧 patchOffer: id=$offerId payload=$offerPayload');
    await widget.apiService2.patchOffer(offerId, offerPayload);

    // 4) Parchar servicio (también con completionImageUrl)
    final servicePayload = {
      'commission': commission,
      'extraCosts': extraCosts,
      'totalPrice': totalPrice,
      'status': 'completed',
      'clientNIT': clientNIT,
      'paymentStatus': paymentStatus,
      'completionImageUrl': completionImageUrl,
    };
    print('🔧 patchService: id=${widget.serviceRequest.id} payload=$servicePayload');
    await widget.apiService2.patchService(widget.serviceRequest.id, servicePayload);

    // 5) Feedback
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trabajo completado y pago registrado.')),
    );
    widget.onStatusChanged?.call('completed');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al completar: $e')),
    );
  } finally {
    if (mounted) setState(() => _isProcessing = false);
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
        final rawComments = serviceData['comments'] as List<dynamic>? ?? [];
        comentarios =
            rawComments.map((c) => Map<String, String>.from(c as Map)).toList();

        // ✅ Fecha
        final String dateOnly = serviceData['date'] as String? ?? '—';    // e.g. "2025-06-15"
        final String timeOnly = serviceData['time'] as String? ?? '—';

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
                    Text(
                      'Ubicación del trabajo:',
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

                    /// 🔹 Imágenes
                    Text(
                      'Imágenes:',
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

                    /// 🔹 Fecha del servicio
                    Text(
                      'Estado: ${statusNames[_currentStatus] ?? 'Desconocido'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    Text(
                      'Asistir a las:',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    Text(
                      'Fecha: $dateOnly',
                      style: MyTextStyles.inputTextStyle1,
                    ),
                    Text(
                      'Hora: $timeOnly',
                      style: MyTextStyles.inputTextStyle1,
                    ),
                    SizedBox(height: 16.0),

                    /// 🔹 Descripción
                    Text.rich(
                      TextSpan(
                        text: 'Descripción: ',
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

                    /// 🔹 Precio ofertado
                    Text(
                      'Precio Ofertado: ${_workerOfferedPrice != null ? '\Bs ${_workerOfferedPrice!.toStringAsFixed(2)}' : 'No ofertado'}',
                      style: MyTextStyles.inputTextStyle6,
                    ),
                    SizedBox(height: 16.0),

                    /// 🔹 Botones
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
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Enviar Propuesta
                ElevatedButton.icon(
                  onPressed: (_isSendingProposal || _proposalSent)
                      ? null
                      : () => _showProposalDialog(
                      context, widget.serviceRequest.id),
                  icon: Icon(Icons.add_business, color: Color(0xFF830A09)),
                  label: Text(
                    _proposalSent ? 'Propuesta Enviada' : 'Enviar Propuesta',
                    style: GoogleFonts.karla(
                      color: Color(0xFF830A09),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Color(0xFF830A09)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _mostrarComentarios(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                    vertical: 25, horizontal: 16), // Ajuste proporcional
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.comment, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  // Utilizamos un Flexible para ajustar el texto dinámicamente
                  Flexible(
                    child: Text(
                      'Comentarios (${comentarios.length})',
                      overflow: TextOverflow
                          .ellipsis, // Asegura que el texto se recorte si es largo
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            )
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
                  onPressed: () => _showUploadCompletionImageDialog(),
                  icon:
                  Icon(Icons.architecture_sharp, color: Color(0xFFB00020)),
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
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;

                print("Botón de Chat presionado");
                print("workerId: ${widget.workerId}");
                print("userId (actual): $userId");

                if (userId == null) {
                  print("Error: userId es null, usuario no autenticado");
                  return;
                }

                _openWhatsApp(userId);
              },
              icon: Icon(Icons.chat, color: Colors.white),
              label: Text(
                "WhatsApp",
                style: GoogleFonts.karla(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
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
              ],
            ),
          ],
        );

      case 'pending_confirmation':
        return Text('Esperando la confirmación del cliente...');
      case 'completed':
        return Text('Este trabajo ha sido completado.');
      case 'cancelled':
        return Text('Este trabajo ha sido cancelado.');
      case 'blocked':
        return Text('No participarás en este trabajo.');
      default:
        return Container();
    }
  }

  void _openWhatsApp(userId) async {
    if (phoneNumber == null) return;

    final whatsappUrl = Uri.parse(
        "https://wa.me/$phoneNumber?text=Hola $displayName, soy tu trabajador asignado desde ManitosXpress.");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }
}