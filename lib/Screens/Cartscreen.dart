import 'dart:async';

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:socio/ServiceResponse/post.dart';

import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/notification.dart';
import 'package:socio/Utils/serviceFetcher.dart';
import 'package:socio/Utils/serviceList.dart';
import 'package:socio/Utils/workerDetails.dart';
import 'package:socio/provider/providerService.dart';

import '../ServiceResponse/get.dart';
import '../ServiceResponse/request.dart';

import '../Utils/styles.dart';
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

  String _userId   = '';
  String _token    = '';
  String _deviceId = '';
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 1) Creamos el provider UNA sola vez
    _historialProv = HistorialProvider();

    // 2) Obtenemos credenciales y disparamos la carga
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token    = await user.getIdToken();
      final deviceId = await _fetchDeviceId();

      if (!mounted) return;
      setState(() {
        _userId   = user.uid;
        _token    = token ?? '';
        _deviceId = deviceId;
      });

      // 3) Mostrar diálogo de bienvenida solo 1 vez
      if (!_welcomeShown) {
        _showWelcomeDialog();
        _welcomeShown = true;
      }

      // 4) Carga inicial de TODO el historial
      await _historialProv.loadAll(
        userId:   _userId,
        token:    _token,
        deviceId: _deviceId,
      );

      // 5) Iniciar polling automático
      _historialProv.startAutoRefresh(
        userId: _userId,
        token: _token,
        deviceId: _deviceId,
      );
    });
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
      builder: (BuildContext dialogContext) {                // 👈 usa aquí dialogContext
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
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
              const Icon(Icons.build_rounded,
                  size: 60, color: Color(0xFF84090D)),
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
              onPressed: () {
                // 👇 navega o cierra usando dialogContext
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF84090D),
                backgroundColor: const Color(0xFFE8E8E8),
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(
                    color: Color(0xFFE8E8E8), width: 1),
              ),
              child: Text("Comenzar", style: MyTextStyles.linkTextStyle),
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
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(18),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: MyTextStyles.tabTextStyle,
                    unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(width: 3, color: Color(0xFF84090D)),
                      insets: EdgeInsets.symmetric(horizontal: 20),
                    ),
                    tabs: [
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.task_alt, color: Colors.black)),
                        text: 'Disponibles (${prov.availableCount})',
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.local_offer, color: Colors.black)),
                                if (prov.offerServiceCount > 0)
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF84090D),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        prov.offerServiceCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Ofertados'),
                          ],
                        ),
                      ),
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.assignment_ind, color: Colors.black)),
                        text: 'Asignados (${prov.inProgressCount})',
                      ),
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.check_circle, color: Colors.black)),
                        text: 'Completados (${prov.completedCount})',
                      ),
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.cancel, color: Colors.black)),
                        text: 'Cancelados (${prov.cancelledCount})',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Center(
                        child: Text('Historial', style: MyTextStyles.buttonTextStyle3),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _ServiceListTab(
                            status: 'available',
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
                            isLoading: prov.isLoading,
                          ),
                          _ServiceListTab(
                            status: 'offer',
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
                            isLoading: prov.isLoading,
                          ),
                          _ServiceListTab(
                            status: 'in_progress',
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
                            isLoading: prov.isLoading,
                          ),
                          _ServiceListTab(
                            status: 'completed',
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
                            isLoading: prov.isLoading,
                          ),
                          _ServiceListTab(
                            status: 'cancelled',
                            userId: _userId,
                            userData: widget.userData,
                            apiService: ApiService(),
                            apiService2: ApiService2(),
                            onRefresh: () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
                            isLoading: prov.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (prov.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando servicios...', style: TextStyle(fontSize: 16, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: prov.isLoading
                  ? null
                  : () => prov.refresh(userId: _userId, token: _token, deviceId: _deviceId),
              label: const Text('Actualizar'),
              icon: const Icon(Icons.refresh),
              backgroundColor: const Color(0xFF84090D),
              foregroundColor: Colors.white,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }
}

/// Un widget por pestaña, que conserva scroll y no se rebuild innecesariamente
class _ServiceListTab extends StatefulWidget {
  final String status;
  final String userId;
  final UserData userData;
  final ApiService apiService;
  final ApiService2 apiService2;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  const _ServiceListTab({
    required this.status,
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (prov.hasMore(widget.status) && !prov.isLoadingMore(widget.status)) {
        prov.loadMore(
          status: widget.status,
          userId: widget.userId,
          token: '', // Puedes pasar el token real si lo necesitas
          deviceId: '', // Puedes pasar el deviceId real si lo necesitas
        );
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prov = context.watch<HistorialProvider>();
    final list = prov.list(widget.status);
    final isLoadingMore = prov.isLoadingMore(widget.status);
    final hasMore = prov.hasMore(widget.status);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Builder(
        builder: (context) {
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
          if (list.isEmpty && !widget.isLoading) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Center(
                  child: Text(
                    'No hay servicios.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            );
          }

          // Skeleton loader
          if (widget.isLoading && list.isEmpty) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.grey[300],
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

          final w = MediaQuery.of(context).size.width;
          final h = MediaQuery.of(context).size.height;

          Widget listWidget;
          switch (widget.status) {
            case 'available':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.buildServiceListAvailable(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
                widget.apiService2,
              );
              break;
            case 'offer':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.buildOfferList(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
                widget.apiService2,
              );
              break;
            case 'in_progress':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.inProgressList(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
                widget.apiService2,
              );
              break;
            case 'completed':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.buildServiceListComplete(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
                widget.apiService2,
              );
              break;
            case 'cancelled':
              listWidget = ServiceListBuilder.buildServiceListCancelled(
                list,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
                widget.apiService2,
              );
              break;
            default:
              listWidget = const SizedBox.shrink();
          }

          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                      hasMore &&
                      !isLoadingMore) {
                    prov.loadMore(
                      status: widget.status,
                      userId: widget.userId,
                      token: '', // Puedes pasar el token real si lo necesitas
                      deviceId: '', // Puedes pasar el deviceId real si lo necesitas
                    );
                  }
                  return false;
                },
                child: listWidget,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Cargando más...', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}