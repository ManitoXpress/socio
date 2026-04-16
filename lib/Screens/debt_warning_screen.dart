import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/Utils/debt_blocker_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DebtWarningScreen extends StatefulWidget {
  final double totalDebt;
  final int daysRemaining;

  const DebtWarningScreen({
    Key? key,
    required this.totalDebt,
    required this.daysRemaining,
  }) : super(key: key);

  @override
  _DebtWarningScreenState createState() => _DebtWarningScreenState();
}

class _DebtWarningScreenState extends State<DebtWarningScreen> {
  final DebtBlockerService _debtService = DebtBlockerService();
  List<Map<String, dynamic>> _warningDebts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWarningDebts();
  }

  Future<void> _loadWarningDebts() async {
    try {
      final allDebts = await _debtService.getAllDebtsWithDueInfo();
      // NUEVA LÓGICA: Mostrar deudas con paymentStatus "debe" pero que no han vencido
      final warningDebts =
          allDebts.where((debt) => debt['shouldShowWarning'] == true).toList();

      if (mounted) {
        setState(() {
          _warningDebts = warningDebts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 100.h),

              // Botón para pagar más grande
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendDebtToWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: Colors.white, size: 24.w),
                      SizedBox(width: 10.w),
                      Text('Pagar deudas',
                          style: MyTextStyles.buttonTextStyle
                              .copyWith(fontSize: 18.sp, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              // Botón ver deudas pendientes restaurado
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showAllDebtsModal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[900],
                    side: BorderSide(color: Colors.orange[900]!, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    textStyle:
                        MyTextStyles.buttonTextStyle.copyWith(fontSize: 18),
                  ),
                  child: Text('Ver deudas pendientes',
                      style: MyTextStyles.buttonTextStyle
                          .copyWith(fontSize: 18, color: Colors.orange[900])),
                ),
              ),
              SizedBox(height: 14.h),
              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[900],
                    side: BorderSide(color: Colors.orange[900]!, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    textStyle:
                        MyTextStyles.buttonTextStyle.copyWith(fontSize: 18),
                  ),
                  child: Text('Continuar',
                      style: MyTextStyles.buttonTextStyle
                          .copyWith(fontSize: 18, color: Colors.orange[900])),
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
        // Icono de advertencia
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: Colors.orange[200],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 50.w,
            color: Colors.orange[800],
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          '¡Atención!',
          style: MyTextStyles.buttonTextStyle.copyWith(
            fontSize: 26.sp,
            color: Colors.orange[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Tienes deudas próximas a vencer',
          style: MyTextStyles.inputTextStyle5.copyWith(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 18.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Colors.orange[400]!,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange[700],
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Tienes ${widget.daysRemaining} día${widget.daysRemaining == 1 ? '' : 's'} para pagar',
                style: MyTextStyles.inputTextStyle5.copyWith(
                  fontSize: 15.sp,
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 50.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 0),
          child: Text(
            'Si no realizas el pago en el plazo establecido, tu cuenta será bloqueada hasta que saldes tus deudas vencidas.',
            style: MyTextStyles.inputTextStyle5.copyWith(
              fontSize: 16.sp,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningDebtsList() {
    return ListView.builder(
      itemCount: _warningDebts.length,
      itemBuilder: (context, index) {
        return DebtCardWidget(debt: _warningDebts[index]);
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
            'No hay deudas próximas a vencer',
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

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Botón para refrescar datos
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await _loadWarningDebts();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3), width: 1.2),
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: MyTextStyles.buttonTextStyle.copyWith(fontSize: 15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: const Color(0xFF2196F3), size: 20),
                SizedBox(width: 6),
                Text('Refrescar datos',
                    style: MyTextStyles.buttonTextStyle.copyWith(
                        fontSize: 15, color: const Color(0xFF2196F3))),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        // Botón para pagar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sendDebtToWhatsApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              textStyle: MyTextStyles.buttonTextStyle.copyWith(fontSize: 15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text('Pagar deudas',
                    style: MyTextStyles.buttonTextStyle
                        .copyWith(fontSize: 15, color: Colors.white)),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        // Botón ver deudas pendientes
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showAllDebtsModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[900],
              side: BorderSide(color: Colors.orange[900]!, width: 1.2),
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: MyTextStyles.buttonTextStyle.copyWith(fontSize: 15),
            ),
            child: Text('Ver deudas pendientes',
                style: MyTextStyles.buttonTextStyle
                    .copyWith(fontSize: 15, color: Colors.orange[900])),
          ),
        ),
        SizedBox(height: 10),
        // Botón continuar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[900],
              side: BorderSide(color: Colors.orange[900]!, width: 1.2),
              padding: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: MyTextStyles.buttonTextStyle.copyWith(fontSize: 15),
            ),
            child: Text('Continuar',
                style: MyTextStyles.buttonTextStyle
                    .copyWith(fontSize: 15, color: Colors.orange[900])),
          ),
        ),
      ],
    );
  }

  void _sendDebtToWhatsApp() async {
    try {
      final debtDetails = await _debtService.getWarningDebtDetailsForWhatsApp();
      final totalAmount = debtDetails['totalAmount'] as double;
      final serviceIds = debtDetails['serviceIds'] as List<String>;

      if (serviceIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay deudas para pagar.')),
        );
        return;
      }

      const phoneNumber = '+59173666393';
      final message = Uri.encodeFull(
          "Hola, tengo ${serviceIds.length} servicio${serviceIds.length == 1 ? '' : 's'} próximo${serviceIds.length == 1 ? '' : 's'} a vencer "
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud.')),
      );
    }
  }

  void _showAllDebtsModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _AllDebtsSheet(scrollController: scrollController);
        },
      ),
    );
  }
}

