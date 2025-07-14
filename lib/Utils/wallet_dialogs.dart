import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WalletDialogs {
  static void showDebtSummaryDialog(BuildContext context,
      Set<String> selectedDebtIds, List<QueryDocumentSnapshot> allOffers) {
    // Implementar la lógica del diálogo de resumen de deudas aquí
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de Pagos'),
        content: const Text('Aquí va el resumen de deudas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  static Widget buildOfferDetailsDialog(
      BuildContext context, Map<String, dynamic> offer) {
    final commission = offer['commission'] ?? 0.0;
    final extraCosts = offer['extraCosts'] ?? 0.0;
    final total = commission + extraCosts;
    final serviceId = offer['serviceId'] ?? 'No disponible';
    final completionImageUrl = offer['completionImageUrl'] ?? '';
    final paymentStatus = offer['paymentStatus'] ?? 'Desconocido';
    final createdAtData = offer['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      createdAt = DateTime.now();
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalles de la oferta',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Comisión: \Bs${commission.toStringAsFixed(2)}'),
              Text('Costos extras: \Bs${extraCosts.toStringAsFixed(2)}'),
              Text('Total: \Bs${total.toStringAsFixed(2)}'),
              Text('Service ID: $serviceId'),
              Text('Estado del pago: $paymentStatus'),
              Text('Fecha: ${createdAt.toLocal()}'),
              const SizedBox(height: 16),
              if (completionImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    completionImageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildIncomeDetailsDialog(
      BuildContext context, Map<String, dynamic> service) {
    final commission = service['commission'] ?? 0.0;
    final offeredPrice = service['offeredPrice'] ?? 0.0;
    final netIncome = offeredPrice - commission;
    final serviceId = service['serviceId'] ?? 'No disponible';
    final status = service['status'] ?? 'Desconocido';
    final createdAtData = service['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      createdAt = DateTime.now();
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.attach_money,
                      color: Color(0xFF4CAF50), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Ingreso',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF84090D),
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Ingreso Neto', 'Bs${netIncome.toStringAsFixed(2)}',
                const Color(0xFF4CAF50)),
            _buildDetailRow('Precio Ofertado',
                'Bs${offeredPrice.toStringAsFixed(2)}', Colors.black87),
            _buildDetailRow('Comisión (10%)',
                'Bs${commission.toStringAsFixed(2)}', Colors.red),
            const Divider(),
            _buildDetailRow('Servicio ID', serviceId, Colors.black87),
            _buildDetailRow('Estado', status, Colors.blue),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84090D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
