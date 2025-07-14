

import 'package:socio/Utils/debt_blocker_service.dart';

/// Archivo de prueba para verificar la lógica del sistema de bloqueo por deudas
/// Este archivo no se usa en producción, solo para testing

class DebtBlockerTest {
  static final DebtBlockerService _debtService = DebtBlockerService();

  /// Prueba la lógica de bloqueo con diferentes escenarios
  static Future<void> testDebtBlockingLogic() async {
    print('=== PRUEBA DE LÓGICA DE BLOQUEO POR DEUDAS ===');

    try {
      // 1. Verificar si debe bloquear la aplicación
      final shouldBlock = await _debtService.shouldBlockApp();
      print('1. ¿Debe bloquear la aplicación? $shouldBlock');

      // 2. Verificar si debe mostrar advertencia
      final shouldShowWarning = await _debtService.shouldShowDebtWarning();
      print('2. ¿Debe mostrar advertencia? $shouldShowWarning');

      // 3. Obtener todas las deudas con información detallada
      final allDebts = await _debtService.getAllDebtsWithDueInfo();
      print('3. Total de deudas encontradas: ${allDebts.length}');

      // 4. Mostrar detalles de cada deuda
      for (int i = 0; i < allDebts.length; i++) {
        final debt = allDebts[i];
        print('\n--- Deuda ${i + 1} ---');
        print('  Service ID: ${debt['serviceId']}');
        print('  Payment Status: ${debt['paymentStatus']}');
        print('  Created At: ${debt['formattedCreatedAt']}');
        print('  Due Date: ${debt['formattedDueDate']}');
        print('  Days Until Due: ${debt['daysUntilDue']}');
        print('  Is Overdue: ${debt['isOverdue']}');
        print('  Should Block By Status: ${debt['shouldBlockByStatus']}');
        print('  Should Block By Time: ${debt['shouldBlockByTime']}');
        print('  Should Show Warning: ${debt['shouldShowWarning']}');
        print('  Total Amount: Bs ${debt['total']}');
      }

      // 5. Obtener deudas que bloquean
      final overdueDebts = await _debtService.getOverdueDebts();
      print('\n4. Deudas que bloquean la aplicación: ${overdueDebts.length}');

      // 6. Calcular totales
      final totalDebt = await _debtService.getTotalDebt();
      final totalOverdueDebt = await _debtService.getTotalOverdueDebt();
      print('\n5. Total de deudas: Bs $totalDebt');
      print('6. Total de deudas que bloquean: Bs $totalOverdueDebt');

      // 7. Obtener días hasta próximo vencimiento
      final daysUntilNextDue = await _debtService.getDaysUntilNextDue();
      print('7. Días hasta próximo vencimiento: $daysUntilNextDue');

      print('\n=== FIN DE PRUEBA ===');
    } catch (e) {
      print('Error en la prueba: $e');
    }
  }

  /// Prueba específica para verificar la lógica de paymentStatus
  static Future<void> testPaymentStatusLogic() async {
    print('\n=== PRUEBA DE LÓGICA DE PAYMENT STATUS ===');

    try {
      final allDebts = await _debtService.getAllDebtsWithDueInfo();

      // Agrupar por paymentStatus
      final debtsByStatus = <String, List<Map<String, dynamic>>>{};

      for (final debt in allDebts) {
        final status = debt['paymentStatus'] as String;
        debtsByStatus.putIfAbsent(status, () => []).add(debt);
      }

      print('Deudas agrupadas por paymentStatus:');
      debtsByStatus.forEach((status, debts) {
        print('\n--- PaymentStatus: "$status" (${debts.length} deudas) ---');

        for (final debt in debts) {
          final isOverdue = debt['isOverdue'] as bool;
          final shouldBlockByTime = debt['shouldBlockByTime'] as bool;
          final shouldShowWarning = debt['shouldShowWarning'] as bool;

          print('  Service: ${debt['serviceId']}');
          print('    - Is Overdue: $isOverdue');
          print('    - Should Block By Time: $shouldBlockByTime');
          print('    - Should Show Warning: $shouldShowWarning');
          print('    - Days Until Due: ${debt['daysUntilDue']}');
        }
      });

      print('\n=== FIN DE PRUEBA DE PAYMENT STATUS ===');
    } catch (e) {
      print('Error en la prueba de payment status: $e');
    }
  }

  /// Prueba para verificar la lógica de tiempo
  static Future<void> testTimeLogic() async {
    print('\n=== PRUEBA DE LÓGICA DE TIEMPO ===');

    try {
      final allDebts = await _debtService.getAllDebtsWithDueInfo();

      // Agrupar por estado de tiempo
      final overdueDebts =
          allDebts.where((d) => d['isOverdue'] == true).toList();
      final notOverdueDebts =
          allDebts.where((d) => d['isOverdue'] == false).toList();

      print('Deudas vencidas (isOverdue = true): ${overdueDebts.length}');
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

      print('\n=== FIN DE PRUEBA DE TIEMPO ===');
    } catch (e) {
      print('Error en la prueba de tiempo: $e');
    }
  }

  /// Ejecuta todas las pruebas
  static Future<void> runAllTests() async {
    await testDebtBlockingLogic();
    await testPaymentStatusLogic();
    await testTimeLogic();
  }
}