class DebtCardWidget extends StatelessWidget {
  final Map<String, dynamic> debt;
  const DebtCardWidget({Key? key, required this.debt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dueDate = debt['dueDate'] as DateTime;
    final paymentStatus = debt['paymentStatus'] as String;
    final now = DateTime.now().toUtc().add(const Duration(hours: 4));
    final difference = dueDate.difference(now);
    final daysDiff = difference.inDays;

    Color borderColor;
    Color labelColor;
    Color backgroundColor;
    String estadoLabel;
    if (now.isBefore(dueDate) && daysDiff > 1) {
      borderColor = Colors.green;
      labelColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.05);
      estadoLabel = 'EN TIEMPO';
    } else if (now.isBefore(dueDate) && daysDiff <= 1) {
      borderColor = Colors.amber;
      labelColor = Colors.amber[800]!;
      backgroundColor = Colors.amber.withOpacity(0.08);
      estadoLabel = 'POR VENCER';
    } else {
      borderColor = Colors.red;
      labelColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.05);
      estadoLabel = 'VENCIDO';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Servicio: ${debt['serviceId']}',
                  style: MyTextStyles.inputTextStyle5.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estadoLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Estado: ${paymentStatus.toUpperCase()}',
              style: MyTextStyles.inputTextStyle5.copyWith(
                fontSize: 12,
                color: labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completado:',
                        style: MyTextStyles.inputTextStyle5
                            .copyWith(fontSize: 12, color: Colors.grey[600])),
                    Text(debt['formattedCreatedAt'],
                        style: MyTextStyles.inputTextStyle5.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vencimiento:',
                        style: MyTextStyles.inputTextStyle5
                            .copyWith(fontSize: 12, color: Colors.grey[600])),
                    Text(debt['formattedDueDate'],
                        style: MyTextStyles.inputTextStyle5.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: borderColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (now.isAfter(dueDate))
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${now.difference(dueDate).inDays} día${now.difference(dueDate).inDays == 1 ? '' : 's'} de retraso',
                style: MyTextStyles.inputTextStyle5.copyWith(
                  fontSize: 13,
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vence en $daysDiff día${daysDiff == 1 ? '' : 's'}',
                style: MyTextStyles.inputTextStyle5.copyWith(
                  fontSize: 13,
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comisión:',
                        style: MyTextStyles.inputTextStyle5
                            .copyWith(fontSize: 12, color: Colors.grey[600])),
                    Text('Bs ${(debt['commission'] as num).toStringAsFixed(2)}',
                        style: MyTextStyles.inputTextStyle5.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Costos extras:',
                        style: MyTextStyles.inputTextStyle5
                            .copyWith(fontSize: 12, color: Colors.grey[600])),
                    Text('Bs ${(debt['extraCosts'] as num).toStringAsFixed(2)}',
                        style: MyTextStyles.inputTextStyle5.copyWith(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total de esta deuda:',
                    style: MyTextStyles.inputTextStyle5
                        .copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Bs ${(debt['total'] as double).toStringAsFixed(2)}',
                    style: MyTextStyles.inputTextStyle5.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: borderColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar todas las deudas en el modal
class _AllDebtsSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _AllDebtsSheet({required this.scrollController});

  @override
  State<_AllDebtsSheet> createState() => _AllDebtsSheetState();
}

class _AllDebtsSheetState extends State<_AllDebtsSheet> {
  final DebtBlockerService _debtService = DebtBlockerService();
  List<Map<String, dynamic>> _allDebts = [];
  bool _isLoading = true;
  Set<String> _selectedDebtIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllDebts();
  }

  Future<void> _loadAllDebts() async {
    try {
      final debts = await _debtService.getAllDebtsWithDueInfo();
      if (mounted) {
        setState(() {
          _allDebts = debts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _selectedTotal {
    return _allDebts
        .where((debt) => _selectedDebtIds.contains(debt['id'] as String))
        .fold(0.0, (sum, debt) => sum + (debt['total'] as double));
  }

  void _toggleDebtSelection(String debtId) {
    setState(() {
      if (_selectedDebtIds.contains(debtId)) {
        _selectedDebtIds.remove(debtId);
      } else {
        _selectedDebtIds.add(debtId);
      }
    });
  }

  void _paySelectedDebts() async {
    final selectedDebts = _allDebts
        .where((debt) => _selectedDebtIds.contains(debt['id'] as String))
        .toList();
    if (selectedDebts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una deuda.')),
      );
      return;
    }
    final totalAmount =
        selectedDebts.fold(0.0, (sum, debt) => sum + (debt['total'] as double));
    final serviceIds =
        selectedDebts.map((debt) => debt['serviceId'] as String).toList();
    const phoneNumber = '+59173666393';
    final message = Uri.encodeFull(
        "Hola, quiero pagar ${serviceIds.length} deuda${serviceIds.length == 1 ? '' : 's'} por un total de Bs ${totalAmount.toStringAsFixed(2)}. "
        "IDs de servicios: ${serviceIds.join(', ')}");
    final whatsappUrl = "https://wa.me/$phoneNumber?text=$message";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Todas tus deudas',
                style: MyTextStyles.buttonTextStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              if (_selectedDebtIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionadas: ${_selectedDebtIds.length}',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: Bs ${_selectedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allDebts.isEmpty
                        ? Center(
                            child: Text('No tienes deudas pendientes.',
                                style: TextStyle(fontSize: 16)),
                          )
                        : ListView.builder(
                            controller: widget.scrollController,
                            itemCount: _allDebts.length,
                            itemBuilder: (context, index) {
                              final debt = _allDebts[index];
                              final debtId = debt['id'] as String;
                              return InkWell(
                                onTap: () => _toggleDebtSelection(debtId),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _selectedDebtIds.contains(debtId),
                                      onChanged: (_) =>
                                          _toggleDebtSelection(debtId),
                                      activeColor: Colors.orange[900],
                                    ),
                                    Expanded(child: DebtCardWidget(debt: debt)),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              if (_selectedDebtIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _paySelectedDebts,
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text('Pagar deudas seleccionadas',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
