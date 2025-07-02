import 'package:flutter/material.dart';
import 'package:socio/models/serviceRequest_models.dart';

class FinancialBreakdownSection extends StatelessWidget {
  final String workerId;
  final double? workerOfferedPrice;
  final ServiceRequestModel serviceData;

  const FinancialBreakdownSection({
    Key? key,
    required this.workerId,
    required this.workerOfferedPrice,
    required this.serviceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? offeredPrice;
    if (workerOfferedPrice != null) {
      offeredPrice = workerOfferedPrice;
    } else {
      final workerOffer = serviceData.rawOffers.firstWhere(
        (offer) => offer['workerId'] == workerId,
        orElse: () => <String, dynamic>{},
      );
      if (workerOffer.isNotEmpty) {
        final raw = workerOffer['offeredPrice'];
        offeredPrice =
            (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
      }
    }
    if (offeredPrice == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E9),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF84090D), width: 2.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF84090D)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Información financiera no disponible para este servicio',
                style: TextStyle(
                  color: Color(0xFF84090D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final commission = offeredPrice * 0.10;
    const extraCosts = 3.0;
    final totalClientPays = offeredPrice + extraCosts;
    final netIncome = offeredPrice - commission;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF84090D), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF84090D).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF84090D),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN FINANCIERO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Servicio completado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border:
                  Border.all(color: const Color(0xFF84090D).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Precio ofertado:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\Bs${offeredPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '+ Costos extras:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '+\Bs${extraCosts.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total cliente paga:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\Bs${totalClientPays.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF84090D), thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comisión (10%):',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '-\Bs${commission.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INGRESO NETO:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                    Text(
                      '\Bs${netIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF84090D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border:
                  Border.all(color: const Color(0xFF84090D).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF84090D),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El cliente paga Bs${totalClientPays.toStringAsFixed(2)} (precio + extras). Tu ingreso neto es Bs${netIncome.toStringAsFixed(2)} (precio - comisión).',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF84090D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
