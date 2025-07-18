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

  // Variables para el apartado de deudas
  List<Map<String, dynamic>> _allDebts = [];
  bool _isLoadingDebts = true;

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

    // Cargar deudas con información de vencimiento
    _loadDebtsWithDueInfo();
  }

  Future<void> _loadDebtsWithDueInfo() async {
    try {
      final debtService = DebtBlockerService();
      final debts = await debtService.getAllDebtsWithDueInfo();
      if (mounted) {
        setState(() {
          _allDebts = debts;
          _isLoadingDebts = false;
        });
      }
    } catch (e) {
      print('Error cargando deudas: $e');
      if (mounted) {
        setState(() => _isLoadingDebts = false);
      }
    }
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

      // Obtener los documentos existentes de Firestore
      final firestoreDocs = await firestoreQuery.get();

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

        // Obtener los documentos recién creados
        return await firestoreQuery.get();
      }

      return firestoreDocs;
    } catch (e) {
      print('[DEBUG] _getOffersFromAPI - Error: $e');
      // Fallback a Firestore si la API falla
      return FirebaseFirestore.instance
          .collection('offers')
          .where('workerId', isEqualTo: workerId)
          .get();
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
      length: 4,
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
                        : () => WalletDialogs.showDebtSummaryDialog(
                            context, _selectedDebtIds, _getCurrentOffers()),
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
                  return WalletTotalsSummary(
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
                  return status == 'completed' && paymentStatus == 'debe';
                }).fold<double>(0.0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final commission = (data['commission'] ?? 0.0) as num;
                  final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                  return sum + commission + extraCosts;
                });
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
                }).fold<double>(0.0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final commission = (data['commission'] ?? 0.0) as num;
                  final extraCosts = (data['extraCosts'] ?? 0.0) as num;
                  return sum + commission + extraCosts;
                });
                // Ingresos: suma de (offeredPrice - commission) para servicios completados (nuestro ingreso neto)
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
                      final offeredPrice = (data['offeredPrice'] ?? 0.0) as num;
                      final commission = (data['commission'] ?? 0.0) as num;
                      return offeredPrice - commission;
                    })
                    .map((income) => income is double
                        ? income
                        : double.tryParse(income.toString()) ?? 0.0)
                    .toList();
                return WalletTotalsSummary(
                  adeudado: adeudado,
                  ingresos:
                      ingresos.fold<double>(0.0, (sum, income) => sum + income),
                  pagado: pagado,
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
                  Tab(
                      child:
                          Text('Deudas', style: MyTextStyles.inputTextStyle)),
                ],
              ),
            ),
            // Filtros rápidos
            WalletFilters(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              selectedDateRange: _selectedDateRange,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              onDateRangeChanged: (value) {
                setState(() {
                  _selectedDateRange = value;
                });
              },
            ),
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

                    final adeudado = offers.where((doc) {
                      final status =
                          (doc.data() as Map<String, dynamic>)['status']
                              ?.toString()
                              .trim()
                              .toLowerCase();
                      return status == 'completed';
                    }).toList();
                    print(
                        '[DEBUG] ListStreamBuilder - Adeudado count: ${adeudado.length}');

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
                        WalletOfferList(
                          offers: adeudado,
                          title: 'Adeudado',
                          allOffers: offers,
                          isSelectionMode: _isSelectionMode,
                          selectedDebtIds: _selectedDebtIds,
                          onToggleDebtSelection: _toggleDebtSelection,
                          onShowOfferDetails: (data) =>
                              _showOfferDetails(context, data),
                        ),
                        WalletIncomeList(
                          ingresos: ingresos,
                          services: offers,
                          selectedIncomePeriod: _selectedIncomePeriod,
                          monthlyIncome: _monthlyIncome,
                          totalIncome: _totalIncome,
                          averageIncome: _averageIncome,
                          bestMonthIncome: _bestMonthIncome,
                          bestMonth: _bestMonth,
                          onPeriodChanged: (value) {
                            setState(() {
                              _selectedIncomePeriod = value ?? '6';
                            });
                          },
                          onShowIncomeDetails: (data) =>
                              _showIncomeDetails(context, data),
                        ),
                        WalletOfferList(
                          offers: pagado,
                          title: 'Pagado',
                          allOffers: offers,
                          isSelectionMode: false,
                          selectedDebtIds: _selectedDebtIds,
                          onToggleDebtSelection: _toggleDebtSelection,
                          onShowOfferDetails: (data) =>
                              _showOfferDetails(context, data),
                        ),
                        _buildDebtsTab(),
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
              : WalletOfferList(
                  offers: filteredOffers,
                  title: title,
                  allOffers: allOffers,
                  isSelectionMode: _isSelectionMode,
                  selectedDebtIds: _selectedDebtIds,
                  onToggleDebtSelection: _toggleDebtSelection,
                  onShowOfferDetails: (data) =>
                      _showOfferDetails(context, data),
                ),
        ),
      ],
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

  void _toggleDebtSelection(String offerId) {
    setState(() {
      if (_selectedDebtIds.contains(offerId)) {
        _selectedDebtIds.remove(offerId);
      } else {
        _selectedDebtIds.add(offerId);
      }
    });
  }

  void _showOfferDetails(BuildContext context, Map<String, dynamic> offer) {
    showDialog(
      context: context,
      builder: (context) {
        // Aquí va el contenido del diálogo de detalles de la oferta
        return WalletDialogs.buildOfferDetailsDialog(context, offer);
      },
    );
  }

  void _showIncomeDetails(BuildContext context, Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) {
        // Aquí va el contenido del diálogo de detalles de ingresos
        return WalletDialogs.buildIncomeDetailsDialog(context, service);
      },
    );
  }

  List<QueryDocumentSnapshot> _getCurrentOffers() {
    return _currentOffers;
  }

  Widget _buildDebtsTab() {
    if (_isLoadingDebts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allDebts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60, color: Colors.green[400]),
            const SizedBox(height: 16),
            const Text('No tienes deudas pendientes.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _allDebts.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final debt = _allDebts[index];
        final daysUntilDue = debt['daysUntilDue'] as int;
        final isOverdue = debt['isOverdue'] as bool;
        final isWarning = debt['isWarning'] as bool;

        // Determinar el color del borde y fondo según el estado
        Color borderColor;
        Color backgroundColor;
        Color textColor;

        if (isOverdue) {
          borderColor = const Color(0xFFD32F2F); // Rojo para vencidas
          backgroundColor = const Color(0xFFFFEBEE);
          textColor = const Color(0xFFD32F2F);
        } else if (isWarning) {
          borderColor = const Color(0xFFFF9800); // Naranja para advertencia
          backgroundColor = const Color(0xFFFFF3E0);
          textColor = const Color(0xFFE65100);
        } else {
          borderColor = const Color(0xFF4CAF50); // Verde para al día
          backgroundColor = const Color(0xFFE8F5E8);
          textColor = const Color(0xFF2E7D32);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 2),
          ),
          elevation: 2,
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ID de servicio y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Servicio: ${debt['serviceId']}',
                        style: MyTextStyles.inputTextStyle5.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue
                            ? 'VENCIDO'
                            : (isWarning ? 'PRÓXIMO' : 'AL DÍA'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fechas
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completado:',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            debt['formattedCreatedAt'],
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vencimiento:',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            debt['formattedDueDate'],
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Días restantes o de retraso
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue
                        ? '${daysUntilDue.abs()} día${daysUntilDue.abs() == 1 ? '' : 's'} de retraso'
                        : 'Vence en ${daysUntilDue} día${daysUntilDue == 1 ? '' : 's'}',
                    style: MyTextStyles.inputTextStyle5.copyWith(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Desglose de montos
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comisión:',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Bs ${(debt['commission'] as double).toStringAsFixed(2)}',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Costos extras:',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Bs ${(debt['extraCosts'] as double).toStringAsFixed(2)}',
                            style: MyTextStyles.inputTextStyle5.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Total de esta deuda
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de esta deuda:',
                        style: MyTextStyles.inputTextStyle5.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bs ${(debt['total'] as double).toStringAsFixed(2)}',
                        style: MyTextStyles.inputTextStyle5.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
