import 'package:flutter/material.dart';
import 'package:socio/Screens/debt_block_screen.dart';
import 'package:socio/Screens/debt_warning_screen.dart';
import 'package:socio/Utils/debt_blocker_service.dart';


class DebtBlockerWrapper extends StatefulWidget {
  final Widget child;
  final bool isGuest;

  const DebtBlockerWrapper({
    Key? key,
    required this.child,
    this.isGuest = false,
  }) : super(key: key);

  @override
  _DebtBlockerWrapperState createState() => _DebtBlockerWrapperState();
}

class _DebtBlockerWrapperState extends State<DebtBlockerWrapper> {
  final DebtBlockerService _debtService = DebtBlockerService();
  bool _isBlockedByDebt = false;
  double _totalOverdueDebt = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _initializeDebtMonitoring();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _initializeDebtMonitoring() async {
    try {
      print('Iniciando monitoreo de deudas vencidas...');

      // Debug: Verificar datos de Firestore
      await _debtService.debugFirestoreData();

      // Debug: Opción para limpiar caché (comentar en producción)
      // await _debtService.clearCacheAndRefresh();

      // Verificar si debe bloquear la aplicación por deudas vencidas
      final shouldBlock = await _debtService.shouldBlockApp();
      print(
          '¿Debe bloquear por deudas vencidas (3 días + paymentStatus "debe")? $shouldBlock');

      if (shouldBlock && mounted) {
        print('Bloqueando aplicación por deudas vencidas...');
        final totalOverdueDebt = await _debtService.getTotalOverdueDebt();
        setState(() {
          _isBlockedByDebt = true;
          _totalOverdueDebt = totalOverdueDebt;
          _isLoading = false;
        });
        return;
      }

      // Verificar si debe mostrar advertencia de deuda próxima a vencer
      final shouldShowWarning = await _debtService.shouldShowDebtWarning();
      final hasShownToday = await _debtService.hasShownWarningToday();
      print(
          '¿Debe mostrar advertencia (paymentStatus "debe" pero no vencidas)? $shouldShowWarning, ¿Ya se mostró hoy? $hasShownToday');

      if (shouldShowWarning && !hasShownToday && mounted) {
        print('Mostrando advertencia de deuda próxima a vencer...');
        final daysUntilNextDue = await _debtService.getDaysUntilNextDue();
        print('Días hasta próximo vencimiento: $daysUntilNextDue');
        _showDebtWarning(daysUntilNextDue);
        await _debtService.setWarningShownToday();
      }

      // Iniciar monitoreo continuo cada 5 minutos
      _debtService.startDebtMonitoring();
      _debtService.blockStateStream.listen((isBlocked) {
        print('Stream de bloqueo: $isBlocked');
        if (mounted) {
          setState(() {
            _isBlockedByDebt = isBlocked;
          });
          if (isBlocked) {
            print('Bloqueando desde stream...');
            _checkAndShowBlockScreen();
          }
        }
      });

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error inicializando monitoreo de deudas: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDebtWarning(int daysUntilNextDue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DebtWarningScreen(
        totalDebt: 0.0, // No usamos este valor en la nueva lógica
        daysRemaining: daysUntilNextDue,
      ),
    );
  }

  void _checkAndShowBlockScreen() async {
    try {
      final totalOverdueDebt = await _debtService.getTotalOverdueDebt();
      if (mounted && totalOverdueDebt > 0) {
        setState(() {
          _totalOverdueDebt = totalOverdueDebt;
        });
      }
    } catch (e) {
      print('Error verificando bloqueo: $e');
    }
  }

  @override
  void dispose() {
    _debtService.stopDebtMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isBlockedByDebt) {
      return DebtBlockScreen(totalDebt: _totalOverdueDebt);
    }

    return widget.child;
  }
}
