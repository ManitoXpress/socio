import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/Controller/inProgressFetcher.dart';
import 'package:socio/Controller/offerFetcher.dart';
import 'package:socio/Controller/serviceCancelled.dart';
import 'package:socio/Controller/serviceComplete.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestServiceType.dart';
import 'package:socio/ServiceResponse/requestStatus.dart';
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
      builder: (_) => AlertDialog(
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
            const Icon(Icons.build_rounded,
                size: 60, color: Color(0xFF84090D)),
            const SizedBox(height: 20),
            Text(
              '🔔 ¡Atención, socios! 🚀 ¡La app Manito Xpress arranca el 19 de abril! Prepárate para recibir servicios. 💪',
              style: MyTextStyles.formServiceTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 5) Abrimos el provider UNA sola vez con .value
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
                    labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: MyTextStyles.tabTextStyle,
                    unselectedLabelStyle:
                    MyTextStyles.unselectedTabTextStyle,
                    indicator: const UnderlineTabIndicator(
                      borderSide:
                      BorderSide(width: 3, color: Color(0xFF84090D)),
                      insets:
                      EdgeInsets.symmetric(horizontal: 20),
                    ),
                    tabs: [
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.task_alt,
                                color: Colors.black)),
                        text:
                        'Disponibles (${prov.availableCount})',
                      ),
                      Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Padding(
                                    padding:
                                    EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.local_offer,
                                        color: Colors.black)),
                                if (prov.offerServiceCount > 0)
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      padding:
                                      const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFF84090D),
                                        borderRadius:
                                        BorderRadius.circular(
                                            12),
                                      ),
                                      constraints:
                                      const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        prov.offerServiceCount
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10),
                                        textAlign:
                                        TextAlign.center,
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
                            child: Icon(Icons.assignment_ind,
                                color: Colors.black)),
                        text:
                        'Asignados (${prov.inProgressCount})',
                      ),
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.check_circle,
                                color: Colors.black)),
                        text:
                        'Completados (${prov.completedCount})',
                      ),
                      Tab(
                        icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.cancel,
                                color: Colors.black)),
                        text:
                        'Cancelados (${prov.cancelledCount})',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Text('Historial',
                          style: MyTextStyles.buttonTextStyle3),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Color(0xFF84090D)),
                        onPressed: () => prov.refresh(
                            userId: _userId,
                            token: _token,
                            deviceId: _deviceId),
                      ),
                    ],
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
                      ),
                      _ServiceListTab(
                        status: 'offer',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'in_progress',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'completed',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'cancelled',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  const _ServiceListTab({
    required this.status,
    required this.userId,
    required this.userData,
    required this.apiService,
    required this.apiService2,
    Key? key,
  }) : super(key: key);

  @override
  State<_ServiceListTab> createState() => _ServiceListTabState();
}

class _ServiceListTabState extends State<_ServiceListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prov = context.watch<HistorialProvider>();
    final list = prov.list(widget.status);

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorMessage != null) {
      return Center(child: Text('Error: ${prov.errorMessage}'));
    }
    if (list.isEmpty) {
      return const Center(child: Text('No hay servicios.'));
    }

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    switch (widget.status) {
      case 'available':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.buildServiceListAvailable(
          list,
          offers,
          w, h,
          widget.userId,
          widget.userData,
          widget.apiService,
          widget.apiService2,
        );
      case 'offer':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.buildOfferList(
          list,
          offers,
          w, h,
          widget.userId,
          widget.userData,
          widget.apiService,
          widget.apiService2,
        );
      case 'in_progress':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.in_progressList(
          list,
          offers,
          w, h,
          widget.userId,
          widget.userData,
          widget.apiService,
          widget.apiService2,
        );
      case 'completed':
        return ServiceListBuilder.buildServiceListComplete(
          list,
          w, h,
          widget.userId,
          widget.userData,
          widget.apiService,
          widget.apiService2,
        );
      case 'cancelled':
        return ServiceListBuilder.buildServiceListCancelled(
          list,
          w, h,
          widget.userId,
          widget.userData,
          widget.apiService,
          widget.apiService2,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}