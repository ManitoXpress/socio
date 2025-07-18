import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletDialogs {
  static void showDebtSummaryDialog(BuildContext context,
      Set<String> selectedDebtIds, List<QueryDocumentSnapshot> allOffers) {
    final selectedDebts = allOffers.where((offer) => selectedDebtIds.contains(offer.id)).toList();
    double totalCommission = 0.0;
    double totalExtraCosts = 0.0;
    double totalAmount = 0.0;
    final serviceIds = <String>[];
    for (final debt in selectedDebts) {
      final data = debt.data() as Map<String, dynamic>;
      final commission = (data['commission'] ?? 0.0) as num;
      final extraCosts = (data['extraCosts'] ?? 0.0) as num;
      totalCommission += commission;
      totalExtraCosts += extraCosts;
      totalAmount += commission + extraCosts;
      serviceIds.add(data['serviceId']?.toString() ?? 'Sin ID');
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF84090D).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.payments, color: Color(0xFF84090D), size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Resumen de Pago',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Color(0xFF84090D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Detalle de deudas seleccionadas:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedDebts.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, idx) {
                          final data = selectedDebts[idx].data() as Map<String, dynamic>;
                          final serviceId = data['serviceId'] ?? 'Sin ID';
                          final commission = (data['commission'] ?? 0.0) as num;
                          final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                          final total = commission + extraCosts;
                          final createdAtData = data['createdAt'];
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
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF84090D).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long, color: Color(0xFF84090D), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Servicio: $serviceId', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(createdAt)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    Row(
                                      children: [
                                        Text('Comisión: ', style: TextStyle(color: Colors.black87)),
                                        Text('Bs${commission.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF84090D), fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Text('Extras: ', style: TextStyle(color: Colors.black87)),
                                        Text('Bs${extraCosts.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF84090D), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Text('Total: Bs${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(thickness: 1.2, color: Colors.grey[300]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total comisión:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Bs${totalCommission.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF84090D))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total extras:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Bs${totalExtraCosts.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF84090D))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Bs${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50), fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final phoneNumber = '+59173666393';
                              final serviceIdsText = serviceIds.join(', ');
                              final debtDetailsText = selectedDebts
                                  .map((debt) {
                                    final data = debt.data() as Map<String, dynamic>;
                                    final serviceId = data['serviceId'] ?? 'Sin ID';
                                    final commission = (data['commission'] ?? 0.0) as num;
                                    final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                                    final total = commission + extraCosts;
                                    return 'Servicio: $serviceId\n  Comisión: Bs${commission.toStringAsFixed(2)}\n  Extras: Bs${extraCosts.toStringAsFixed(2)}\n  Total: Bs${total.toStringAsFixed(2)}';
                                  })
                                  .join('\n\n');
                              final message = Uri.encodeFull(
                                "Hola, quisiera solicitar el código QR para realizar el pago de mis deudas.\n\n" +
                                "Resumen de pago:\n" +
                                "-----------------------------\n" +
                                "$debtDetailsText\n" +
                                "-----------------------------\n" +
                                "Total comisión: Bs${totalCommission.toStringAsFixed(2)}\n" +
                                "Total extras: Bs${totalExtraCosts.toStringAsFixed(2)}\n" +
                                "Total a pagar: Bs${totalAmount.toStringAsFixed(2)}\n\n" +
                                "Por favor, envíame el código QR para hacer el pago."
                              );
                              final whatsappUrl = "https://wa.me/$phoneNumber?text=$message";
                              if (await canLaunch(whatsappUrl)) {
                                await launch(whatsappUrl);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                            label: const Text('Pagar por WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
