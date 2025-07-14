import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../Utils/styles.dart';
import '../ServiceResponse/get.dart';
import 'wallet_totals_summary.dart';
import 'wallet_filters.dart';
import 'wallet_offer_list.dart';
import 'wallet_income_list.dart';
import 'wallet_dialogs.dart';
import 'debt_blocker_service.dart';

class WalletScreen extends StatefulWidget {
  WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'todos';
  DateTimeRange? _selectedDateRange;
  bool _showSkeleton = true;

  // Variables para selección múltiple de deudas
  Set<String> _selectedDebtIds = {};
  bool _isSelectionMode = false;
  List<QueryDocumentSnapshot> _currentOffers = [];

  // Variables para el historial de ingresos
  String _selectedIncomePeriod = '6'; // meses
  Map<String, double> _monthlyIncome = {};
  double _totalIncome = 0.0;
  double _averageIncome = 0.0;
  double _bestMonthIncome = 0.0;
  String _bestMonth = '';

  @override
  void initState() {
    super.initState();
    // Inicializar formato de fechas para español
    initializeDateFormatting('es');
    print('[DEBUG] initState - Starting skeleton loader');
    // Simula skeleton loader por 1s
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        print('[DEBUG] initState - Hiding skeleton loader');
        setState(() => _showSkeleton = false);
      }
    });
  }

  Stream<QuerySnapshot> _getOffers() {
    final user = FirebaseAuth.instance.currentUser;
    print('[DEBUG] _getOffers - User ID: ${user?.uid}');
    print('[DEBUG] _getOffers - User is null: ${user == null}');

    if (user == null) {
      print('[DEBUG] _getOffers - Returning empty stream because user is null');
      return const Stream.empty();
    }

    print('[DEBUG] _getOffers - Using API REST instead of Firestore');

    // Usar API REST en lugar de Firestore para evitar problemas de reglas
    return Stream.fromFuture(_getOffersFromAPI(user.uid)).handleError((error) {
      print('[DEBUG] _getOffers - API Error: $error');
      print('[DEBUG] _getOffers - Error type: ${error.runtimeType}');
      // Retornar stream vacío en caso de error
      return Stream.value(FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: user.uid)
          .limit(0)
          .get());
    });
  }

  Future<QuerySnapshot> _getOffersFromAPI(String workerId) async {
    try {
      final apiService = ApiService2();
      final offers = await apiService.getWorkerOffers(workerId);

      print('[DEBUG] _getOffersFromAPI - Got ${offers.length} offers from API');

      // Si la API funciona, usar Firestore con los datos de la API
      // Esto evita problemas de reglas pero mantiene la compatibilidad
      final firestoreQuery = FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: workerId);

      // Obtener los documentos existentes de Firestore (forzar recarga del servidor)
      final firestoreDocs = await firestoreQuery.get(const GetOptions(source: Source.server));

      print(
          '[DEBUG] _getOffersFromAPI - Firestore returned ${firestoreDocs.docs.length} docs');

      // Si Firestore no tiene datos pero la API sí, usar los datos de la API
      if (firestoreDocs.docs.isEmpty && offers.isNotEmpty) {
        print(
            '[DEBUG] _getOffersFromAPI - Using API data as Firestore is empty');
        // Crear documentos temporales en Firestore con los datos de la API
        final batch = FirebaseFirestore.instance.batch();
        for (final offer in offers) {
          final docRef = FirebaseFirestore.instance.collection('offers').doc();
          batch.set(docRef, offer);
        }
        await batch.commit();

        // Obtener los documentos recién creados (forzar recarga del servidor)
        return await firestoreQuery.get(const GetOptions(source: Source.server));
      }

      return firestoreDocs;
    } catch (e) {
      print('[DEBUG] _getOffersFromAPI - Error: $e');
      // Fallback a Firestore si la API falla (forzar recarga del servidor)
      return FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: workerId)
          .get(const GetOptions(source: Source.server));
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '+59173666393';
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

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // Calcular estadísticas de ingresos mensuales
  void _calculateMonthlyIncome(List<QueryDocumentSnapshot> offers) {
    _monthlyIncome.clear();
    _totalIncome = 0.0;
    _bestMonthIncome = 0.0;
    _bestMonth = '';

    final now = DateTime.now();
    final monthsToShow = int.parse(_selectedIncomePeriod);

    for (int i = 0; i < monthsToShow; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final monthName = DateFormat('MMM yyyy', 'es').format(date);
      _monthlyIncome[monthName] = 0.0;
    }

    // Solo considerar servicios completados
    final completedOffers = offers.where((offer) {
      final status = (offer.data() as Map<String, dynamic>)['status']
          ?.toString()
          .trim()
          .toLowerCase();
      return status == 'completed';
    }).toList();

    for (final offer in completedOffers) {
      final data = offer.data() as Map<String, dynamic>;
      final offeredPrice = (data['offeredPrice'] ?? 0.0) as num;
      final commission = (data['commission'] ?? 0.0) as num;
      final netIncome = offeredPrice - commission;

      final createdAtData = data['createdAt'];
      DateTime createdAt;
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else if (createdAtData is String) {
        createdAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }

      final monthName = DateFormat('MMM yyyy', 'es').format(createdAt);
      if (_monthlyIncome.containsKey(monthName)) {
        _monthlyIncome[monthName] = _monthlyIncome[monthName]! + netIncome;
        _totalIncome += netIncome;
      }
    }

    // Encontrar el mejor mes
    _monthlyIncome.forEach((month, income) {
      if (income > _bestMonthIncome) {
        _bestMonthIncome = income;
        _bestMonth = month;
      }
    });

    _averageIncome = _totalIncome / _monthlyIncome.length;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 0,
            ),
            floatingActionButton: _isSelectionMode
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _selectedDebtIds.isEmpty
                      ? null
                      : () => _showDebtSummaryWithData(
                      _getSelectedDebtDetails(_getCurrentOffers())),
                  label: Text(
                      'Pagar ${_selectedDebtIds.length} deuda${_selectedDebtIds.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  backgroundColor: _selectedDebtIds.isEmpty
                      ? Colors.grey
                      : Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _cancelSelection,
                  child: const Icon(Icons.close, color: Colors.white),
                  backgroundColor: Color(0xFF84090D),
                ),
              ],
            )
                : FloatingActionButton.extended(
              onPressed: _enterSelectionMode,
              label: const Text('Seleccionar deudas',
                  style: TextStyle(
                      color: Color(0xFF84090D), fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.checklist, color: Color(0xFF84090D)),
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF84090D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF84090D), width: 2),
              ),
            ),
            body: Column(
              children: [
                // Resumen de totales (se pasa desde el StreamBuilder)
                StreamBuilder<QuerySnapshot>(
                  stream: _getOffers(),
                  builder: (context, snapshot) {
                    print(
                        '[DEBUG] StreamBuilder - Connection State: ${snapshot.connectionState}');
                    print('[DEBUG] StreamBuilder - Has Data: ${snapshot.hasData}');
                    print(
                        '[DEBUG] StreamBuilder - Has Error: ${snapshot.hasError}');
                    if (snapshot.hasError) {
                      print('[DEBUG] StreamBuilder - Error: ${snapshot.error}');
                      print(
                          '[DEBUG] StreamBuilder - Error type: ${snapshot.error.runtimeType}');
                    }
                    if (snapshot.hasData) {
                      print(
                          '[DEBUG] StreamBuilder - Data docs count: ${snapshot.data!.docs.length}');
                      print(
                          '[DEBUG] StreamBuilder - Data size: ${snapshot.data!.size}');
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print(
                          '[DEBUG] StreamBuilder - No data or empty docs, returning empty summary');
                      return _buildTotalsSummary(
                          adeudado: 0, ingresos: 0, pagado: 0);
                    }
                    final offers = snapshot.data!.docs;
                    print('[DEBUG] Processing ${offers.length} offers');

                    // Log cada documento para verificar acceso a datos
                    for (int i = 0; i < offers.length; i++) {
                      try {
                        final doc = offers[i];
                        final data = doc.data() as Map<String, dynamic>;
                        print('[DEBUG] Doc $i - ID: ${doc.id}');
                        print('[DEBUG] Doc $i - workerId: ${data['workerId']}');
                        print('[DEBUG] Doc $i - status: ${data['status']}');
                        print(
                            '[DEBUG] Doc $i - paymentStatus: ${data['paymentStatus']}');
                        print(
                            '[DEBUG] Doc $i - offeredPrice: ${data['offeredPrice']}');
                        print('[DEBUG] Doc $i - commission: ${data['commission']}');
                      } catch (e) {
                        print('[DEBUG] Doc $i - Error accessing data: $e');
                      }
                    }

                    _currentOffers = offers; // Almacenar las ofertas actuales
                    // Adeudado: suma de comisiones + costos extras de servicios completados y paymentStatus debe (lo que nos deben)
                    final adeudado = offers.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status'] ?? '').toString().trim().toLowerCase();
                      final paymentStatus = (data['paymentStatus'] ?? '').toString().trim().toLowerCase();
                      final commission = (data['commission'] ?? 0.0) as num;
                      final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                      final total = commission + extraCosts;
                      print('[LOG ADEUDADO] id:  ${doc.id} | status: $status | paymentStatus: $paymentStatus | total: $total');
                      return status == 'completed' && paymentStatus == 'debe';
                    }).toList();
                    print('[LOG ADEUDADO] Total documentos adeudados:  ${adeudado.length}');
                    // Pagado: suma de comisiones + costos extras donde paymentStatus == 'pagado'
                    final pagado = offers.where((doc) {
                      final status = (doc.data() as Map<String, dynamic>)['status']
                          ?.toString()
                          .trim()
                          .toLowerCase();
                      final paymentStatus =
                      (doc.data() as Map<String, dynamic>)['paymentStatus']
                          ?.toString()
                          .trim()
                          .toLowerCase();
                      return status == 'completed' && paymentStatus == 'pagado';
                    }).toList();
                    // Ingresos: suma de (offeredPrice - commission) para servicios completados y pagados (nuestro ingreso neto)
                    final ingresos = offers
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status']?.toString().trim().toLowerCase();
                          final paymentStatus = data['paymentStatus']?.toString().trim().toLowerCase();
                          return status == 'completed' && paymentStatus == 'pagado';
                        })
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final offeredPrice = (data['offeredPrice'] ?? 0.0) as num;
                          final commission = (data['commission'] ?? 0.0) as num;
                          return offeredPrice - commission;
                        })
                        .map((income) => income is double
                            ? income
                            : double.tryParse(income.toString()) ?? 0.0)
                        .toList();
                    return _buildTotalsSummary(
                      adeudado: adeudado.fold<double>(0.0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final commission = (data['commission'] ?? 0.0) as num;
                        final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                        return sum + commission + extraCosts;
                      }),
                      ingresos:
                      ingresos.fold<double>(0.0, (sum, income) => sum + income),
                      pagado: pagado.fold<double>(0.0, (sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final commission = (data['commission'] ?? 0.0) as num;
                        final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                        return sum + commission + extraCosts;
                      }),
                    );
                  },
                ),
                // TabBar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    labelStyle: const TextStyle(fontSize: 0),
                    unselectedLabelStyle: MyTextStyles.inputTextStyle,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3.0, color: Color(0xFF84090D)),
                      insets: EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                    tabs: [
                      Tab(
                          child:
                          Text('Adeudado', style: MyTextStyles.inputTextStyle)),
                      Tab(
                          child:
                          Text('Ingresos', style: MyTextStyles.inputTextStyle)),
                      Tab(
                          child:
                          Text('Pagado', style: MyTextStyles.inputTextStyle)),
                    ],
                  ),
                ),
                // Filtros rápidos
                _buildFilters(),
                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text('Movimientos',
                      style: MyTextStyles.buttonTextStyle3,
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _getOffers(),
                      builder: (context, snapshot) {
                        print(
                            '[DEBUG] ListStreamBuilder - Connection State: ${snapshot.connectionState}');
                        print(
                            '[DEBUG] ListStreamBuilder - Has Data: ${snapshot.hasData}');
                        print(
                            '[DEBUG] ListStreamBuilder - Has Error: ${snapshot.hasError}');
                        if (snapshot.hasError) {
                          print(
                              '[DEBUG] ListStreamBuilder - Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData) {
                          print(
                              '[DEBUG] ListStreamBuilder - Data docs count: ${snapshot.data!.docs.length}');
                        }

                        if (_showSkeleton) {
                          print(
                              '[DEBUG] ListStreamBuilder - Showing skeleton loader');
                          return _buildSkeletonLoader();
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          print('[DEBUG] ListStreamBuilder - Connection waiting');
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          print('[DEBUG] ListStreamBuilder - Showing error state');
                          return const Center(
                              child: Text('Error al cargar los datos.'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          print(
                              '[DEBUG] ListStreamBuilder - No data, showing empty state');
                          return _buildEmptyState();
                        }

                        final offers = snapshot.data!.docs;
                        print(
                            '[DEBUG] ListStreamBuilder - Processing ${offers.length} offers');

                        // Log cada documento para verificar acceso a datos
                        for (int i = 0; i < offers.length; i++) {
                          try {
                            final doc = offers[i];
                            final data = doc.data() as Map<String, dynamic>;
                            print('[DEBUG] ListDoc $i - ID: ${doc.id}');
                            print(
                                '[DEBUG] ListDoc $i - workerId: ${data['workerId']}');
                            print('[DEBUG] ListDoc $i - status: ${data['status']}');
                            print(
                                '[DEBUG] ListDoc $i - paymentStatus: ${data['paymentStatus']}');
                          } catch (e) {
                            print('[DEBUG] ListDoc $i - Error accessing data: $e');
                          }
                        }

                        // Filtro correcto para la lista de adeudado en la pestaña
                        final adeudado = offers.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString().trim().toLowerCase();
                          final paymentStatus = (data['paymentStatus'] ?? '').toString().trim().toLowerCase();
                          return status == 'completed' && paymentStatus == 'debe';
                        }).toList();
                        print('[LOG ADEUDADO] Total documentos adeudados (pestaña): ${adeudado.length}');

                        final pagado = offers.where((doc) {
                          final status =
                          (doc.data() as Map<String, dynamic>)['status']
                              ?.toString()
                              .trim()
                              .toLowerCase();
                          final paymentStatus =
                          (doc.data() as Map<String, dynamic>)['paymentStatus']
                              ?.toString()
                              .trim()
                              .toLowerCase();
                          return status == 'completed' && paymentStatus == 'pagado';
                        }).toList();
                        print(
                            '[DEBUG] ListStreamBuilder - Pagado count: ${pagado.length}');

                        final ingresos = offers
                            .where((doc) {
                          final status =
                          (doc.data() as Map<String, dynamic>)['status']
                              ?.toString()
                              .trim()
                              .toLowerCase();
                          return status == 'completed';
                        })
                            .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final offeredPrice =
                          (data['offeredPrice'] ?? 0.0) as num;
                          final commission = (data['commission'] ?? 0.0) as num;
                          return offeredPrice - commission;
                        })
                            .map((income) => income is double
                            ? income
                            : double.tryParse(income.toString()) ?? 0.0)
                            .toList();
                        print(
                            '[DEBUG] ListStreamBuilder - Ingresos count: ${ingresos.length}');
                        print(
                            '[DEBUG] ListStreamBuilder - Ingresos values: $ingresos');

                        print(
                            '[DEBUG] ListStreamBuilder - About to build TabBarView');
                        print(
                            '[DEBUG] ListStreamBuilder - _showSkeleton: $_showSkeleton');

                        return TabBarView(
                          children: [
                            _buildFilteredOfferList(
                                context, adeudado, 'Adeudado', offers),
                            _buildFilteredIncomeList(context, ingresos, offers),
                            _buildFilteredOfferList(
                                context, pagado, 'Pagado', offers),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildTotalsSummary(
      {required double adeudado,
        required double ingresos,
        required double pagado}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildTotalCard(
                'Adeudado',
                '\Bs ${adeudado.toStringAsFixed(2)}',
                Color(0xFF84090D),
                Icons.warning),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTotalCard(
                'Ingresos',
                '\Bs ${ingresos.toStringAsFixed(2)}',
                Colors.black87,
                Icons.trending_up),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTotalCard('Pagado', '\Bs ${pagado.toStringAsFixed(2)}',
                Color(0xFF4CAF50), Icons.check_circle),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(
      String label, String value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      shadowColor: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: label == 'Adeudado'
                    ? Color(0xFF84090D)
                    : (label == 'Pagado' ? Color(0xFF4CAF50) : Colors.black87),
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: label == 'Adeudado'
                        ? Color(0xFF84090D)
                        : (label == 'Pagado'
                        ? Color(0xFF4CAF50)
                        : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: label == 'Adeudado'
                      ? Color(0xFF84090D)
                      : (label == 'Pagado'
                      ? Color(0xFF4CAF50)
                      : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showDateRangePicker,
            icon: const Icon(Icons.date_range, size: 18),
            label: const Text('Fechas'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.all(12),
                color: Colors.grey[300],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 120, height: 14, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.grey[200]),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No hay movimientos registrados.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilteredOfferList(
      BuildContext context,
      List<QueryDocumentSnapshot> offers,
      String title,
      List<QueryDocumentSnapshot> allOffers) {
    print(
        '[DEBUG] _buildFilteredOfferList - Building $title with ${offers.length} offers');

    final filteredOffers = offers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final matchesSearch = data['serviceId']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesDate =
          _selectedDateRange == null || _dateInRange(data['createdAt']);
      return matchesSearch && matchesDate;
    }).toList();

    print(
        '[DEBUG] _buildFilteredOfferList - Filtered offers: ${filteredOffers.length}');

    return Column(
      children: [
        Expanded(
          child: filteredOffers.isEmpty
              ? Center(
            child: Text(
              'No hay $title registrados.',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
          )
              : _buildOfferList(context, filteredOffers, title, allOffers),
        ),
      ],
    );
  }

  Widget _buildFilteredIncomeList(BuildContext context, List<double> ingresos,
      List<QueryDocumentSnapshot> services) {
    print(
        '[DEBUG] _buildFilteredIncomeList - Building with ${ingresos.length} ingresos and ${services.length} services');

    // Filtrar solo servicios completados
    final completedServices = services.where((service) {
      final status = (service.data() as Map<String, dynamic>)['status']
          ?.toString()
          .trim()
          .toLowerCase();
      return status == 'completed';
    }).toList();

    print(
        '[DEBUG] _buildFilteredIncomeList - Completed services: ${completedServices.length}');

    // Calcular estadísticas mensuales
    _calculateMonthlyIncome(completedServices);

    final filteredServices = completedServices.where((offer) {
      final matchesSearch = offer['serviceId']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesDate =
          _selectedDateRange == null || _dateInRange(offer['createdAt']);
      return matchesSearch && matchesDate;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Selector de período
          _buildPeriodSelector(),
          // Estadísticas principales
          _buildIncomeStatistics(),
          // Gráfico de barras mensual
          _buildMonthlyChart(),
          // Lista de transacciones
          _buildIncomeTransactionsList(context, filteredServices),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Color(0xFF84090D), size: 20),
          const SizedBox(width: 8),
          Text('Período:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF84090D))),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedIncomePeriod,
              isExpanded: true,
              underline: Container(),
              items: [
                DropdownMenuItem(value: '3', child: Text('Últimos 3 meses')),
                DropdownMenuItem(value: '6', child: Text('Últimos 6 meses')),
                DropdownMenuItem(value: '12', child: Text('Últimos 12 meses')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedIncomePeriod = value ?? '6';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: en pantallas pequeñas, mostrar en columna
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _buildStatCard(
                  'Total',
                  'Bs ${_totalIncome.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Promedio',
                        'Bs ${_averageIncome.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Mejor mes',
                        _bestMonth.isNotEmpty ? _bestMonth : 'N/A',
                        Icons.star,
                        Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // En pantallas grandes, mostrar en fila
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  'Bs ${_totalIncome.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Promedio',
                  'Bs ${_averageIncome.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Mejor mes',
                  _bestMonth.isNotEmpty ? _bestMonth : 'N/A',
                  Icons.star,
                  Color(0xFFFF9800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyIncome.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No hay datos de ingresos para mostrar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Filtrar solo meses con ingresos mayores a 0
    final monthsWithIncome =
    _monthlyIncome.entries.where((entry) => entry.value > 0).toList();

    if (monthsWithIncome.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No hay ingresos registrados en este período',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxIncome =
    monthsWithIncome.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final sortedMonths = monthsWithIncome.map((e) => e.key).toList()..sort();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF84090D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historial de Ingresos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF84090D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth < 400 ? 100.0 : 120.0;
              final barWidth = constraints.maxWidth < 400 ? 16.0 : 20.0;

              return SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: sortedMonths.map((month) {
                    final income = _monthlyIncome[month] ?? 0.0;
                    // Solo mostrar barras si hay ingreso
                    if (income <= 0) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: barWidth,
                                  // Barra invisible para mantener el espacio
                                  color: Colors.transparent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM', 'es').format(
                                    DateFormat('MMM yyyy', 'es').parse(month)),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Bs0',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Calcular altura proporcional al ingreso
                    final height = maxIncome > 0 ? (income / maxIncome) : 0.0;
                    final isCurrentMonth = month ==
                        DateFormat('MMM yyyy', 'es').format(DateTime.now());

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: barWidth,
                                decoration: BoxDecoration(
                                  color: isCurrentMonth
                                      ? Color(0xFF84090D)
                                      : Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isCurrentMonth
                                          ? Color(0xFF84090D)
                                          : Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM', 'es').format(
                                  DateFormat('MMM yyyy', 'es').parse(month)),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Bs${income.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF84090D),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTransactionsList(
      BuildContext context, List<QueryDocumentSnapshot> services) {
    if (services.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay transacciones de ingresos',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Transacciones (${services.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF84090D),
              ),
            ),
          ),
          SizedBox(
            height: 300, // Altura fija para evitar overflow
            child: ListView.builder(
              itemCount: services.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final service = services[index];
                final commission = service['commission'] ?? 0.0;
                final offeredPrice = service['offeredPrice'] ?? 0.0;
                final netIncome = offeredPrice - commission;
                final serviceId = service['serviceId'] ?? 'Sin ID';
                final status = service['status'] ?? 'Desconocido';
                final createdAtData = service['createdAt'];

                DateTime createdAt;
                if (createdAtData is Timestamp) {
                  createdAt = createdAtData.toDate();
                } else if (createdAtData is String) {
                  createdAt =
                      DateTime.tryParse(createdAtData) ?? DateTime.now();
                } else if (createdAtData is Map &&
                    createdAtData['_seconds'] != null) {
                  // Firestore timestamp format
                  createdAt = DateTime.fromMillisecondsSinceEpoch(
                    (createdAtData['_seconds'] as int) * 1000,
                  );
                } else {
                  createdAt = DateTime.now();
                }

                final isNew =
                    DateTime.now().difference(createdAt).inMinutes < 10;
                final monthName =
                DateFormat('MMM yyyy', 'es').format(createdAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bs${netIncome.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFFDE8E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NUEVO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF84090D),
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                          style:
                          TextStyle(color: Colors.grey[600], fontSize: 10),
                        ),
                        Text(
                          'Mes: $monthName',
                          style: TextStyle(
                            color: Color(0xFF84090D),
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'INGRESO',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _showIncomeDetails(
                        context, service.data() as Map<String, dynamic>),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomeDetails(BuildContext context, Map<String, dynamic> service) {
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
      // Firestore timestamp format
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      createdAt = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        color: Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.attach_money,
                          color: Color(0xFF4CAF50), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                _buildDetailRow('Ingreso Neto',
                    'Bs${netIncome.toStringAsFixed(2)}', Color(0xFF4CAF50)),
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
                      backgroundColor: Color(0xFF84090D),
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
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

  bool _dateInRange(dynamic createdAtData) {
    if (_selectedDateRange == null) return true;
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null) {
      // Firestore timestamp format
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      createdAt = DateTime.now();
    }
    return createdAt.isAfter(
        _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
        createdAt
            .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: 'Buscar por ID o cliente',
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
      style: const TextStyle(color: Colors.black),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildOfferList(
      BuildContext context,
      List<QueryDocumentSnapshot> offers,
      String title,
      List<QueryDocumentSnapshot> allOffers) {
    return ListView.builder(
      itemCount: offers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final offerId =
        offer is QueryDocumentSnapshot ? offer.id : (offer['id'] ?? '');
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
          // Firestore timestamp format
          createdAt = DateTime.fromMillisecondsSinceEpoch(
            (createdAtData['_seconds'] as int) * 1000,
          );
        } else {
          createdAt = DateTime.now();
        }
        final isNew = DateTime.now().difference(createdAt).inMinutes < 10;

        // Si es la sección de adeudado, mostrar desglose detallado
        if (title == 'Adeudado') {
          return Card(
            color: _isSelectionMode && _selectedDebtIds.contains(offerId)
                ? Color(0xFFFDE8E9)
                : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: _isSelectionMode && _selectedDebtIds.contains(offerId)
                  ? BorderSide(color: Color(0xFF84090D), width: 2)
                  : BorderSide.none,
            ),
            elevation: 3,
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleDebtSelection(offerId)
                  : () => _showOfferDetails(
                  context, offer.data() as Map<String, dynamic>),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                      value: _selectedDebtIds.contains(offerId),
                      onChanged: (value) => _toggleDebtSelection(offerId),
                      activeColor: Color(0xFF84090D),
                    )
                        : CircleAvatar(
                      backgroundColor: Color(0xFF84090D),
                      child:
                      const Icon(Icons.warning, color: Colors.white),
                    ),
                    title: Text('Adeudado: \Bs${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Fecha: ${createdAt.toLocal()}',
                        style: const TextStyle(color: Colors.grey)),
                    trailing: isNew
                        ? Chip(
                      label: const Text('Nuevo'),
                      backgroundColor: Color(0xFFFDE8E9),
                      labelStyle: TextStyle(
                        color: Color(0xFF84090D),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  if (!_isSelectionMode)
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
                  ? Color(0xFF4CAF50)
                  : Color(0xFF84090D),
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
                                  ? Color(0xFF4CAF50)
                                  : Color(0xFF84090D),
                              fontWeight: FontWeight.bold)),
                      backgroundColor: paymentStatus == 'pagado'
                          ? Color(0xFFE8F5E9)
                          : Color(0xFFFDE8E9),
                    ),
                    if (isNew)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: const Text('Nuevo'),
                          backgroundColor: Color(0xFFFDE8E9),
                          labelStyle: TextStyle(
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
                    ? Color(0xFF4CAF50)
                    : Color(0xFF84090D),
                fontSize: 18,
              ),
            ),
            onTap: () => _showOfferDetails(
                context, offer.data() as Map<String, dynamic>),
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
    final paymentStatus = offer['paymentStatus'] ?? 'Desconocido';
    final createdAtData = offer['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAt = DateTime.tryParse(createdAtData) ?? DateTime.now();
    } else if (createdAtData is Map && createdAtData['_seconds'] != null) {
      // Firestore timestamp format
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (createdAtData['_seconds'] as int) * 1000,
      );
    } else {
      createdAt = DateTime.now();
    }

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
      },
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedDebtIds.clear();
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedDebtIds.clear();
    });
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

  void _showDebtSummaryWithData(Map<String, dynamic> debtDetails) {
    if (_selectedDebtIds.isEmpty) return;

    final selectedDebts = debtDetails['debts'] as List<Map<String, dynamic>>;
    final totalAmount = debtDetails['totalAmount'] as double;
    final serviceIds = debtDetails['serviceIds'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF84090D)),
            const SizedBox(width: 8),
            Text('Resumen de Pagos',
                style: TextStyle(
                    color: Color(0xFF84090D), fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deudas seleccionadas: ${_selectedDebtIds.length}',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Detalle de servicios:'),
              const SizedBox(height: 4),
              ...selectedDebts.map((debt) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${debt['serviceId']}',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                          '  Comisión: Bs${debt['commission'].toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                          '  Extras: Bs${debt['extraCosts'].toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                          '  Total: Bs${debt['total'].toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFDE8E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF84090D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total a pagar:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF84090D))),
                    Text('Bs ${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF84090D))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('¿Deseas enviar esta información por WhatsApp?',
                  style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Color(0xFF84090D))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendDebtSummaryToWhatsAppWithData(debtDetails);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar por WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _sendDebtSummaryToWhatsApp() async {
    const phoneNumber = '+59165884846';

    // Crear mensaje detallado
    final serviceIds = _selectedDebtIds.join(', ');
    final message = Uri.encodeFull(
        "Hola, quisiera solicitar el código QR para realizar el pago de las siguientes deudas:\n\n"
            "Servicios: $serviceIds\n"
            "Total de deudas seleccionadas: ${_selectedDebtIds.length}\n\n"
            "Por favor, envíame el código QR correspondiente.");

    final whatsappUrl = "https://wa.me/$phoneNumber?text=$message";

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }

    // Salir del modo selección
    _cancelSelection();
  }

  void _sendDebtSummaryToWhatsAppWithData(
      Map<String, dynamic> debtDetails) async {
    const phoneNumber = '+59165884846';

    final selectedDebts = debtDetails['debts'] as List<Map<String, dynamic>>;
    final totalAmount = debtDetails['totalAmount'] as double;
    final serviceIds = debtDetails['serviceIds'] as List<String>;

    // Crear mensaje detallado
    final serviceIdsText = serviceIds.join(', ');
    final debtDetailsText = selectedDebts
        .map((debt) =>
    '• ${debt['serviceId']}: Bs${debt['total'].toStringAsFixed(2)}')
        .join('\n');

    final message = Uri.encodeFull(
        "Hola, quisiera solicitar el código QR para realizar el pago de las siguientes deudas:\n\n"
            "Servicios: $serviceIdsText\n"
            "Total de deudas seleccionadas: ${selectedDebts.length}\n\n"
            "Detalle:\n$debtDetailsText\n\n"
            "Total a pagar: Bs${totalAmount.toStringAsFixed(2)}\n\n"
            "Por favor, envíame el código QR correspondiente.");

    final whatsappUrl = "https://wa.me/$phoneNumber?text=$message";

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }

    // Salir del modo selección
    _cancelSelection();
  }

  Map<String, dynamic> _getSelectedDebtDetails(
      List<QueryDocumentSnapshot> allOffers) {
    final selectedDebts = <Map<String, dynamic>>[];
    double totalAmount = 0.0;
    final serviceIds = <String>[];

    for (final debtId in _selectedDebtIds) {
      try {
        final offer = allOffers.firstWhere(
              (offer) => offer.id == debtId,
        );
        final commission = offer['commission'] ?? 0.0;
        final extraCosts = offer['extraCosts'] ?? 0.0;
        final serviceId = offer['serviceId'] ?? 'Sin ID';
        final debtAmount = commission + extraCosts;
        totalAmount += debtAmount;
        serviceIds.add(serviceId);
        selectedDebts.add({
          'serviceId': serviceId,
          'commission': commission,
          'extraCosts': extraCosts,
          'total': debtAmount,
        });
      } catch (e) {
        print('Documento no encontrado para debtId: $debtId');
        continue;
      }
    }
    return {
      'debts': selectedDebts,
      'totalAmount': totalAmount,
      'serviceIds': serviceIds,
    };
  }

  List<QueryDocumentSnapshot> _getCurrentOffers() {
    return _currentOffers;
  }
}
