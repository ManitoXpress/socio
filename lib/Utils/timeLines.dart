
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
import 'package:socio/Utils/styles.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socio/Controller/imagePreview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:socio/constans/service_constans.dart';
import 'package:socio/models/offer_models.dart';
import 'package:socio/models/serviceRequest_models.dart';
import 'package:socio/provider/service_partner_provider.dart';
import 'package:url_launcher/url_launcher.dart';
class ServiceFormWithTimelineSocio extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServicePartnerProvider>(
      create: (_) {
        final prov = ServicePartnerProvider(
          serviceRequest: serviceRequest,
          offer: offer,
          userData: userData,
          workerId: workerId,
          offers: offers,
          apiService: apiService,
          apiService2: apiService2,
          userId: userId,
        );
        // El constructor de ServicePartnerProvider ya llama a _init()
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
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                      Text(
                        'Estado: ${_statusName(currentStatus)}',
                        style: MyTextStyles.inputTextStyle6,
                      ),
                      const SizedBox(height: 8),

                      // ── Fecha y Hora
                      Text(
                        'Fecha: ${serviceData.date}',
                        style: MyTextStyles.inputTextStyle1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hora: ${serviceData.time}',
                        style: MyTextStyles.inputTextStyle1,
                      ),
                      const SizedBox(height: 16),

                      // ── Descripción
                      _buildRichText('Descripción:', serviceData.description),
                      const SizedBox(height: 16),

                      // ── Carrusel de imágenes
                      if (serviceData.images.isNotEmpty)
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200.0,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 500),
                            viewportFraction: 0.5,
                          ),
                          items: serviceData.images.map((url) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ImageViewer(imageUrl: url),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: url,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // ── Expertises requeridas
                      if (serviceData.expertises.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: serviceData.expertises.map((e) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                'Tipo de servicio: ${e.name}',
                                style: MyTextStyles.inputTextStyle6,
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // ── Mapa (marca la ubicación del cliente)
                      Text(
                        'Ubicación del trabajo:',
                        style: MyTextStyles.inputTextStyle6,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: initialPos,
                              zoom: 14.0,
                            ),
                            markers: {
                              Marker(
                                  markerId: const MarkerId('serviceLocation'),
                                  position: initialPos),
                            },
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Botones de acción según estado
                      _buildActionButtons(
                        context,
                        prov,
                        serviceData,
                        workerId,
                        workerOfferedPrice,
                        comentarios.length,
                        hasExistingProposal,
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildRichText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Karla',
            color: AppColors.primary,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Karla',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ServicePartnerProvider prov,
    ServiceRequestModel serviceData,
    String selectedWorkerId,
    double? offeredPrice,
    int commentCount,
    bool hasExistingProposal,
  ) {
    final status = prov.currentStatus;

    // 1) Cuando el servicio está disponible (no ofertado aún)
    if (status == ServiceStatus.available) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: hasExistingProposal
                ? null
                : () => _showProposalDialog(context, prov),
            icon: Icon(Icons.add_business, color: AppColors.primary),
            label: Text(
              hasExistingProposal ? 'Propuesta Enviada' : 'Enviar Propuesta',
              style: GoogleFonts.karla(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _showCommentsModal(context, prov),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: MediaQuery.of(context).size.width * 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.comment, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Comentarios ($commentCount)',
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 2) Cuando el servicio está “in_progress” (en curso)
    else if (status == ServiceStatus.inProgress) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showUploadCompletionDialog(context, prov),
                icon: Icon(Icons.work, color: AppColors.primary),
                label: Text(
                  "Completar trabajo",
                  style: GoogleFonts.karla(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNoParticipationDialog(context, prov),
                icon: Icon(Icons.dangerous, color: Colors.red),
                label: Text(
                  "No Participar",
                  style: GoogleFonts.karla(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
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
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              "WhatsApp",
              style: TextStyle(
                fontFamily: 'Karla',
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsappGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      );
    }

    // 3) Cuando el servicio ya está completado
    else if (status == ServiceStatus.completed) {
      return Center(
        child: Text(
          'Este trabajo ha sido completado.',
          style: MyTextStyles.inputTextStyle6,
        ),
      );
    }

    // 4) Cancelado o Bloqueado
    else if (status == ServiceStatus.cancelled || status == ServiceStatus.blocked) {
      return Center(
        child: Text(
          status == ServiceStatus.cancelled
              ? 'Este trabajo ha sido cancelado.'
              : 'No participarás en este trabajo.',
          style: MyTextStyles.inputTextStyle6,
        ),
      );
    }

    // Otros estados (offer, pending, etc), opcionalmente agregar botones
    return const SizedBox.shrink();
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
              title: Text('Enviar Propuesta', style: MyTextStyles.linkTextStyle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingrese el precio a ofertar:', style: MyTextStyles.ButtonTextStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prov.priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Precio Ofertado",
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (_sending)
                        const Padding(
                          padding: EdgeInsets.only(left: 12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: _sending ? null : () => Navigator.of(ctx).pop(),
                  icon: Icon(Icons.cancel, color: AppColors.primary),
                  label: Text("Cancelar",
                      style: GoogleFonts.karla(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      )),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sending
                      ? null
                      : () async {
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
                  icon: Icon(Icons.check_circle, color: AppColors.primary),
                  label: Text("Enviar Propuesta",
                      style: GoogleFonts.karla(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      )),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.primary),
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
          title: Text('No Participar en el Trabajo', style: MyTextStyles.linkTextStyle),
          content: Text('¿Estás seguro de que no quieres participar?',
              style: MyTextStyles.ButtonTextStyle),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: Icon(Icons.dangerous, color: AppColors.primary),
              label: Text("Cancelar",
                  style: GoogleFonts.karla(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  )),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: AppColors.primary)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await prov.blockParticipation();
                Navigator.of(ctx).pop();
              },
              icon: Icon(Icons.check_circle, color: AppColors.primary),
              label: Text("Confirmar No Participar",
                  style: GoogleFonts.karla(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  )),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadCompletionDialog(
      BuildContext context, ServicePartnerProvider prov) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool _uploading = false;
        XFile? _picked;
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            return AlertDialog(
              title: Text('Subir foto de trabajo terminado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_picked == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('Seleccionar imagen'),
                      onPressed: () async {
                        _picked = await ImagePicker()
                            .pickImage(source: ImageSource.gallery, imageQuality: 80);
                        setSt(() {});
                      },
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_picked!.path),
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx2).pop(),
                  child: const Text('Cancelar'),
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

                          // 1) Subir la imagen al backend
                          try {
                            await prov.submitCompletionImage();
                          } catch (_) {
                            // ServicePartnerProvider ya maneja errores internamente
                          }
                          setSt(() => _uploading = false);
                          Navigator.of(ctx2).pop();
                        },
                  child: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
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

