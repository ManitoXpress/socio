import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';


import '../ServiceResponse/get.dart';
import '../ServiceResponse/post.dart';
import '../ServiceResponse/request.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../ServiceResponse/requestLocation.dart';
import '../ServiceResponse/requestServiceType.dart';
import '../ServiceResponse/requestStatus.dart';
import '../ServiceResponse/requestUserData.dart';
import '../ServiceResponse/requestWorker.dart';
import '../Utils/authUtils.dart';
import '../Utils/proposal.dart';
import '../constans/service_constant.dart';
import '../models/comment_model.dart';
import '../models/offerModels.dart';
import '../models/serviceModels.dart';
import '../models/workerModels.dart';

class ServicePartnerProvider extends ChangeNotifier {
  final ServiceRequestModel serviceRequest;
  final OfferModel offer;
  final String userId; // ID del usuario cliente
  final UserData userData; // Datos del socio (trabajador)
  final String workerId;
  final List<OfferModel> offers; // Lista de ofertas si hace falta
  final ApiService apiService;
  final ApiService2 apiService2;

  // STREAM de Firestore para el documento "services/{id}"
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _serviceStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _serviceSub;

  // Estado interno
  ServiceRequestModel? _serviceData;
  WorkerDetailsModel? _workerDetails;
  bool _hasExistingProposal = false;
  double? _workerOfferedPrice;
  List<CommentModel> _comments = [];
  String _currentStatus = ServiceStatus.available;
  LatLng _initialPosition = const LatLng(0, 0);
  bool _isLoading = true;
  String? _errorMessage;

  // Controles locales
  final TextEditingController priceController = TextEditingController();
  final TextEditingController cancelReasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _isSendingProposal = false;
  bool _proposalSent = false;
  bool _isProcessing = false;

  // Conjunto local para evitar reenvío múltiple de propuesta
  final Set<String> _proposalsSentForServiceIds = {};

  ServicePartnerProvider({
    required this.serviceRequest,
    required this.offer,
    required this.userData,
    required this.workerId,
    required this.offers,
    required this.apiService,
    required this.apiService2,
    required this.userId,
  }) {
    // Inicializar _serviceData con los datos que vienen de serviceList.dart
    _serviceData = serviceRequest;

    _serviceStream = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceRequest.id)
        .snapshots();

