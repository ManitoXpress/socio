import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends StatefulWidget {
  WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot> _getOffers() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null
        ? const Stream.empty()
        : FirebaseFirestore.instance
            .collection('offers')
            .where('workerId', isEqualTo: user.uid)
            .snapshots();
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '+59165884846';
    final message = Uri.encodeFull(
        "Hola, quisiera solicitar el código QR para realizar el pago de mis servicios pendientes.");
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
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Movimientos',
                style: TextStyle(fontWeight: FontWeight.w600)),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Adeudado'),
                Tab(text: 'Ingresos'),
                Tab(text: 'Pagado'),
              ],
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _getOffers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar los datos.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay movimientos registrados.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              }

              final offers = snapshot.data!.docs;
              final adeudado = offers
                  .where((doc) =>
                      (doc.data() as Map<String, dynamic>)['paymentStatus'] ==
                      'debe')
                  .toList();
              final pagado = offers
                  .where((doc) =>
                      (doc.data() as Map<String, dynamic>)['paymentStatus'] ==
                      'pagado')
                  .toList();
              final ingresos = offers
                  .where((doc) =>
                      (doc.data() as Map<String, dynamic>)['paymentStatus'] !=
                      'debe')
                  .map((doc) =>
                      (doc.data() as Map<String, dynamic>)['offeredPrice'] ??
                      0.0)
                  .map((price) => price is double
                      ? price
                      : double.tryParse(price.toString()) ?? 0.0)
                  .toList();

              return TabBarView(
                children: [
                  _buildFilteredOfferList(context, adeudado, 'Adeudado'),
                  _buildFilteredIncomeList(context, ingresos, offers),
                  _buildFilteredOfferList(context, pagado, 'Pagado'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredOfferList(
      BuildContext context, List<QueryDocumentSnapshot> offers, String title) {
    final filteredOffers = offers
        .where((doc) => (doc.data() as Map<String, dynamic>)['serviceId']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: filteredOffers.isEmpty
              ? Center(
                  child: Text(
                    'No hay $title registrados.',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : _buildOfferList(context, filteredOffers, title),
        ),
      ],
    );
  }

  Widget _buildFilteredIncomeList(BuildContext context, List<double> ingresos,
      List<QueryDocumentSnapshot> services) {
    final filtereServices = services
        .where((doc) => (doc.data() as Map<String, dynamic>)['serviceId']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: _buildIncomeList(context, ingresos, filtereServices),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Buscar por Service ID',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildOfferList(
      BuildContext context, List<QueryDocumentSnapshot> offers, String title) {
    return ListView.builder(
      itemCount: offers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final offer = offers[index].data() as Map<String, dynamic>;
        final commission = offer['commission'] ?? 0.0;
        final extraCosts = offer['extraCosts'] ?? 0.0;
        final total = commission + extraCosts;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.monetization_on, color: Colors.white),
            ),
            title: Text(
              'Comisión: \$${commission.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Costos extras: \$${extraCosts.toStringAsFixed(2)}'),
            trailing: Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () => _showOfferDetails(context, offer),
          ),
        );
      },
    );
  }

  Widget _buildIncomeList(
    BuildContext context, List<double> ingresos, List<QueryDocumentSnapshot> services) {
  // Filtrar los servicios según el campo `serviceId` y el término de búsqueda
  final filteredServices = services
      .where((doc) => (doc.data() as Map<String, dynamic>)['serviceId']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()))
      .toList();

  return ListView.builder(
    itemCount: filteredServices.length,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemBuilder: (context, index) {
      final income = ingresos.isNotEmpty && index < ingresos.length
          ? ingresos[index]
          : 0.0; // Evitar errores si ingresos tiene menos elementos
      final service = filteredServices[index].data() as Map<String, dynamic>;

      // Extraer los campos necesarios del servicio
      final commission = service['commission'] ?? 0.0;
      final extraCosts = service['extraCosts'] ?? 0.0;
      final offeredPrice = service['offeredPrice'] ?? 0.0;
      final totalPrice = service['totalPrice'] ?? 0.0;
      final serviceId = service['serviceId'] ?? 'Sin ID';
      final paymentStatus = service['paymentStatus'] ?? 'Desconocido';
      final status = service['status'] ?? 'Desconocido';
      final createdAt =
          (service['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final completionImageUrl = service['completionImageUrl'] ?? '';

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: const Icon(Icons.attach_money, color: Colors.white),
              ),
              title: Text(
                'Ingreso: \$${offeredPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Fecha: ${createdAt.toLocal()}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles del servicio:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Comisión: \$${commission.toStringAsFixed(2)}'),
                  Text('Costos extras: \$${extraCosts.toStringAsFixed(2)}'),
                  Text('Precio ofertado: \$${offeredPrice.toStringAsFixed(2)}'),
                  Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
                  Text('Estado del pago: $paymentStatus'),
                  Text('Estado: $status'),
                  Text('Service ID: $serviceId'),
                  const SizedBox(height: 8),
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
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}



  void _showOfferDetails(BuildContext context, Map<String, dynamic> offer) {
    final commission = offer['commission'] ?? 0.0;
    final extraCosts = offer['extraCosts'] ?? 0.0;
    final total = commission + extraCosts;
    final serviceId = offer['serviceId'] ?? 'No disponible';
    final completionImageUrl = offer['completionImageUrl'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles de la oferta',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Comisión: \$${commission.toStringAsFixed(2)}'),
                  Text('Costos extras: \$${extraCosts.toStringAsFixed(2)}'),
                  Text('Total: \$${total.toStringAsFixed(2)}'),
                  Text('Service ID: $serviceId'),
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
      },
    );
  }
}
