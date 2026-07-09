import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
import 'package:socio/Utils/cacheLocal.dart';

class ServiceRepositoryInProgress {
  final ApiService2 apiService;
  final FirebaseFirestore firestore;

  ServiceRepositoryInProgress({required this.apiService, required this.firestore});

  Future<List<ServiceRequest>> fetchServicesByInProgress(String status, String userId, String column, String token) async {
    return await _fetch(status, userId);
  }

  Future<List<ServiceRequest>> _fetch(String status, String userId) async {
    try {
      print('[InProgress] workerId=$userId status=$status');
      final snap = await firestore.collection('services')
          .where('workerId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .get();
      print('[InProgress] docs=${snap.docs.length}');
      if (snap.docs.isEmpty) return [];

      final list = snap.docs.map((doc) {
        final d = {'id': doc.id, ...doc.data()};
        final st = (d['status'] as String?) ?? status;
        return ServiceRequest(
          id: doc.id,
          serviceDateTime: d['serviceDateTime']?.toString() ?? '',
          description: d['description']?.toString() ?? '',
          expertises: _exp(d),
          images: (d['images'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? [],
          location: _loc(d['location']),
          offeredPrice: _price(d['offeredPrice']),
          userId: d['userId']?.toString() ?? '',
          workerId: d['workerId']?.toString() ?? userId,
          status: Status(id: st, name: Status.getNameById(st)),
          devicesId: '',
          serviceType: ServiceType(
            name: d['serviceType']?['name']?.toString() ?? '',
            id: d['serviceType']?['id']?.toString() ?? '',
            selectedDate: d['serviceType']?['selectedDate']?.toString() ?? '',
            selectedTime: d['serviceType']?['selectedTime']?.toString() ?? '',
          ),
          isFavorite: d['isFavorite'] as bool? ?? false,
          acceptedTerms: d['acceptedTerms'] as bool? ?? false,
          subcategoryName: d['subcategoryName']?.toString() ?? '',
          hasOffer: true,
          offers: [],
          CreatedAt: d['createdAt'] ?? '',
        );
      }).toList();

      await Future.wait(list.map((svc) async {
        try {
          final os = await firestore.collection('offers')
              .where('serviceId', isEqualTo: svc.id)
              .where('workerId', isEqualTo: userId)
              .get();
          if (os.docs.isNotEmpty) {
            final o = {'id': os.docs.first.id, ...os.docs.first.data()};
            final oSt = o['status']?.toString() ?? 'accepted';
            svc.offers = [Offer(
              id: o['id']?.toString() ?? '',
              workerId: userId,
              offeredPrice: _price(o['offeredPrice']),
              hasOffer: true,
              serviceId: svc.id,
              extraCosts: _price(o['extraCosts']),
              totalPrice: _price(o['totalPrice']),
              status: Status(id: oSt, name: Status.getNameById(oSt)),
              userToken: '',
              createdAt: DateTime.tryParse(o['createdAt']?.toString() ?? '') ?? DateTime.now(),
              expertises: svc.expertises,
              subcategoryName: svc.subcategoryName,
            )];
            svc.offeredPrice = _price(o['offeredPrice']);
          }
        } catch (e) { print('[InProgress] oferta err: $e'); }
      }));

      list.forEach(LocalCacheService.cacheServiceRequest);
      return list;
    } catch (e) {
      print('[InProgress] Firestore err: $e');
      return [];
    }
  }

  List<Expertise> _exp(Map<String, dynamic> d) {
    return ((d['expertises'] as List?) ?? [])
        .map((e) => Expertise(id: e['id']?.toString() ?? '', name: e['name']?.toString() ?? ''))
        .toList();
  }

  Map<String, double> _loc(dynamic r) {
    if (r is Map<String, dynamic>) return r.map((k, v) => MapEntry(k, (v as num).toDouble()));
    return {};
  }

  double _price(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
