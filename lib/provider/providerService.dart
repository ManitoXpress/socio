import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../ServiceResponse/get.dart';
import '../ServiceResponse/post.dart';

import '../ServiceResponse/request.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../ServiceResponse/requestServiceType.dart';
import '../ServiceResponse/requestStatus.dart';
import '../Utils/serviceFetcher.dart';
import '../Utils/workerDetails.dart';
import '../controllers/inProgressFetcher.dart';
import '../controllers/offerFetcher.dart';
import '../controllers/serviceCancelled.dart';
import '../controllers/serviceComplete.dart';

class HistorialProvider extends ChangeNotifier {
  // Repositorios
  final ServiceRepository _repoAvailable;
  final OfferRepository _repoOffer;
  final ServiceRepositoryInProgress _repoInProgress;
  final ServiceRepositoryComplete _repoComplete;
  final ServiceRepositoryCancelled _repoCancelled;

  // Estado
  bool isLoading = false;
  String? errorMessage;
  final Map<String, List<ServiceRequest>> _byStatus = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, dynamic> _lastDoc = {};
  final Map<String, bool> _isLoadingMore = {};
  final Map<String, DateTime> _lastLoaded = {};

  final Set<String> _seenServiceIds = {};
  Timer? _autoRefreshTimer;
  bool _autoRefreshActive = false;
  final Map<String, DateTime> _newServiceTimestamps = {};

