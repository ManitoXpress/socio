import 'package:socio/Utils/debt_blocker_service.dart';

/// Archivo de prueba para verificar la lógica del sistema de bloqueo por deudas
/// Este archivo no se usa en producción, solo para testing

class DebtBlockerTest {
  static final DebtBlockerService _debtService = DebtBlockerService();

  /// Prueba la lógica de bloqueo con diferentes escenarios
  static Future<void> testDebtBlockingLogic() async {
    try {
      // 1. Verificar si debe bloquear la aplicación
      final shouldBlock = await _debtService.shouldBlockApp();
      // 2. Verificar si debe mostrar advertencia
      final shouldShowWarning = await _debtService.shouldShowDebtWarning();
      // 3. Obtener todas las deudas con información detallada
      final allDebts = await _debtService.getAllDebtsWithDueInfo();
      // 4. Mostrar detalles de cada deuda
      for (int i = 0; i < allDebts.length; i++) {
        final debt = allDebts[i];
      }

      // 5. Obtener deudas que bloquean
      final overdueDebts = await _debtService.getOverdueDebts();
      // 6. Calcular totales
      final totalDebt = await _debtService.getTotalDebt();
      final totalOverdueDebt = await _debtService.getTotalOverdueDebt();
      // 7. Obtener días hasta próximo vencimiento
      final daysUntilNextDue = await _debtService.getDaysUntilNextDue();
    } catch (e) {
    }
  }

  /// Prueba específica para verificar la lógica de paymentStatus
  static Future<void> testPaymentStatusLogic() async {
    try {
      final allDebts = await _debtService.getAllDebtsWithDueInfo();

      // Agrupar por paymentStatus
      final debtsByStatus = <String, List<Map<String, dynamic>>>{};

      for (final debt in allDebts) {
        final status = debt['paymentStatus'] as String;
        debtsByStatus.putIfAbsent(status, () => []).add(debt);
      }
      debtsByStatus.forEach((status, debts) {
        for (final debt in debts) {
          final isOverdue = debt['isOverdue'] as bool;
          final shouldBlockByTime = debt['shouldBlockByTime'] as bool;
          final shouldShowWarning = debt['shouldShowWarning'] as bool;
        }
      });
    } catch (e) {
    }
  }

  /// Prueba para verificar la lógica de tiempo
  static Future<void> testTimeLogic() async {
    try {
      final allDebts = await _debtService.getAllDebtsWithDueInfo();

      // Agrupar por estado de tiempo
      final overdueDebts =
          allDebts.where((d) => d['isOverdue'] == true).toList();
      final notOverdueDebts =
          allDebts.where((d) => d['isOverdue'] == false).toList();
      for (final debt in overdueDebts) {
        print(
            '  - ${debt['serviceId']}: ${debt['daysUntilDue']} días de retraso, paymentStatus: ${debt['paymentStatus']}');
      }

      print(
          '\nDeudas no vencidas (isOverdue = false): ${notOverdueDebts.length}');
      for (final debt in notOverdueDebts) {
        print(
            '  - ${debt['serviceId']}: vence en ${debt['daysUntilDue']} días, paymentStatus: ${debt['paymentStatus']}');
      }
    } catch (e) {
    }
  }

  /// Ejecuta todas las pruebas
  static Future<void> runAllTests() async {
    await testDebtBlockingLogic();
    await testPaymentStatusLogic();
    await testTimeLogic();
  }
}
