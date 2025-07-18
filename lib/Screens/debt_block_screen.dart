import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:url_launcher/url_launcher.dart';


import '../Utils/debt_blocker_service.dart';
import '../Utils/styles.dart';
import 'debt_warning_screen.dart';

class DebtBlockScreen extends StatefulWidget {
  final double totalDebt;

  const DebtBlockScreen({
    Key? key,
    required this.totalDebt,
  }) : super(key: key);

  @override
  _DebtBlockScreenState createState() => _DebtBlockScreenState();
}

class _DebtBlockScreenState extends State<DebtBlockScreen> {
  final DebtBlockerService _debtService = DebtBlockerService();
  List<Map<String, dynamic>> _overdueDebts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverdueDebts();
  }

  Future<void> _loadOverdueDebts() async {
    try {
      // NUEVA LÓGICA: Cargar deudas que han vencido (3 días + paymentStatus "debe")
      final overdueDebts = await _debtService.getOverdueDebts();
      if (mounted) {
        setState(() {
          _overdueDebts = overdueDebts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando deudas vencidas: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 24.h),

              // Mensaje de advertencia más grande
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Text(
                  'Debes pagar tus deudas vencidas para desbloquear tu cuenta.',
                  style: MyTextStyles.buttonTextStyle.copyWith(
                    fontSize: 20.sp,
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Botón para pagar más grande
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendDebtToWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 22.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 30.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Pagar deudas vencidas',
                        style: MyTextStyles.buttonTextStyle.copyWith(
                          fontSize: 22.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icono de bloqueo
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.block,
            size: 60.w,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 32.h),

        // Título
        Text(
          'Cuenta Bloqueada',
          style: MyTextStyles.buttonTextStyle.copyWith(
            fontSize: 28.sp,
            color: const Color(0xFFD32F2F),
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // Mensaje principal
        Text(
          'Tu cuenta ha sido bloqueada por deudas vencidas',
          style: MyTextStyles.inputTextStyle5.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 24.h),

        // Monto total vencido
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFFD32F2F),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total deudas vencidas:',
                style: MyTextStyles.inputTextStyle5.copyWith(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Bs ${widget.totalDebt.toStringAsFixed(2)}',
                style: MyTextStyles.buttonTextStyle.copyWith(
                  fontSize: 32.sp,
                  color: const Color(0xFFD32F2F),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_overdueDebts.length} servicio${_overdueDebts.length == 1 ? '' : 's'} vencido${_overdueDebts.length == 1 ? '' : 's'}',
                style: MyTextStyles.inputTextStyle5.copyWith(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueDebtsList() {
    return ListView.builder(
      itemCount: _overdueDebts.length,
      itemBuilder: (context, index) {
        return DebtCardWidget(debt: _overdueDebts[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80.w,
            color: Colors.green[400],
          ),
          SizedBox(height: 24.h),
          Text(
            'No hay deudas vencidas',
            style: MyTextStyles.inputTextStyle5.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Todas tus deudas están al día',
            style: MyTextStyles.inputTextStyle5.copyWith(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Column(
      children: [
        // Botón para refrescar datos
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await _loadOverdueDebts();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3), width: 2),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh,
                  color: const Color(0xFF2196F3),
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Refrescar datos',
                  style: MyTextStyles.buttonTextStyle.copyWith(
                    fontSize: 18.sp,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Botón de pagar deudas aún más pequeño
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendDebtToWhatsApp,
            icon: Icon(Icons.payment, size: 18),
            label: Text(
              'Pagar deudas vencidas',
              style: MyTextStyles.buttonTextStyle.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  void _sendDebtToWhatsApp() async {
    try {
      final debtDetails = await _debtService.getOverdueDebtDetailsForWhatsApp();
      final totalAmount = debtDetails['totalAmount'] as double;
      final serviceIds = debtDetails['serviceIds'] as List<String>;

      if (serviceIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay deudas vencidas para pagar.')),
        );
        return;
      }

      const phoneNumber = '+59173666393';
      final message = Uri.encodeFull(
          "Hola, tengo ${serviceIds.length} servicio${serviceIds.length == 1 ? '' : 's'} vencido${serviceIds.length == 1 ? '' : 's'} "
          "por un total de Bs ${totalAmount.toStringAsFixed(2)}. "
          "Necesito el código QR para realizar el pago. "
          "IDs de servicios: ${serviceIds.join(', ')}");

      final whatsappUrl = "https://wa.me/$phoneNumber?text=$message";

      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    } catch (e) {
      print('Error enviando deudas a WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud.')),
      );
    }
  }
}
