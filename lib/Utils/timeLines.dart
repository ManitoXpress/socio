import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../Screens/commentScreen.dart';
import '../ServiceResponse/get.dart';
import '../ServiceResponse/post.dart';

import '../ServiceResponse/requestStatus.dart';
import '../ServiceResponse/requestUserData.dart';
import '../constans/service_constans.dart';

import '../models/offer_models.dart';
import '../models/serviceRequest_models.dart';
import '../provider/service_partner_provider.dart';

import 'styles.dart';
import 'timeline_widgets/action_buttons_section.dart';
import 'timeline_widgets/description_section.dart';
import 'timeline_widgets/expertises_section.dart';
import 'timeline_widgets/financial_breakdown_section.dart';
import 'timeline_widgets/images_carousel_section.dart';
import 'timeline_widgets/location_map_section.dart';
import 'timeline_widgets/service_details_section.dart';

class ServiceFormWithTimelineSocio extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final OfferModel offer;
  final UserData userData;
  final String workerId;
  final List<OfferModel> offers;
  final ApiService apiService;
  final ApiService2 apiService2;
  final String userId;
  final String displayName;

  const ServiceFormWithTimelineSocio({
    Key? key,
    required this.serviceRequest,
    required this.offer,
    required this.userData,
    required this.workerId,
    required this.offers,
    required this.apiService,
    required this.apiService2,
    required this.userId,
    required this.displayName,
  }) : super(key: key);

  @override
  State<ServiceFormWithTimelineSocio> createState() =>
      _ServiceFormWithTimelineSocioState();
}

class _ServiceFormWithTimelineSocioState
    extends State<ServiceFormWithTimelineSocio>
    with SingleTickerProviderStateMixin, RestorationMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;
  late AnimationController _animationController;
  late Animation<Offset> _bounceAnimation;
  final RestorableDouble _scrollOffset = RestorableDouble(0.0);

  @override
  String? get restorationId => 'service_timeline_socio_screen';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_saveScrollOffset);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0.25),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_saveScrollOffset);
    _scrollController.dispose();
    _animationController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_scrollOffset, 'timeline_socio_scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollOffset.value > 0.0) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  void _saveScrollOffset() {
    if (_scrollController.hasClients) {
      _scrollOffset.value = _scrollController.offset;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 10) {
      if (_showScrollIndicator) {
        setState(() {
          _showScrollIndicator = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServicePartnerProvider>(
      create: (_) {
        final prov = ServicePartnerProvider(
          serviceRequest: widget.serviceRequest,
          offer: widget.offer,
          userData: widget.userData,
          workerId: widget.workerId,
          offers: widget.offers,
          apiService: widget.apiService,
          apiService2: widget.apiService2,
          userId: widget.userId,
        );
        return prov;
      },
      child: Consumer<ServicePartnerProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (prov.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Detalles del Servicio',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
              ),
              body: Center(
                child: Text(
                  prov.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final serviceData = prov.serviceData!;
          final comentarios = prov.comments;
          final currentStatus = prov.currentStatus;
          final LatLng initialPos = prov.initialPosition;
          final workerOfferedPrice = prov.workerOfferedPrice;
          final hasExistingProposal = prov.hasExistingProposal;

          // Define tu API KEY aquí (reemplaza por la tuya real)
          const String googleMapsApiKey = 'AIzaSyBRj4mtlIsxekbQOnGcwWSWuNVaGi3-hIM';

          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Detalles del Servicio',
                style: MyTextStyles.buttonTextStyle,
              ),
              backgroundColor: AppColors.primary,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: AppColors.primary, width: 2.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Estado
                          ServiceDetailsSection(
                            status: _statusName(currentStatus),
                            date: serviceData.date,
                            time: serviceData.time,
                            serviceTypes: serviceData.expertises
                                .map((e) => e.name?.toString() ?? e.toString())
                                .toList(),
                            location: initialPos,
                            address: serviceData.location['address'],
                          ),
                          const SizedBox(height: 16),

                          // ── Descripción
                          DescriptionSection(
                              description: serviceData.description),
                          const SizedBox(height: 16),

                          // ── Carrusel de imágenes
                          if (serviceData.images.isNotEmpty)
                            ImagesCarouselSection(images: serviceData.images),
                          const SizedBox(height: 16),

                          // ── Expertises requeridas
                          if (serviceData.expertises.isNotEmpty)
                            ExpertisesSection(
                                expertises: serviceData.expertises),
                          const SizedBox(height: 16),

                          // ── Mapa (marca la ubicación del cliente)
                          LocationMapSection(
                            location: initialPos,
                            status: Status(id: currentStatus, name: Status.getNameById(currentStatus)),
                          ),
                          const SizedBox(height: 16),

                          // ── Desglose financiero para servicios completados
                          if (currentStatus == ServiceStatus.completed)
                            FinancialBreakdownSection(
                              workerId: widget.workerId,
                              workerOfferedPrice: workerOfferedPrice,
                              serviceData: serviceData,
                            ),

                          // ── Botones de acción según estado
                          ActionButtonsSection(
                            context: context,
                            prov: prov,
                            serviceData: serviceData,
                            workerId: widget.workerId,
                            workerOfferedPrice: workerOfferedPrice,
                            commentCount: comentarios.length,
                            hasExistingProposal: hasExistingProposal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Flecha animada de rebote
                if (_showScrollIndicator)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showScrollIndicator ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _bounceAnimation,
                                child: child,
                              );
                            },
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.grey[600],
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusName(String status) {
    const statusNames = {
      ServiceStatus.available: 'Disponible',
      ServiceStatus.offer: 'Ofertado',
      ServiceStatus.inProgress: 'En curso',
      ServiceStatus.completed: 'Completado',
      ServiceStatus.cancelled: 'Cancelado',
      ServiceStatus.blocked: 'Bloqueado',
    };
    return statusNames[status] ?? 'Desconocido';
  }
}
