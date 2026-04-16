import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/requestWorker.dart';


class ServiceDataFetcher {
  // Obtener los detalles del trabajador
  Future<WorkerDetails?> fetchWorkerDetails(String? workerId) async {
    if (workerId == null || workerId.isEmpty) {
      return null;
    }

    try {
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .get();

      if (workerSnapshot.exists) {
        return WorkerDetails.fromMap(workerSnapshot.data()!);
      } else {
      }
    } catch (e) {
    }
    return null;
  }

  // Obtener el precio ofertado para un servicio específico
  Future<double?> fetchOfferedPrice(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) {
      return null;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final offerData = querySnapshot.docs.first.data();
        return double.tryParse(offerData['offeredPrice'].toString());
      } else {
      }
    } catch (e) {
    }
    return null;
  }
}