    _init();
  }

  // Getters públicos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ServiceRequestModel? get serviceData => _serviceData;
  WorkerDetailsModel? get workerDetails => _workerDetails;
  double? get workerOfferedPrice => _workerOfferedPrice;
  List<CommentModel> get comments => List.unmodifiable(_comments);
  String get currentStatus => _currentStatus;
  LatLng get initialPosition => _initialPosition;
  bool get hasExistingProposal => _proposalSent || _hasExistingProposal;
  bool get isSendingProposal => _isSendingProposal;
  bool get isProcessing => _isProcessing;

  void _setError(String mensaje) {
    _errorMessage = mensaje;
    _notifyIfNeeded();
  }

  void _notifyIfNeeded() {
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    _serviceSub?.cancel();
    priceController.dispose();
    cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // 1) Suscribirse a Stream de Firestore
    _serviceSub = _serviceStream.listen(
      (snapshot) {
        if (!snapshot.exists) {
          _setError('El servicio no existe.');
          return;
        }
        _parseService(snapshot);
      },
      onError: (e) => _setError('Error al escuchar servicio: $e'),
    );

    // 2) Cargar detalles del trabajador (solo si workerId NO está vacío)
    if (workerId.isNotEmpty) {
      await _loadWorkerDetails();
    }

    // 3) Verificar si ya existe propuesta (API / Firebase)
    await _checkExistingProposal();

    _isLoading = false;
    _notifyIfNeeded();
  }

  void _parseService(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final nueva = ServiceRequestModel.fromDocument(snapshot);

    // Preservar los rawOffers que ya tenemos (pasados desde serviceList.dart)
    // ya que Firestore podría no tener la información de ofertas que necesitamos
    final preservedRawOffers = _serviceData?.rawOffers ?? [];

    _serviceData = nueva;
    _currentStatus = nueva.status;

    // Debug: Imprimir información del servicio
    // Usar los rawOffers preservados si están disponibles, sino usar los de Firestore
    final offersToUse =
        preservedRawOffers.isNotEmpty ? preservedRawOffers : nueva.rawOffers;

    // Actualizar el serviceData con los offers correctos
    _serviceData = ServiceRequestModel(
      id: nueva.id,
      status: nueva.status,
      date: nueva.date,
      time: nueva.time,
      description: nueva.description,
      location: nueva.location,
      images: nueva.images,
      expertises: nueva.expertises,
      rawOffers: offersToUse,
      rawComments: nueva.rawComments,
      userId: nueva.userId,
      workerId: nueva.workerId,
      completionImageUrl: nueva.completionImageUrl,
    );

    // Posición inicial
    final lat = nueva.location['lat'] as double? ?? 0.0;
    final lng = nueva.location['lng'] as double? ?? 0.0;
    _initialPosition = LatLng(lat, lng);

    // Comentarios
    _comments = nueva.rawComments
        .map((c) => CommentModel.fromMap(Map<String, String>.from(c)))
        .toList();

    // Precio ofertado (si corresponde)
    if (workerId.isNotEmpty) {
      final anyOffer = offersToUse.firstWhere(
        (o) => o['workerId'] == workerId,
        orElse: () => <String, dynamic>{},
      );
      if (anyOffer.isNotEmpty) {
        final raw = anyOffer['offeredPrice'];
        _workerOfferedPrice =
            (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
      } else {
        _workerOfferedPrice = null;
      }
    } else {
    }

    // Si antes no había workerDetails y ahora sí, recargar
    if (_workerDetails == null && nueva.workerId.isNotEmpty) {
      _loadWorkerDetails();
    }
    _notifyIfNeeded();
  }

  Future<void> _loadWorkerDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();
      if (doc.exists) {
        _workerDetails =
            WorkerDetailsModel.fromMap(Map<String, dynamic>.from(doc.data()!));
      } else {
        _workerDetails = null;
      }
    } catch (e) {
      _setError('Error cargando detalles del trabajador: $e');
      _workerDetails = null;
    }
    _notifyIfNeeded();
  }

  Future<void> _checkExistingProposal() async {
    try {
      // Verificar con ProposalService
      final existingLocal = await ProposalService.checkExistingProposal(
        serviceRequestId: serviceRequest.id,
        workerId: workerId,
      );
      
      // Verificar con ApiService (backend)
      final existingBackend = await ApiService().checkProposalExists(
        serviceRequest.id, 
        workerId
      );
      
      // Si existe en cualquiera de los dos, marcar como existente
      final existing = existingLocal || existingBackend;
      _hasExistingProposal = existing;
      _proposalSent = existing;
    } catch (e) {
      // Si hay error, asumimos que no existe aún
      _hasExistingProposal = false;
      _proposalSent = false;
    }
    _notifyIfNeeded();
  }

  Future<bool> sendProposal() async {
    // Validación inicial más estricta
    if (_isSendingProposal) {
      _setError('Ya se está enviando una propuesta');
      return false;
    }
    
    if (_proposalSent || _hasExistingProposal) {
      _setError('Ya existe una propuesta para este servicio');
      return false;
    }

    _isSendingProposal = true;
    _notifyIfNeeded();

    final offeredPrice = double.tryParse(priceController.text.trim()) ?? 0.0;
    const extraCosts = 3.0;

    // Verificar workerId válido
    if (workerId.isEmpty) {
      _setError('workerId está vacío o es nulo');
      _isSendingProposal = false;
      _notifyIfNeeded();
      return false;
    }

    // 1) Verificar en servidor si ya existe (más robusto)
    try {
      final alreadyExists =
          await ApiService().checkProposalExists(serviceRequest.id, workerId);
      if (alreadyExists) {
        _setError('Ya existe una propuesta para este servicio');
        _isSendingProposal = false;
        _notifyIfNeeded();
        return false;
      }
    } catch (e) {
      // Si hay error en verificación, NO continuamos
      _setError('Error al verificar propuestas existentes: $e');
      _isSendingProposal = false;
      _notifyIfNeeded();
      return false;
    }

    // 2) Verificación adicional con ProposalService
    try {
      final existingProposal = await ProposalService.checkExistingProposal(
        serviceRequestId: serviceRequest.id,
        workerId: workerId,
      );
      if (existingProposal) {
        _setError('Ya existe una propuesta para este servicio');
        _isSendingProposal = false;
        _notifyIfNeeded();
        return false;
      }
    } catch (e) {
      // Si hay error en verificación local, NO continuamos
      _setError('Error al verificar propuestas existentes: $e');
      _isSendingProposal = false;
      _notifyIfNeeded();
      return false;
    }

    // 3) Convertir ServiceRequestModel -> ServiceRequest (dominio) usando todos sus campos
    final domainService = ServiceRequest(
      CreatedAt: '', // tu lógica para CreatedAt
      serviceDateTime: '${serviceRequest.date} ${serviceRequest.time}',
      id: serviceRequest.id,
      devicesId: '', // si lo requieres
      description: serviceRequest.description,
      images: serviceRequest.images,
      location: {
        'lat': serviceRequest.location['lat'] as double? ?? 0.0,
        'lng': serviceRequest.location['lng'] as double? ?? 0.0,
      },
      offeredPrice: offeredPrice,
      serviceType: ServiceType(
        id: '',
        name: '',
        selectedDate: serviceRequest.date,
        selectedTime: serviceRequest.time,
      ),
      userId: serviceRequest.userId,
      workerId: workerId,
      isFavorite: false,
      selectedDate: serviceRequest.date,
      selectedTime: serviceRequest.time,
      acceptedTerms: false,
      expertises: serviceRequest.expertises
          .map((e) => Expertise(id: e.id, name: e.name))
          .toList(),
      status: Status(
        id: serviceRequest.status,
        name: Status.getNameById(serviceRequest.status),
      ),
      subcategoryName: '', // si lo necesitas
      hasOffer: serviceRequest.rawOffers.isNotEmpty,
      offers: serviceRequest.rawOffers
          .map((o) => Offer.fromMap(Map<String, dynamic>.from(o)))
          .toList(),

      workerDetails: _workerDetails != null
          ? WorkerDetails(
              id: _workerDetails!.id,
              displayName: _workerDetails!.displayName,
              email: _workerDetails!.email,
              imagePath: _workerDetails!.imagePath,
              idDocumentImagePath: _workerDetails!.idDocumentImagePath,
              expLevel: _workerDetails!.expLevel != null
                  ? [_workerDetails!.expLevel.toString()]
                  : [],
              expertises: _workerDetails!.expertises
                  .map((e) => Expertise(id: e.id, name: e.name))
                  .toList(),
              phoneNumber: _workerDetails!.phoneNumber,
              // AHORA: instanciamos Location en lugar de pasar un Map
              location: Location(
                lat: _workerDetails!.location['lat'] ?? 0.0,
                lng: _workerDetails!.location['lng'] ?? 0.0,
              ),
              // Resto de campos adicionales…
              certificateImagePaths: _workerDetails!.certificateImagePaths,
              criminalRecordImagePath: _workerDetails!.criminalRecordImagePath,
              fcmToken: _workerDetails!.fcmToken,
              verificationStatus: _workerDetails!.verificationStatus,
              idCardNumber: _workerDetails!.idCardNumber,
            )
          : null,
    );

    // 4) Enviar propuesta al servidor usando el objeto de dominio
    try {
      await ApiService().sendProposalToServer(
        domainService,
        '',
        offeredPrice.toString(),
        extraCosts,
        workerId,
      );
      
      // Actualizar estado inmediatamente después del envío exitoso
      _workerOfferedPrice = offeredPrice;
      _proposalSent = true;
      _hasExistingProposal = true;
      _proposalsSentForServiceIds.add(serviceRequest.id);
      
      // Refresca el estado consultando el backend para confirmar
      await _checkExistingProposal();
      
      _isSendingProposal = false;
      _notifyIfNeeded();
      return true;
    } catch (e) {
      _setError('Error al enviar propuesta: $e');
      _isSendingProposal = false;
      _notifyIfNeeded();
      return false;
    }
  }

  Future<void> addComment(String texto) async {
    if (_serviceData == null) {
      _setError('Servicio no cargado.');
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    String rol = 'desconocido';
    String nombre = 'Anónimo';

    if (currentUid == serviceRequest.userId) {
      rol = 'cliente';
      nombre = 'Cliente';
    } else if (currentUid == workerId) {
      rol = 'trabajador';
      nombre = 'Trabajador';
    }

    final now = TimeOfDay.now();
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final nuevo = CommentModel(
      nombre: nombre,
      mensaje: texto,
      hora: hora,
      rol: rol,
    );

    _comments.add(nuevo);
    final commentsMap = _comments.map((c) => c.toMap()).toList();

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceRequest.id)
          .update({'comments': commentsMap});
    } catch (e) {
      _setError('Error al agregar comentario: $e');
    }
    _notifyIfNeeded();
  }

  Future<void> blockParticipation() async {
    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceRequest.id)
          .update({
        'blockedUsers': FieldValue.arrayUnion([workerId])
      });
      // Actualizamos estado localmente
      _currentStatus = ServiceStatus.blocked;
      _notifyIfNeeded();
    } catch (e) {
      _setError('Error al bloquear participación: $e');
    }
  }

  Future<void> submitCompletionImage(String imagePath) async {
    // 1) Usar la imagen ya seleccionada
    _selectedImageFile = File(imagePath);
    _notifyIfNeeded();

    // 2) Subir al backend
    _isProcessing = true;
    _notifyIfNeeded();

    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        _setError('Error: usuario no autenticado');
        _isProcessing = false;
        _notifyIfNeeded();
        return;
      }

      await apiService.uploadImageToBackend(
        _selectedImageFile!.path,
        serviceRequest.id,
        token,
      );

      // Suponemos que la API nos devuelve la URL subida
      await apiService.uploadImageToBackend(
        imagePath,
        serviceRequest.id,
        token,
      );
      _notifyIfNeeded();

      // 3) Continuar con marcar completado:
      await completeAndAccept();
    } catch (e) {
      _setError('Error al subir imagen: $e');
      _isProcessing = false;
      _notifyIfNeeded();
    }
  }

  Future<void> completeAndAccept() async {
    _isProcessing = true;
    _notifyIfNeeded();

    try {
      // 1) Obtener todas las ofertas del servicio
      final offersList = await apiService2.getOffers2(serviceRequest.id);
      // Buscar la oferta del worker actual que esté en progreso
      Map<String, dynamic>? workerOffer;
      for (final offer in offersList) {
        if (offer['workerId'] == workerId &&
            (offer['status'] == 'in_progress' ||
                offer['status'] == ServiceStatus.inProgress)) {
          workerOffer = offer;
          break;
        }
      }
      // Si no hay ninguna en progreso, buscar la primera que no esté cancelada
      workerOffer ??= offersList.firstWhere(
        (offer) =>
            offer['workerId'] == workerId && offer['status'] != 'cancelled',
        orElse: () => <String, dynamic>{},
      );
      if (workerOffer == null) {
        throw Exception(
            'No se encontró una oferta válida para este trabajador.');
      }
      if (workerOffer.isEmpty) {
        throw Exception(
            'No se encontró una oferta válida para este trabajador.');
      }
      final offerId = workerOffer['id'] as String;
      final raw = workerOffer['offeredPrice'];
      final offeredPrice = (raw is num)
          ? raw.toDouble()
          : double.tryParse(raw.toString()) ?? 0.0;
      const extraCosts = 3.0;
      final commission = offeredPrice * 0.10;
      final totalPrice = offeredPrice + extraCosts;
      final clientNIT = workerOffer['clientNIT'] as String? ?? '';
      final paymentStatus = 'debe';

      // 2) Parchar oferta
      final offerPayload = {
        'offeredPrice': offeredPrice,
        'commission': commission,
        'extraCosts': extraCosts,
        'totalPrice': totalPrice,
        'status': ServiceStatus.completed,
        'clientNIT': clientNIT,
        'paymentStatus': paymentStatus,
        'completionImageUrl': _uploadedImageUrl,
      };
      await apiService2.patchOffer(offerId, offerPayload);

      // 3) Parchar servicio (el mismo que está en progreso)
      final servicePayload = {
        'commission': commission,
        'extraCosts': extraCosts,
        'totalPrice': totalPrice,
        'status': ServiceStatus.completed,
        'clientNIT': clientNIT,
        'paymentStatus': paymentStatus,
        'completionImageUrl': _uploadedImageUrl,
      };
      await apiService2.patchService(serviceRequest.id, servicePayload);

      // 4) Actualizar estado local
      _currentStatus = ServiceStatus.completed;
      _notifyIfNeeded();
    } catch (e) {
      _setError('Error al completar trabajo: $e');
    } finally {
      _isProcessing = false;
      _notifyIfNeeded();
    }
  }

  String? getWhatsAppUrl() {
    if (_workerDetails == null || _workerDetails!.phoneNumber.isEmpty) {
      return null;
    }
    final name = _workerDetails!.displayName;
    final phone = _workerDetails!.phoneNumber;
    return 'https://wa.me/$phone?text=Hola $name, soy tu trabajador asignado desde ManitosXpress.';
  }
}