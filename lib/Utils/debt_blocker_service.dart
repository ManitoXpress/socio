import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DebtBlockerService {
  static const String _debtWarningKey = 'debt_warning_shown';
  static const String _debtWarningDateKey = 'debt_warning_date';
  static const String _debtBlockDateKey = 'debt_block_date';
  static const int _overdueDays = 3; // 3 días para vencimiento

  static final DebtBlockerService _instance = DebtBlockerService._internal();
  factory DebtBlockerService() => _instance;
  DebtBlockerService._internal();

  Timer? _timer;
  final StreamController<bool> _blockStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get blockStateStream => _blockStateController.stream;

  /// Obtiene la fecha actual en Bolivia (UTC-4)
  DateTime get _boliviaTime {
    final now = DateTime.now().toUtc();
    return now.add(const Duration(hours: 4)); // Bolivia UTC-4
  }

  /// Convierte createdAt a DateTime
  DateTime _parseCreatedAt(dynamic createdAtData) {
    if (createdAtData is Timestamp) {
      return createdAtData.toDate();
    } else if (createdAtData is String) {
      return DateTime.tryParse(createdAtData) ?? DateTime.now();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      return DateTime.now();
    }
  }

  /// Calcula la fecha de vencimiento (3 días después de createdAt)
  DateTime _calculateDueDate(DateTime createdAt) {
    return createdAt.add(Duration(days: _overdueDays));
  }

  /// Calcula los días restantes hasta el vencimiento
  int _calculateDaysUntilDue(DateTime dueDate) {
    final now = _boliviaTime;
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  /// Obtiene todas las deudas con información de vencimiento
  Future<List<Map<String, dynamic>>> getAllDebtsWithDueInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Forzar recarga desde el servidor sin caché para evitar problemas de sincronización
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.server));

      print('Total de ofertas encontradas: ${offersSnapshot.docs.length}');
      final debts = <Map<String, dynamic>>[];

      for (final doc in offersSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().trim().toLowerCase();
        final paymentStatus =
            data['paymentStatus']?.toString().trim().toLowerCase();

        print('Oferta ${doc.id}: status=$status, paymentStatus=$paymentStatus');

        // Solo considerar servicios completados que no han sido pagados
        if (status == 'completed' && paymentStatus != 'pagado') {
          print('✅ Agregando deuda: ${doc.id} - paymentStatus: $paymentStatus');
          final commission = (data['commission'] ?? 0.0) as num;
          final extraCosts = (data['extraCosts'] ?? 0.0) as num;
          final serviceId = data['serviceId'] ?? 'Sin ID';
          final debtAmount = commission + extraCosts;

          final createdAt = _parseCreatedAt(data['createdAt']);
          final dueDate = _calculateDueDate(createdAt);
          final daysUntilDue = _calculateDaysUntilDue(dueDate);
          final isOverdue = daysUntilDue < 0;
          final isWarning = daysUntilDue <= 1 && daysUntilDue >= 0;

          // NUEVA LÓGICA: Determinar si debe bloquear basado en paymentStatus Y tiempo
          final shouldBlockByStatus = paymentStatus == 'debe';
          final shouldBlockByTime = isOverdue && shouldBlockByStatus;
          final shouldShowWarning = shouldBlockByStatus && !isOverdue;

          debts.add({
            'id': doc.id,
            'serviceId': serviceId,
            'commission': commission,
            'extraCosts': extraCosts,
            'total': debtAmount,
            'createdAt': createdAt,
            'dueDate': dueDate,
            'daysUntilDue': daysUntilDue,
            'isOverdue': isOverdue,
            'isWarning': isWarning,
            'paymentStatus': paymentStatus,
            'shouldBlockByStatus': shouldBlockByStatus,
            'shouldBlockByTime': shouldBlockByTime,
            'shouldShowWarning': shouldShowWarning,
            'formattedCreatedAt':
                DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
            'formattedDueDate': DateFormat('dd/MM/yyyy HH:mm').format(dueDate),
          });
        } else {
          print(
              '❌ Excluyendo oferta: ${doc.id} - status: $status, paymentStatus: $paymentStatus');
        }
      }

      print('Total de deudas encontradas: ${debts.length}');

      // Ordenar por fecha de vencimiento (más próximas primero)
      debts.sort((a, b) =>
          (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

      return debts;
    } catch (e) {
      print('Error obteniendo deudas con información de vencimiento: $e');
      return [];
    }
  }

  /// Obtiene solo las deudas que deben bloquear la aplicación
  Future<List<Map<String, dynamic>>> getOverdueDebts() async {
    final allDebts = await getAllDebtsWithDueInfo();
    print('getOverdueDebts - Total deudas: ${allDebts.length}');

    // NUEVA LÓGICA: Solo bloquear si han pasado 3 días Y paymentStatus es "debe"
    final overdueDebts =
        allDebts.where((debt) => debt['shouldBlockByTime'] == true).toList();

    print(
        'getOverdueDebts - Deudas que bloquean (3 días + paymentStatus "debe"): ${overdueDebts.length}');
    print('getOverdueDebts - Detalles de todas las deudas:');
    for (final debt in allDebts) {
      print(
          '  - ${debt['serviceId']}: paymentStatus=${debt['paymentStatus']}, isOverdue=${debt['isOverdue']}, shouldBlockByStatus=${debt['shouldBlockByStatus']}, shouldBlockByTime=${debt['shouldBlockByTime']}');
    }

    return overdueDebts;
  }

  /// Calcula el total de deudas pendientes del usuario
  Future<double> getTotalDebt() async {
    try {
      final debts = await getAllDebtsWithDueInfo();
      return debts.fold<double>(
          0.0, (sum, debt) => sum + (debt['total'] as double));
    } catch (e) {
      print('Error calculando deuda total: $e');
      return 0.0;
    }
  }

  /// Calcula el total de deudas que bloquean la aplicación
  Future<double> getTotalOverdueDebt() async {
    try {
      final overdueDebts = await getOverdueDebts();
      return overdueDebts.fold<double>(
          0.0, (sum, debt) => sum + (debt['total'] as double));
    } catch (e) {
      print('Error calculando deuda vencida total: $e');
      return 0.0;
    }
  }

  /// Verifica si debe mostrar la advertencia de deuda
  Future<bool> shouldShowDebtWarning() async {
    final debts = await getAllDebtsWithDueInfo();
    print('shouldShowDebtWarning - Total deudas: ${debts.length}');

    if (debts.isEmpty) {
      print('shouldShowDebtWarning - No hay deudas, no mostrar advertencia');
      return false;
    }

    // NUEVA LÓGICA: Mostrar advertencia si hay deudas con paymentStatus "debe" pero no han vencido
    final warningDebts =
        debts.where((debt) => debt['shouldShowWarning'] == true).toList();

    print(
        'shouldShowDebtWarning - Deudas de advertencia (paymentStatus "debe" pero no vencidas): ${warningDebts.length}');
    print('shouldShowDebtWarning - Detalles de deudas:');
    for (final debt in debts) {
      print(
          '  - ${debt['serviceId']}: paymentStatus=${debt['paymentStatus']}, isOverdue=${debt['isOverdue']}, shouldShowWarning=${debt['shouldShowWarning']}');
    }

    return warningDebts.isNotEmpty;
  }

  /// Verifica si debe bloquear la aplicación por deuda vencida
  Future<bool> shouldBlockApp() async {
    final overdueDebts = await getOverdueDebts();
    final hasOverdueDebts = overdueDebts.isNotEmpty;

    print(
        'shouldBlockApp - Deudas que bloquean (3 días + paymentStatus "debe"): ${overdueDebts.length}');
    print(
        'shouldBlockApp - ¿Debe bloquear por deudas vencidas? $hasOverdueDebts');

    if (hasOverdueDebts) {
      print('shouldBlockApp - Detalles de deudas que bloquean:');
      for (final debt in overdueDebts) {
        print(
            '  - ${debt['serviceId']}: paymentStatus=${debt['paymentStatus']}, isOverdue=${debt['isOverdue']}, shouldBlockByTime=${debt['shouldBlockByTime']}');
      }
    }

    return hasOverdueDebts;
  }

  /// Obtiene los días restantes antes del vencimiento de la deuda más próxima
  Future<int> getDaysUntilNextDue() async {
    final debts = await getAllDebtsWithDueInfo();
    if (debts.isEmpty) return -1;

    // Encontrar la deuda con vencimiento más próximo
    final nextDueDebt = debts.reduce((a, b) =>
        (a['daysUntilDue'] as int) < (b['daysUntilDue'] as int) ? a : b);

    return nextDueDebt['daysUntilDue'] as int;
  }

  /// Inicia el monitoreo de deudas
  void startDebtMonitoring() {
    _timer?.cancel();
    // Para producción, verificar cada 5 minutos
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final shouldBlock = await shouldBlockApp();
      print('Monitoreo: ¿Debe bloquear? $shouldBlock');
      _blockStateController.add(shouldBlock);
    });
  }

  /// Detiene el monitoreo de deudas
  void stopDebtMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Resetea el estado de deudas
  Future<void> _resetDebtState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_debtWarningKey);
    await prefs.remove(_debtWarningDateKey);
    await prefs.remove(_debtBlockDateKey);
  }

  /// Obtiene los detalles de las deudas que bloquean para WhatsApp
  Future<Map<String, dynamic>> getOverdueDebtDetailsForWhatsApp() async {
    try {
      final overdueDebts = await getOverdueDebts();
      double totalAmount = 0.0;
      final serviceIds = <String>[];

      for (final debt in overdueDebts) {
        totalAmount += debt['total'] as double;
        serviceIds.add(debt['serviceId'] as String);
      }

      return {
        'debts': overdueDebts,
        'totalAmount': totalAmount,
        'serviceIds': serviceIds,
      };
    } catch (e) {
      print('Error obteniendo detalles de deuda vencida: $e');
      return {'totalAmount': 0.0, 'debts': [], 'serviceIds': []};
    }
  }

  /// Obtiene los detalles de las deudas de advertencia para WhatsApp
  Future<Map<String, dynamic>> getWarningDebtDetailsForWhatsApp() async {
    try {
      final allDebts = await getAllDebtsWithDueInfo();
      final warningDebts =
          allDebts.where((debt) => debt['shouldShowWarning'] == true).toList();
      double totalAmount = 0.0;
      final serviceIds = <String>[];

      for (final debt in warningDebts) {
        totalAmount += debt['total'] as double;
        serviceIds.add(debt['serviceId'] as String);
      }

      return {
        'debts': warningDebts,
        'totalAmount': totalAmount,
        'serviceIds': serviceIds,
      };
    } catch (e) {
      print('Error obteniendo detalles de deuda de advertencia: $e');
      return {'totalAmount': 0.0, 'debts': [], 'serviceIds': []};
    }
  }

  /// Método de debug para verificar datos de Firestore
  Future<void> debugFirestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('debugFirestoreData - No hay usuario autenticado');
        return;
      }

      print('debugFirestoreData - Verificando datos para usuario: ${user.uid}');

      // Forzar recarga sin caché
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.server));

      print(
          'debugFirestoreData - Total ofertas en Firestore: ${offersSnapshot.docs.length}');

      for (final doc in offersSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().trim().toLowerCase();
        final paymentStatus =
            data['paymentStatus']?.toString().trim().toLowerCase();
        final commission = data['commission'] ?? 0.0;
        final extraCosts = data['extraCosts'] ?? 0.0;
        final serviceId = data['serviceId'] ?? 'Sin ID';

        print('debugFirestoreData - Oferta ${doc.id}:');
        print('  - serviceId: $serviceId');
        print('  - status: "$status"');
        print('  - paymentStatus: "$paymentStatus"');
        print('  - commission: $commission');
        print('  - extraCosts: $extraCosts');
        print('  - status == "completed": ${status == 'completed'}');
        print('  - paymentStatus != "pagado": ${paymentStatus != 'pagado'}');
        print(
            '  - Debería ser deuda: ${status == 'completed' && paymentStatus != 'pagado'}');
        print('  ---');
      }
    } catch (e) {
      print('debugFirestoreData - Error: $e');
    }
  }

  /// Método para forzar recarga de datos sin caché
  Future<List<Map<String, dynamic>>>
      getAllDebtsWithDueInfoForceRefresh() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Forzar recarga desde el servidor sin caché
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.server));

      print(
          'getAllDebtsWithDueInfoForceRefresh - Total ofertas encontradas: ${offersSnapshot.docs.length}');
      final debts = <Map<String, dynamic>>[];

      for (final doc in offersSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().trim().toLowerCase();
        final paymentStatus =
            data['paymentStatus']?.toString().trim().toLowerCase();

        print(
            'getAllDebtsWithDueInfoForceRefresh - Oferta ${doc.id}: status=$status, paymentStatus=$paymentStatus');

        // Solo considerar servicios completados que no han sido pagados
        if (status == 'completed' && paymentStatus != 'pagado') {
          print('✅ Agregando deuda: ${doc.id} - paymentStatus: $paymentStatus');
          final commission = (data['commission'] ?? 0.0) as num;
          final extraCosts = (data['extraCosts'] ?? 0.0) as num;
          final serviceId = data['serviceId'] ?? 'Sin ID';
          final debtAmount = commission + extraCosts;

          final createdAt = _parseCreatedAt(data['createdAt']);
          final dueDate = _calculateDueDate(createdAt);
          final daysUntilDue = _calculateDaysUntilDue(dueDate);
          final isOverdue = daysUntilDue < 0;
          final isWarning = daysUntilDue <= 1 && daysUntilDue >= 0;

          // NUEVA LÓGICA: Determinar si debe bloquear basado en paymentStatus Y tiempo
          final shouldBlockByStatus = paymentStatus == 'debe';
          final shouldBlockByTime = isOverdue && shouldBlockByStatus;
          final shouldShowWarning = shouldBlockByStatus && !isOverdue;

          debts.add({
            'id': doc.id,
            'serviceId': serviceId,
            'commission': commission,
            'extraCosts': extraCosts,
            'total': debtAmount,
            'createdAt': createdAt,
            'dueDate': dueDate,
            'daysUntilDue': daysUntilDue,
            'isOverdue': isOverdue,
            'isWarning': isWarning,
            'paymentStatus': paymentStatus,
            'shouldBlockByStatus': shouldBlockByStatus,
            'shouldBlockByTime': shouldBlockByTime,
            'shouldShowWarning': shouldShowWarning,
            'formattedCreatedAt':
                DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
            'formattedDueDate': DateFormat('dd/MM/yyyy HH:mm').format(dueDate),
          });
        } else {
          print(
              '❌ Excluyendo oferta: ${doc.id} - status: $status, paymentStatus: $paymentStatus');
        }
      }

      print(
          'getAllDebtsWithDueInfoForceRefresh - Total de deudas encontradas: ${debts.length}');

      // Ordenar por fecha de vencimiento (más próximas primero)
      debts.sort((a, b) =>
          (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

      return debts;
    } catch (e) {
      print(
          'Error obteniendo deudas con información de vencimiento (force refresh): $e');
      return [];
    }
  }

  /// Método para limpiar caché y forzar recarga completa
  Future<void> clearCacheAndRefresh() async {
    try {
      print('clearCacheAndRefresh - Limpiando caché de Firestore...');

      // Limpiar caché de Firestore
      await FirebaseFirestore.instance.clearPersistence();

      print('clearCacheAndRefresh - Caché limpiado, forzando recarga...');

      // Forzar recarga de datos
      await debugFirestoreData();

      print('clearCacheAndRefresh - Recarga completada');
    } catch (e) {
      print('clearCacheAndRefresh - Error: $e');
    }
  }

  /// Verifica si ya se mostró la advertencia hoy
  Future<bool> hasShownWarningToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_debtWarningDateKey);
    if (lastShown == null) return false;
    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return false;
    final now = _boliviaTime;
    return now.year == lastDate.year &&
        now.month == lastDate.month &&
        now.day == lastDate.day;
  }

  /// Marca que la advertencia se mostró hoy
  Future<void> setWarningShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = _boliviaTime;
    await prefs.setString(_debtWarningDateKey, now.toIso8601String());
  }

  /// Dispone los recursos
  void dispose() {
    _timer?.cancel();
    _blockStateController.close();
  }
}
