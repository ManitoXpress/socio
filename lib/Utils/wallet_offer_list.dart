import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletOfferList extends StatelessWidget {
  final List<QueryDocumentSnapshot> offers;
  final String title;
  final List<QueryDocumentSnapshot> allOffers;
  final bool isSelectionMode;
  final Set<String> selectedDebtIds;
  final void Function(String) onToggleDebtSelection;
  final void Function(Map<String, dynamic>) onShowOfferDetails;

  const WalletOfferList({
    Key? key,
    required this.offers,
    required this.title,
    required this.allOffers,
    required this.isSelectionMode,
    required this.selectedDebtIds,
    required this.onToggleDebtSelection,
    required this.onShowOfferDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar solo deudas adeudadas (status completed y paymentStatus debe)
    final filteredOffers = offers.where((offer) {
      final data = offer.data() as Map<String, dynamic>;
      final status = data['status']?.toString().trim().toLowerCase();
      final paymentStatus = data['paymentStatus']?.toString().trim().toLowerCase();
      if (title == 'Adeudado') {
        return status == 'completed' && paymentStatus == 'debe';
      }
      return true;
    }).toList();

    return ListView.builder(
      itemCount: filteredOffers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final offer = filteredOffers[index];
        final offerId = offer.id;
        final commission = offer['commission'] ?? 0.0;
        final extraCosts = offer['extraCosts'] ?? 0.0;
        final offeredPrice = offer['offeredPrice'] ?? 0.0;
        final total = commission + extraCosts;
        final paymentStatus = offer['paymentStatus'] ?? 'Desconocido';
        final serviceId = offer['serviceId'] ?? 'Sin ID';
        final status = offer['status'] ?? 'Desconocido';
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
        final isNew = DateTime.now().difference(createdAt).inMinutes < 10;

        if (title == 'Adeudado') {
          return Card(
            color: isSelectionMode && selectedDebtIds.contains(offerId)
                ? const Color(0xFFFDE8E9)
                : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelectionMode && selectedDebtIds.contains(offerId)
                  ? const BorderSide(color: Color(0xFF84090D), width: 2)
                  : BorderSide.none,
            ),
            elevation: 3,
            child: InkWell(
              onTap: isSelectionMode
                  ? () => onToggleDebtSelection(offerId)
                  : () =>
                      onShowOfferDetails(offer.data() as Map<String, dynamic>),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: isSelectionMode
                        ? Checkbox(
                            value: selectedDebtIds.contains(offerId),
                            onChanged: (value) =>
                                onToggleDebtSelection(offerId),
                            activeColor: const Color(0xFF84090D),
                          )
                        : const CircleAvatar(
                            backgroundColor: Color(0xFF84090D),
                            child: Icon(Icons.warning, color: Colors.white),
                          ),
                    title: Text('Adeudado: \Bs${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Fecha: ${createdAt.toLocal()}',
                        style: const TextStyle(color: Colors.grey)),
                    trailing: isNew
                        ? Chip(
                            label: const Text('Nuevo'),
                            backgroundColor: const Color(0xFFFDE8E9),
                            labelStyle: const TextStyle(
                              color: Color(0xFF84090D),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (!isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Desglose del adeudado:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              'Precio ofertado: \Bs${offeredPrice.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                              '+ Comisión (10%): \Bs${commission.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF84090D))),
                          Text(
                              '+ Costos extras: \Bs${extraCosts.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF84090D))),
                          const Divider(),
                          Text(
                              '= Total que nos debe: \Bs${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF84090D),
                                  fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Detalles adicionales:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Estado del pago: $paymentStatus'),
                          Text('Estado: $status'),
                          Text('Service ID: $serviceId'),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Para pagado, mantener el diseño original
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: paymentStatus == 'pagado'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF84090D),
              child: Icon(
                paymentStatus == 'pagado' ? Icons.check : Icons.warning,
                color: Colors.white,
              ),
            ),
            title: Text('Servicio: $serviceId',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${createdAt.toLocal()}'),
                Row(
                  children: [
                    Chip(
                      label: Text(paymentStatus == 'pagado' ? 'PAGADO' : 'DEBE',
                          style: TextStyle(
                              color: paymentStatus == 'pagado'
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF84090D),
                              fontWeight: FontWeight.bold)),
                      backgroundColor: paymentStatus == 'pagado'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFDE8E9),
                    ),
                    if (isNew)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: const Text('Nuevo'),
                          backgroundColor: const Color(0xFFFDE8E9),
                          labelStyle: const TextStyle(
                            color: Color(0xFF84090D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '\Bs${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: paymentStatus == 'pagado'
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF84090D),
                fontSize: 18,
              ),
            ),
            onTap: () =>
                onShowOfferDetails(offer.data() as Map<String, dynamic>),
          ),
        );
      },
    );
  }
}
