import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io'; // Para manejar archivos locales
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:socio/Screens/commentScreen.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/authUtils.dart';
import 'package:socio/Utils/service_details_card.dart';
import 'package:socio/Utils/styles.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socio/Controller/imagePreview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:socio/constans/service_constans.dart';
import 'package:socio/models/offer_models.dart';
import 'package:socio/models/serviceRequest_models.dart';
import 'package:socio/provider/service_partner_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  State<ServiceFormWithTimelineSocio> createState() => _ServiceFormWithTimelineSocioState();
}

class _ServiceFormWithTimelineSocioState extends State<ServiceFormWithTimelineSocio> 
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
                        border: Border.all(color: AppColors.primary, width: 2.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Estado
                          _ServiceDetailsSection(
                            status: _statusName(currentStatus),
                            date: serviceData.date,
                            time: serviceData.time,
                            serviceTypes: serviceData.expertises.map((e) => e.name?.toString() ?? e.toString()).toList(),
                            location: initialPos,
                            address: serviceData.location['address'],
                          ),
                          const SizedBox(height: 16),

                          // ── Descripción
                          _DescriptionSection(description: serviceData.description),
                          const SizedBox(height: 16),

                          // ── Carrusel de imágenes
                          if (serviceData.images.isNotEmpty)
                            _ImagesCarouselSection(images: serviceData.images),
                          const SizedBox(height: 16),

                          // ── Expertises requeridas
                          if (serviceData.expertises.isNotEmpty)
                            _ExpertisesSection(expertises: serviceData.expertises),
                          const SizedBox(height: 16),

                          // ── Mapa (marca la ubicación del cliente)
                          _LocationMapSection(location: initialPos),
                          const SizedBox(height: 16),

                          // ── Desglose financiero para servicios completados
                          if (currentStatus == ServiceStatus.completed)
                            _FinancialBreakdownSection(
                              workerId: widget.workerId,
                              workerOfferedPrice: workerOfferedPrice,
                              serviceData: serviceData,
                            ),

                          // ── Botones de acción según estado
                          _ActionButtonsSection(
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS PRIVADOS
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceDetailsSection extends StatelessWidget {
  final String status;
  final String date;
  final String time;
  final List<String> serviceTypes;
  final LatLng location;
  final String? address;

  const _ServiceDetailsSection({
    required this.status,
    required this.date,
    required this.time,
    required this.serviceTypes,
    required this.location,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DEL SERVICIO',
                      style: GoogleFonts.karla(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Información de fecha y hora
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue[600]!,
                  title: 'Fecha',
                  value: date,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time,
                  iconColor: Colors.orange[600]!,
                  title: 'Hora',
                  value: time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tipos de servicio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.build,
                    color: Colors.purple[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tipos de Servicio',
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serviceTypes.map((type) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF84090D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF84090D).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.karla(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84090D),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.karla(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Colors.blue[600]!;
      case 'ofertado':
        return Colors.orange[600]!;
      case 'en curso':
        return Colors.amber[600]!;
      case 'completado':
        return Colors.green[600]!;
      case 'cancelado':
        return Colors.red[600]!;
      case 'bloqueado':
        return Colors.grey[600]!;
      default:
        return Color(0xFF84090D);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Icons.check_circle;
      case 'ofertado':
        return Icons.local_offer;
      case 'en curso':
        return Icons.work;
      case 'completado':
        return Icons.task_alt;
      case 'cancelado':
        return Icons.cancel;
      case 'bloqueado':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.blue[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.blue[600]!,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'DESCRIPCIÓN DEL SERVICIO',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Text(
              description,
              style: GoogleFonts.karla(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesCarouselSection extends StatelessWidget {
  final List<String> images;

  const _ImagesCarouselSection({required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.purple[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Colors.purple[600]!,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'GALERÍA DE IMÁGENES',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 220.0,
              enlargeCenterPage: true,
              autoPlay: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.6,
            ),
            items: images.map((url) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewer(imageUrl: url),
                        ),
                      );
                    },
                    child: Hero(
                      tag: url,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF84090D)),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ExpertisesSection extends StatelessWidget {
  final List<dynamic> expertises;

  const _ExpertisesSection({required this.expertises});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.teal[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.category,
                  color: Colors.teal[600]!,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'TIPOS DE SERVICIO REQUERIDOS',
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: expertises.map((e) {
              String name;
              if (e is Map && e.containsKey('name')) {
                name = e['name'].toString();
              } else if (e is dynamic && e.name != null) {
                name = e.name.toString();
              } else {
                name = e.toString();
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF84090D).withOpacity(0.1),
                      Color(0xFF84090D).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF84090D).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF84090D).withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF84090D),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.karla(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF84090D),
                        ),
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LocationMapSection extends StatelessWidget {
  final LatLng location;

  const _LocationMapSection({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.red[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red[600]!,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'UBICACIÓN DEL TRABAJO',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('serviceLocation'),
                    position: location,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(
                      title: 'Ubicación del trabajo',
                      snippet: 'Aquí se realizará el servicio',
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.red[600],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta es la ubicación exacta donde se realizará el trabajo',
                    style: GoogleFonts.karla(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialBreakdownSection extends StatelessWidget {
  final String workerId;
  final double? workerOfferedPrice;
  final ServiceRequestModel serviceData;

  const _FinancialBreakdownSection({
    required this.workerId,
    required this.workerOfferedPrice,
    required this.serviceData,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Imprimir información para entender qué datos llegan
    print('=== DEBUG FINANCIAL BREAKDOWN ===');
    print('workerId: $workerId');
    print('workerOfferedPrice: $workerOfferedPrice');
    print('serviceData: ${serviceData != null ? 'EXISTS' : 'NULL'}');
    if (serviceData != null) {
      print('rawOffers length: ${serviceData.rawOffers.length}');
      print('rawOffers: ${serviceData.rawOffers}');
    }
    
    // Obtener el precio ofertado del trabajador desde las ofertas del servicio
    double? offeredPrice;
    
    if (workerOfferedPrice != null) {
      offeredPrice = workerOfferedPrice;
      print('Using workerOfferedPrice: $offeredPrice');
    } else if (serviceData != null) {
      // Buscar en las ofertas del servicio
      final workerOffer = serviceData.rawOffers.firstWhere(
        (offer) => offer['workerId'] == workerId,
        orElse: () => <String, dynamic>{},
      );
      
      print('Found workerOffer: $workerOffer');
      
      if (workerOffer.isNotEmpty) {
        final raw = workerOffer['offeredPrice'];
        offeredPrice = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
        print('Using rawOffers price: $offeredPrice');
      }
    }
    
    print('Final offeredPrice: $offeredPrice');
    print('=== END DEBUG ===');
    
    // Si no hay precio ofertado, no mostrar el desglose
    if (offeredPrice == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFFDE8E9),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Color(0xFF84090D), width: 2.0),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF84090D)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Información financiera no disponible para este servicio',
                style: TextStyle(
                  color: Color(0xFF84090D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Calcular comisión (10%) y costos extras
    final commission = offeredPrice * 0.10;
    const extraCosts = 3.0;
    final totalClientPays = offeredPrice + extraCosts; // Cliente paga precio + extras
    final netIncome = offeredPrice - commission; // Trabajador recibe precio - comisión
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFFFDE8E9), // Fondo rojo claro
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Color(0xFF84090D), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono de alerta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Color(0xFF84090D),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN FINANCIERO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Servicio completado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF84090D).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contenido del desglose
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Color(0xFF84090D).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Precio ofertado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio ofertado:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\Bs${offeredPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Costos extras (se suman)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ Costos extras:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '+\Bs${extraCosts.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Total que paga el cliente
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total cliente paga:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '\Bs${totalClientPays.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF84090D), thickness: 1),
                
                // Comisión (se resta del precio ofertado)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comisión (10%):',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '-\Bs${commission.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Ingreso neto
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INGRESO NETO:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF84090D),
                      ),
                    ),
                    Text(
                      '\Bs${netIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Mensaje informativo
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Color(0xFF84090D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Color(0xFF84090D).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF84090D),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El cliente paga Bs${totalClientPays.toStringAsFixed(2)} (precio + extras). Tu ingreso neto es Bs${netIncome.toStringAsFixed(2)} (precio - comisión).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF84090D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  final BuildContext context;
  final ServicePartnerProvider prov;
  final ServiceRequestModel serviceData;
  final String workerId;
  final double? workerOfferedPrice;
  final int commentCount;
  final bool hasExistingProposal;

  const _ActionButtonsSection({
    required this.context,
    required this.prov,
    required this.serviceData,
    required this.workerId,
    required this.workerOfferedPrice,
    required this.commentCount,
    required this.hasExistingProposal,
  });

  @override
  Widget build(BuildContext context) {
    final status = prov.currentStatus;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFF84090D).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF84090D).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.indigo[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: Colors.indigo[600]!,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'ACCIONES DISPONIBLES',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 1) Cuando el servicio está disponible (no ofertado aún)
          if (status == ServiceStatus.available) ...[
            _buildModernButton(
              onPressed: hasExistingProposal ? null : () => _showProposalDialog(context, prov),
              icon: Icons.add_business,
              label: hasExistingProposal ? 'Propuesta Enviada' : 'Enviar Propuesta',
              backgroundColor: hasExistingProposal ? Colors.grey[300]! : Color(0xFF84090D),
              textColor: hasExistingProposal ? Colors.grey[600]! : Colors.white,
              iconColor: hasExistingProposal ? Colors.grey[600]! : Colors.white,
            ),
            const SizedBox(height: 16),
            _buildModernButton(
              onPressed: () => _showCommentsModal(context, prov),
              icon: Icons.comment,
              label: 'Comentarios ($commentCount)',
              backgroundColor: Colors.black87,
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
          ],

          // 2) Cuando el servicio está "in_progress" (en curso)
          if (status == ServiceStatus.inProgress) ...[
            // Botones principales en columna para evitar overflow
            Column(
              children: [
                _buildModernButton(
                  onPressed: () => _showUploadCompletionDialog(context, prov),
                  icon: Icons.work,
                  label: "Completar trabajo",
                  backgroundColor: Colors.green[600]!,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 12),
                _buildModernButton(
                  onPressed: () => _showNoParticipationDialog(context, prov),
                  icon: Icons.dangerous,
                  label: "No Participar",
                  backgroundColor: Colors.red[600]!,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModernButton(
              onPressed: () async {
                final url = prov.getWhatsAppUrl();
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
                    );
                  }
                } else if (prov.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(prov.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icons.chat,
              label: "Contactar por WhatsApp",
              backgroundColor: Color(0xFF25D366),
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
          ],

          // 3) Cuando el servicio ya está completado
          if (status == ServiceStatus.completed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este trabajo ha sido completado exitosamente.',
                      style: GoogleFonts.karla(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4) Cancelado o Bloqueado
          if (status == ServiceStatus.cancelled || status == ServiceStatus.blocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status == ServiceStatus.cancelled ? Colors.red[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == ServiceStatus.cancelled ? Colors.red[200]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == ServiceStatus.cancelled ? Icons.cancel : Icons.block,
                    color: status == ServiceStatus.cancelled ? Colors.red[600] : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status == ServiceStatus.cancelled
                          ? 'Este trabajo ha sido cancelado.'
                          : 'No participarás en este trabajo.',
                      style: GoogleFonts.karla(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == ServiceStatus.cancelled ? Colors.red[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.karla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProposalDialog(BuildContext context, ServicePartnerProvider prov) {
    if (prov.hasExistingProposal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya enviaste propuesta para este servicio')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        bool _sending = false;
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF84090D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_business, color: Color(0xFF84090D)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enviar Propuesta',
                    style: GoogleFonts.karla(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84090D),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingrese el precio a ofertar:',
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: prov.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Precio Ofertado",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF84090D), width: 2),
                      ),
                      prefixIcon: Icon(Icons.attach_money, color: Color(0xFF84090D)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _sending ? null : () => Navigator.of(ctx).pop(),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.karla(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _sending ? null : () async {
                    setSt(() => _sending = true);
                    final success = await prov.sendProposal();
                    setSt(() => _sending = false);

                    if (success) {
                      Navigator.of(ctx).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al enviar propuesta')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF84090D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Enviar",
                          style: GoogleFonts.karla(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNoParticipationDialog(BuildContext context, ServicePartnerProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dangerous, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text(
                'No Participar',
                style: GoogleFonts.karla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que no quieres participar en este trabajo?',
            style: GoogleFonts.karla(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "Cancelar",
                style: GoogleFonts.karla(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await prov.blockParticipation();
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Confirmar",
                style: GoogleFonts.karla(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadCompletionDialog(BuildContext context, ServicePartnerProvider prov) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool _uploading = false;
        XFile? _picked;
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.work, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Completar Trabajo',
                    style: GoogleFonts.karla(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sube una foto del trabajo terminado para confirmar la finalización del servicio.',
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_picked == null)
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: InkWell(
                        onTap: () async {
                          _picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                          setSt(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey[600], size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Seleccionar imagen',
                              style: GoogleFonts.karla(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_picked!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (_picked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Imagen seleccionada',
                        style: GoogleFonts.karla(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.karla(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (_picked == null || _uploading)
                      ? null
                      : () async {
                    setSt(() => _uploading = true);
                    final token = await AuthUtils.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: usuario no autenticado')),
                      );
                      setSt(() => _uploading = false);
                      return;
                    }
                    try {
                      await prov.submitCompletionImage(_picked!.path);
                    } catch (_) {}
                    setSt(() => _uploading = false);
                    Navigator.of(ctx2).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Confirmar',
                          style: GoogleFonts.karla(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommentsModal(BuildContext context, ServicePartnerProvider provider) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return CommentsBottomSheet(provider: provider);
          },
    );
  }
}