  HistorialProvider()
      : _repoAvailable = ServiceRepository(
          apiService: ApiService(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoOffer = OfferRepository(
          apiService2: ApiService2(),
          serviceDataFetcher: ServiceDataFetcher(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoInProgress = ServiceRepositoryInProgress(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoComplete = ServiceRepositoryComplete(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        ),
        _repoCancelled = ServiceRepositoryCancelled(
          apiService: ApiService2(),
          firestore: FirebaseFirestore.instance,
        );

  List<ServiceRequest> _ordenarPorFecha(List<ServiceRequest> lista) {
    lista.sort((a, b) {
      final aDate = DateTime.tryParse(a.CreatedAt ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b.CreatedAt ?? '') ?? DateTime(1900);
      return bDate.compareTo(aDate); // Descendente: más reciente primero
    });
    return lista;
  }

  /// Devuelve la lista para cada estado
  List<ServiceRequest> list(String status) => _byStatus[status] ?? [];

  int get availableCount => list('available').length;
  int get offerServiceCount => list('offer').expand((s) => s.offers).length;
  int get inProgressCount => list('in_progress').length;
  int get completedCount => list('completed').length;
  int get cancelledCount => list('cancelled').length;

  bool hasMore(String status) => _hasMore[status] ?? true;
  bool isLoadingMore(String status) => _isLoadingMore[status] ?? false;

  /// Carga todo el historial de una vez (con cache y control de tiempo)
  Future<void> loadAll({
    required String userId,
    required String token,
    required String deviceId,
    bool forceRefresh = false,
  }) async {
    // Cache: solo recarga si pasaron 30s o forceRefresh
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastLoaded['all'] != null &&
        now.difference(_lastLoaded['all']!).inSeconds < 30) {
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // 1) Disponibles
    final availableFut = _repoAvailable.fetchServicesByStatus(
        'available', 'status', userId, token, []).catchError((e, _) {
      debugPrint('Error en available: $e');
      return <ServiceRequest>[];
    });

    // 2) Ofertados  (filtrando por workerId)
    final offerFut = _repoOffer
        .fetchOffersForUser(
      'offer', // valor de status
      userId, // workerId
      token,
      ServiceRequest(
        id: '',
        serviceDateTime: '',
        description: '',
        images: [],
        location: {},
        offeredPrice: 0.0,
        serviceType: ServiceType(
          id: '',
          name: '',
          selectedDate: '',
          selectedTime: '',
        ),
        userId: userId,
        workerId: '',
        isFavorite: false,
        selectedDate: null,
        selectedTime: null,
        acceptedTerms: false,
        expertises: <Expertise>[],
        status: Status(id: 'offer', name: 'Ofertado'),
        hasOffer: false,
        offers: [],
        devicesId: '',
        subcategoryName: '',
        CreatedAt: '',
      ),
      deviceId,
    )
        .catchError((e, _) {
      debugPrint('Error en offer: $e');
      return <ServiceRequest>[];
    });

    // 3) En progreso → solo usamos 'in_progress'
    final estados = [
      'in_progress',
    ];

    final inProgressFut = Future.wait(
      estados.map((st) => _repoInProgress
              .fetchServicesByInProgress(
            st, // un status cada vez
            userId,
            'status',
            token,
          )
              .catchError((e, _) {
            debugPrint('Error en $st: $e');
            return <ServiceRequest>[];
          })),
    ).then((listas) {
      // listas es List<List<ServiceRequest>> → lo aplanamos
      return listas.expand((l) => l).toList();
    });

    // 4) Completados
    final completedFut = _repoComplete
        .fetchServicesByComplete('completed', userId, 'status', token)
        .catchError((e, _) {
      debugPrint('Error en completed: $e');
      return <ServiceRequest>[];
    });

    // 5) Cancelados
    final cancelledFut = _repoCancelled
        .fetchServicesByCancelled('cancelled', userId, 'status', token)
        .catchError((e, _) {
      debugPrint('Error en cancelled: $e');
      return <ServiceRequest>[];
    });

    try {
      final results = await Future.wait<List<ServiceRequest>>([
        availableFut,
        offerFut,
        inProgressFut,
        completedFut,
        cancelledFut,
      ]);

      // Marcar servicios nuevos
      for (int i = 0; i < results.length; i++) {
        for (final service in results[i]) {
          if (!_seenServiceIds.contains(service.id)) {
            service.isNew = true;
            _newServiceTimestamps[service.id] = DateTime.now();
          } else {
            service.isNew = false;
          }
        }
      }
      // Limpiar servicios viejos del set
      _seenServiceIds.addAll(results.expand((l) => l.map((s) => s.id)));

      _byStatus['available'] = _ordenarPorFecha(results[0]);
      _byStatus['offer'] = _ordenarPorFecha(results[1]);
      _byStatus['in_progress'] = _ordenarPorFecha(results[2]);
      _byStatus['completed'] = _ordenarPorFecha(results[3]);
      _byStatus['cancelled'] = _ordenarPorFecha(results[4]);
      _hasMore['available'] = results[0].length >= 20;
      _hasMore['offer'] = results[1].length >= 20;
      _hasMore['in_progress'] = results[2].length >= 20;
      _hasMore['completed'] = results[3].length >= 20;
      _hasMore['cancelled'] = results[4].length >= 20;
      _lastLoaded['all'] = now;

      // Programar ocultar el badge después de 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        bool updated = false;
        for (var list in _byStatus.values) {
          for (final service in list) {
            if (service.isNew == true &&
                _newServiceTimestamps[service.id] != null) {
              final diff =
                  DateTime.now().difference(_newServiceTimestamps[service.id]!);
              if (diff.inSeconds >= 5) {
                service.isNew = false;
                updated = true;
              }
            }
          }
        }
        if (updated) notifyListeners();
      });
    } catch (e, st) {
      errorMessage = 'Error cargando historial';
      debugPrint('loadAll fallo inesperado: $st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Paginación: carga más servicios para un estado
  Future<void> loadMore({
    required String status,
    required String userId,
    required String token,
    required String deviceId,
    int limit = 20,
  }) async {
    if (_isLoadingMore[status] == true || !hasMore(status)) return;
    _isLoadingMore[status] = true;
    notifyListeners();
    try {
      // Aquí deberías implementar la consulta paginada real
      // Por ahora, solo simula un delay
      await Future.delayed(const Duration(milliseconds: 800));
      // Cuando implementes paginación real, agrega los nuevos items a _byStatus[status]
      // y actualiza _hasMore[status] según la respuesta
    } finally {
      _isLoadingMore[status] = false;
      notifyListeners();
    }
  }

  /// Refrescar (llama de nuevo a loadAll)
  Future<void> refresh({
    required String userId,
    required String token,
    required String deviceId,
  }) =>
      loadAll(
          userId: userId, token: token, deviceId: deviceId, forceRefresh: true);

  /// Inicia el polling automático cada 30 segundos
  void startAutoRefresh({
    required String userId,
    required String token,
    required String deviceId,
  }) {
    if (_autoRefreshActive) return;
    _autoRefreshActive = true;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isLoading) {
        loadAll(userId: userId, token: token, deviceId: deviceId);
      }
    });
  }

  /// Detiene el polling automático
  void stopAutoRefresh() {
    _autoRefreshActive = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
