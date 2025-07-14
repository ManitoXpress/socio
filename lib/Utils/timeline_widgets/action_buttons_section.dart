import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:socio/constans/service_constans.dart';

import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../Screens/commentScreen.dart';

import '../../models/serviceRequest_models.dart';
import '../../provider/service_partner_provider.dart';
import '../authUtils.dart';

class ActionButtonsSection extends StatelessWidget {
  final BuildContext context;
  final ServicePartnerProvider prov;
  final ServiceRequestModel serviceData;
  final String workerId;
  final double? workerOfferedPrice;
  final int commentCount;
  final bool hasExistingProposal;

  const ActionButtonsSection({
    Key? key,
    required this.context,
    required this.prov,
    required this.serviceData,
    required this.workerId,
    required this.workerOfferedPrice,
    required this.commentCount,
    required this.hasExistingProposal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = prov.currentStatus;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                  color: const Color(0xFF830A09)!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: const Color(0xFF830A09)!,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Acciones Disponibles',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF830A09),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (status == ServiceStatus.available) ...[
            _buildModernButton(
              onPressed: hasExistingProposal
                  ? null
                  : () => _showProposalDialog(context, prov),
              icon: Icons.add_business,
              label: hasExistingProposal
                  ? 'Propuesta Enviada'
                  : 'Enviar Propuesta',
              backgroundColor: hasExistingProposal
                  ? Colors.grey[300]!
                  : const Color(0xFF84090D),
              textColor: hasExistingProposal ? Colors.grey[600]! : Colors.white,
              iconColor: hasExistingProposal ? Colors.grey[600]! : Colors.white,
            ),
            const SizedBox(height: 16),
            _buildModernButton(
              onPressed: () => _showCommentsModal(context, prov),
              icon: Icons.chat_bubble_rounded,
              label: 'Comentarios ($commentCount)',
              backgroundColor: Colors.black87,
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
          ],
          if (status == ServiceStatus.inProgress) ...[
            Column(
              children: [
                _buildModernButton(
                  onPressed: () => _showUploadCompletionDialog(context, prov),
                  icon: Icons.work,
                  label: "Completar trabajo",
                  backgroundColor: const Color(0xFF1A819A)!,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 12),
                _buildModernButton(
                  onPressed: () => _showNoParticipationDialog(context, prov),
                  icon: Icons.dangerous,
                  label: "No Participar",
                  backgroundColor: const Color(0xFF830A09)!,
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
                      const SnackBar(
                          content: Text('No se pudo abrir WhatsApp.')),
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
              backgroundColor: const Color(0xFF25D366),
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
          ],
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
          if (status == ServiceStatus.cancelled ||
              status == ServiceStatus.blocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status == ServiceStatus.cancelled
                    ? Colors.red[50]
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == ServiceStatus.cancelled
                      ? Colors.red[200]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == ServiceStatus.cancelled
                        ? Icons.cancel
                        : Icons.block,
                    color: status == ServiceStatus.cancelled
                        ? Colors.red[600]
                        : Colors.grey[600],
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
                        color: status == ServiceStatus.cancelled
                            ? Colors.red[700]
                            : Colors.grey[700],
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
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
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
            borderRadius: BorderRadius.circular(12),
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
        const SnackBar(
            content: Text('Ya enviaste propuesta para este servicio')),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84090D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_business,
                        color: Color(0xFF84090D)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enviar Propuesta',
                    style: GoogleFonts.karla(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF84090D),
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
                      color: const Color(0xFF000000),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF000000), width: 2),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Bs.',
                          style: TextStyle(
                            color: Color(0xFF84090D),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84090D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sending ? null : () => Navigator.of(ctx).pop(),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.karla(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
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
                              const SnackBar(
                                  content: Text('Error al enviar propuesta')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84090D),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showNoParticipationDialog(
      BuildContext context, ServicePartnerProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF830A09).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dangerous, color: Color(0xFF830A09)),
              ),
              const SizedBox(width: 12),
              Text(
                'No Participar',
                style: GoogleFonts.karla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF830A09),
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
                backgroundColor: const Color(0xFF830A09),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A819A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.work,
                        color: const Color(0xFF1A819A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Completar Trabajo',
                    style: GoogleFonts.karla(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A819A),
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
                        border: Border.all(
                            color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: InkWell(
                        onTap: () async {
                          _picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery, imageQuality: 80);
                          setSt(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                color: Colors.grey[600], size: 32),
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
                          color: const Color(0xFF1A819A),
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
                              const SnackBar(
                                  content:
                                      Text('Error: usuario no autenticado')),
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
                    backgroundColor: const Color(0xFF1A819A),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showCommentsModal(
      BuildContext context, ServicePartnerProvider provider) {
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
