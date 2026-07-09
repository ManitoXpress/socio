import 'dart:ui';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socio/Widgets/modern_tabbar.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../ServiceResponse/get.dart';
import '../ServiceResponse/request.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../models/expertiseModels.dart';
import '../models/offerModels.dart';
import '../models/serviceModels.dart';
import '../provider/service_partner_provider.dart';
import '../provider/providerService.dart';
import '../Utils/timeLines.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color principal de ManitoSocio
// ─────────────────────────────────────────────────────────────────────────────
const Color _kSocioColor = Color(0xFF830A09);

// ─────────────────────────────────────────────────────────────────────────────
//  HistorialScreen
// ─────────────────────────────────────────────────────────────────────────────
class HistorialScreen extends StatefulWidget {
  final UserData userData;
  const HistorialScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final HistorialProvider _historialProv;

  String _userId = '';
  String _token = '';
  String _deviceId = '';
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    // 3 pestañas consolidadas
    _tabController = TabController(length: 3, vsync: this);
    _historialProv = HistorialProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeHistorial();
    });
  }

  // ─── Inicialización correcta: variables locales, sin Future.microtask ───────
  Future<void> _initializeHistorial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Variables locales — no depender del estado de setState
    final userId = user.uid;
    if (!mounted) return;
    setState(() => _userId = userId);

    // Mostrar diálogo de bienvenida solo 1 vez
    if (!_welcomeShown) {
      _welcomeShown = true;
      _showWelcomeDialog();
    }

    final futures = await Future.wait([
      user.getIdToken(),
      _fetchDeviceId(),
    ]).timeout(const Duration(seconds: 5), onTimeout: () => ['', 'timeout']);

    final token = futures[0] as String? ?? '';
    final deviceId = futures[1] as String;

    if (!mounted) return;
    setState(() {
      _token = token;
      _deviceId = deviceId;
    });

    // Solo omitir carga si ya hay datos REALES en memoria
    final yaConDatos = _historialProv.list('available').isNotEmpty ||
        _historialProv.list('offer').isNotEmpty ||
        _historialProv.list('in_progress').isNotEmpty ||
        _historialProv.list('completed').isNotEmpty;

    if (!yaConDatos) {
      // Usar variables locales garantizadas
      await _historialProv.loadAll(
        userId: userId,
        token: token,
        deviceId: deviceId,
      );
    }

    if (!mounted) return;
    _historialProv.startAutoRefresh(
      userId: userId,
      token: token,
      deviceId: deviceId,
    );
  }

  Future<String> _fetchDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id ?? 'unknown';
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'unknown';
    }
    return 'unsupported';
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('¡Bienvenido a ManitosXpress!',
              style: MyTextStyles.welcomeTotheJungle1),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gracias por unirte a ManitosXpress. Aquí podrás ofrecer tus habilidades y conectarte con clientes que necesitan tu ayuda.',
                style: MyTextStyles.formServiceTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Revisa los servicios disponibles y envía tus propuestas. ¡Tu próximo proyecto está a un clic de distancia!',
                style: MyTextStyles.formServiceTextStyle,
                textAlign: TextAlign.center,
              ),
              const Icon(Icons.build_rounded, size: 60, color: _kSocioColor),
              const SizedBox(height: 20),
              Text(
                '"Aprovecha de utilizar la app y ampliar tu red de clientes! Manitos Xpress - Seguridad, Confianza y Tiempo"',
                style: MyTextStyles.inputTextStyle6,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: _kSocioColor,
                backgroundColor: const Color(0xFFE8E8E8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
              child: Text('Comenzar', style: MyTextStyles.linkTextStyle),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historialProv.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _historialProv,
      child: Consumer<HistorialProvider>(
        builder: (_, prov, __) {
          // Conteos para los badges
          final waitCount = prov.list('available').length + prov.list('offer').length;
          final inProgressCount = prov.list('in_progress').length;
          final completedCount = prov.list('completed').length + prov.list('cancelled').length;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: ModernTabBar(
                  controller: _tabController,
                  waitCount: waitCount,
                  inProgressCount: inProgressCount,
                  completedCount: completedCount,
                  mainColor: _kSocioColor,
                ),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Center(
                        child: Text('Historial',
                            style: MyTextStyles.buttonTextStyle3),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Pestaña 0: En espera (available + offer)
                          _ServiceListTab(
                            statuses: const ['available', 'offer'],
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(
                              userId: _userId,
                              token: _token,
                              deviceId: _deviceId,
                            ),
                            isLoading: prov.isLoading,
                          ),
                          // Pestaña 1: En proceso (in_progress)
                          _ServiceListTab(
                            statuses: const ['in_progress'],
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(
                              userId: _userId,
                              token: _token,
                              deviceId: _deviceId,
                            ),
                            isLoading: prov.isLoading,
                          ),
                          // Pestaña 2: Finalizados (completed + cancelled)
                          _ServiceListTab(
                            statuses: const ['completed', 'cancelled'],
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(
                              userId: _userId,
                              token: _token,
                              deviceId: _deviceId,
                            ),
                            isLoading: prov.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Overlay de carga global
                if (prov.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.15),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _kSocioColor),
                          SizedBox(height: 16),
                          Text('Cargando servicios...',
                              style: TextStyle(fontSize: 16, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: prov.isLoading
                  ? null
                  : () => prov.refresh(
                        userId: _userId,
                        token: _token,
                        deviceId: _deviceId,
                      ),
              label: const Text('Actualizar'),
              icon: const Icon(Icons.refresh),
              backgroundColor: _kSocioColor,
              foregroundColor: Colors.white,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ServiceListTab — pestaña con múltiples estados + deduplicación estable
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceListTab extends StatefulWidget {
  final List<String> statuses;
  final String userId;
  final UserData userData;
  final ApiService apiService;
  final ApiService2 apiService2;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  const _ServiceListTab({
    required this.statuses,
    required this.userId,
    required this.userData,
    required this.apiService,
    required this.apiService2,
    required this.onRefresh,
    required this.isLoading,
    Key? key,
  }) : super(key: key);

  @override
  State<_ServiceListTab> createState() => _ServiceListTabState();
}

class _ServiceListTabState extends State<_ServiceListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final prov = context.read<HistorialProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      for (final status in widget.statuses) {
        if (prov.hasMore(status) && !prov.isLoadingMore(status)) {
          prov.loadMore(
            status: status,
            userId: widget.userId,
            token: '',
            deviceId: '',
          );
        }
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<HistorialProvider>(
      builder: (context, prov, child) {
        // ── Combinar listas de múltiples estados ──────────────────────────────
        List<ServiceRequest> rawList = [];
        bool isLoadingMore = false;
        bool hasMore = false;

        for (final s in widget.statuses) {
          rawList.addAll(prov.list(s));
          if (prov.isLoadingMore(s)) isLoadingMore = true;
          if (prov.hasMore(s)) hasMore = true;
        }

        // ── Deduplicación estable por description + serviceDateTime ───────────
        // (createdAt no es confiable — se asigna en parseo como DateTime.now())
        List<ServiceRequest> list = [];
        final itemsVistos = <String>{};
        for (final item in rawList) {
          final uniqueKey = '${item.description}_${item.serviceDateTime}';
          if (!itemsVistos.contains(uniqueKey)) {
            itemsVistos.add(uniqueKey);
            list.add(item);
          }
        }

        // ── Ordenar por serviceDateTime descendente ───────────────────────────
        list.sort((a, b) =>
            b.serviceDateTime.compareTo(a.serviceDateTime));

        // ── Manejo de estados UI ──────────────────────────────────────────────
        if (prov.errorMessage != null) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Text(
                  'Error: ${prov.errorMessage}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }

        // Skeleton loader mientras carga y lista vacía
        if (widget.isLoading && list.isEmpty) {
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: 5,
            itemBuilder: (context, index) => _SkeletonCard(),
          );
        }

        if (list.isEmpty && !widget.isLoading) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[350]),
                    const SizedBox(height: 12),
                    Text(
                      'No hay servicios aquí.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // ── Lista principal con tarjetas glassmorphic ─────────────────────────
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: _kSocioColor,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200 &&
                  hasMore &&
                  !isLoadingMore) {
                for (final status in widget.statuses) {
                  final prov = context.read<HistorialProvider>();
                  if (prov.hasMore(status) && !prov.isLoadingMore(status)) {
                    prov.loadMore(
                      status: status,
                      userId: widget.userId,
                      token: '',
                      deviceId: '',
                    );
                  }
                }
              }
              return false;
            },
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final service = list[index];
                    return _GlassmorphicServiceCard(
                      service: service,
                      userId: widget.userId,
                      userData: widget.userData,
                      apiService: widget.apiService,
                      apiService2: widget.apiService2,
                    );
                  },
                ),
                if (isLoadingMore)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kSocioColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Cargando más...',
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _GlassmorphicServiceCard — tarjeta moderna glassmorphic
// ─────────────────────────────────────────────────────────────────────────────
class _GlassmorphicServiceCard extends StatelessWidget {
  final ServiceRequest service;
  final String userId;
  final UserData userData;
  final ApiService apiService;
  final ApiService2 apiService2;

  const _GlassmorphicServiceCard({
    required this.service,
    required this.userId,
    required this.userData,
    required this.apiService,
    required this.apiService2,
    Key? key,
  }) : super(key: key);

  void _navigateToDetails(BuildContext context, {String? workerId}) {
    final effectiveWorkerId = workerId ?? service.workerId;

    final serviceModel = ServiceRequestModel(
      id: service.id,
      status: service.status.id,
      date: service.serviceType.selectedDate,
      time: service.serviceType.selectedTime,
      description: service.description,
      location: service.location,
      images: service.images,
      expertises: service.expertises
          .map((e) => ExpertiseModel(id: e.id, name: e.name))
          .toList(),
      rawOffers: service.offers
          .map((o) => {
                'workerId': o.workerId,
                'offeredPrice': o.offeredPrice,
                'extraCosts': o.extraCosts,
                'totalPrice': o.totalPrice,
                'status': o.status.id,
                'id': o.id,
              })
          .toList(),
      rawComments: [],
      userId: service.userId,
      workerId: effectiveWorkerId.isNotEmpty ? effectiveWorkerId : userId,
      completionImageUrl: null,
    );

    // Buscar la oferta correspondiente al workerId
    Offer? matchedOffer;
    if (service.offers.isNotEmpty) {
      try {
        matchedOffer = service.offers.firstWhere(
          (o) => o.workerId == effectiveWorkerId,
        );
      } catch (_) {
        matchedOffer = service.offers.first;
      }
    }

    final offerModel = OfferModel(
      id: matchedOffer?.id ?? '',
      serviceId: service.id,
      workerId: effectiveWorkerId.isNotEmpty ? effectiveWorkerId : userId,
      offeredPrice: matchedOffer?.offeredPrice ?? service.offeredPrice,
      status: matchedOffer?.status.id ?? service.status.id,
      subcategoryName: service.subcategoryName,
      expertises: service.expertises
          .map((e) => Expertise(id: e.id, name: e.name))
          .toList(),
      clientNIT: '',
      extraCosts: matchedOffer?.extraCosts ?? 0.0,
      totalPrice: matchedOffer?.totalPrice ?? 0.0,
      paymentStatus: '',
    );

    final allOfferModels = service.offers
        .map((o) => OfferModel(
              id: o.id,
              serviceId: o.serviceId,
              workerId: o.workerId,
              offeredPrice: o.offeredPrice,
              status: o.status.id,
              subcategoryName: o.subcategoryName,
              expertises: o.expertises
                  .map((e) => Expertise(id: e.id, name: e.name))
                  .toList(),
              clientNIT: '',
              extraCosts: o.extraCosts,
              totalPrice: o.totalPrice,
              paymentStatus: '',
            ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider<ServicePartnerProvider>(
          create: (_) => ServicePartnerProvider(
            serviceRequest: serviceModel,
            offer: offerModel,
            userData: userData,
            workerId: serviceModel.workerId,
            offers: allOfferModels,
            apiService: apiService,
            apiService2: apiService2,
            userId: service.userId,
          ),
          child: ServiceFormWithTimelineSocio(
            serviceRequest: serviceModel,
            offer: offerModel,
            userData: userData,
            workerId: serviceModel.workerId,
            offers: allOfferModels,
            apiService: apiService,
            apiService2: apiService2,
            userId: service.userId,
            displayName: userData.displayName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusId = service.status.id;
    final isAvailable = statusId == 'available';
    final isOffer = statusId == 'offer';
    final isInProgress = statusId == 'in_progress';
    final isCompleted = statusId == 'completed';
    final isCancelled = statusId == 'cancelled';

    // Chip de estado
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (isAvailable) {
      statusColor = Colors.orange;
      statusLabel = 'Disponible';
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (isOffer) {
      statusColor = Colors.blue;
      statusLabel = 'Ofertado';
      statusIcon = Icons.local_offer_rounded;
    } else if (isInProgress) {
      statusColor = const Color(0xFF1E88E5);
      statusLabel = 'En proceso';
      statusIcon = Icons.construction_rounded;
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusLabel = 'Completado';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isCancelled) {
      statusColor = Colors.red;
      statusLabel = 'Cancelado';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = Colors.grey;
      statusLabel = statusId;
      statusIcon = Icons.help_outline;
    }

    // Precio a mostrar
    String priceText = 'Bs. 0.00';
    if (service.offeredPrice > 0) {
      priceText = 'Bs. ${service.offeredPrice.toStringAsFixed(2)}';
    } else if (service.offers.isNotEmpty) {
      priceText = 'Bs. ${service.offers.first.offeredPrice.toStringAsFixed(2)}';
    }

    // Fecha
    final dateText = service.serviceDateTime.isNotEmpty
        ? service.serviceDateTime
        : (service.selectedDate ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: _kSocioColor.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Categoría + estado chip + ícono ─────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip de estado
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Categoría:',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            service.subcategoryName.isNotEmpty
                                ? service.subcategoryName
                                : 'Servicio general',
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Servicio:',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            service.expertises.isNotEmpty
                                ? service.expertises
                                    .map((e) => e.name)
                                    .join(', ')
                                : 'Por definir',
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontStyle: service.expertises.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ícono decorativo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _kSocioColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _kSocioColor.withOpacity(0.15), width: 1),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/animations/manito.png',
                          height: 32,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.handyman, color: _kSocioColor, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Precio + Fecha ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Precio ofertado:',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kSocioColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _kSocioColor.withOpacity(0.2),
                                  width: 1),
                            ),
                            child: Text(
                              priceText,
                              style: const TextStyle(
                                  color: _kSocioColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dateText.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            dateText.length > 10
                                ? dateText.substring(0, 10)
                                : dateText,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Descripción (si existe) ───────────────────────────────────
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),

                // ── Botones de acción ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToDetails(context),
                        icon: const Icon(Icons.info_outline, size: 15),
                        label: const Text('Ver detalles',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kSocioColor,
                          side: const BorderSide(color: _kSocioColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton loader card
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(width: 90, height: 22, radius: 6),
              const Spacer(),
              _shimmer(width: 52, height: 52, radius: 14),
            ],
          ),
          const SizedBox(height: 10),
          _shimmer(width: 140, height: 14, radius: 4),
          const SizedBox(height: 6),
          _shimmer(width: 200, height: 18, radius: 4),
          const SizedBox(height: 10),
          _shimmer(width: 100, height: 14, radius: 4),
          const SizedBox(height: 6),
          _shimmer(width: 160, height: 14, radius: 4),
          const SizedBox(height: 14),
          _shimmer(width: double.infinity, height: 36, radius: 10),
        ],
      ),
    );
  }

  Widget _shimmer(
      {required double width,
      required double height,
      required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
