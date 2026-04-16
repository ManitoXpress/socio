import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:provider/provider.dart';
import '../provider/providerImage.dart';

/// Paso combinado: captura frente Y reverso del carnet en una sola pantalla
class IdDocumentCombinedStep extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String frontPath, String backPath) onImagesSelected;
  final void Function() onNextStep;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  final String idDocumentImagePath;
  final String idDocumentImagePath2;

  const IdDocumentCombinedStep({
    Key? key,
    required this.registrationController,
    required this.onImagesSelected,
    required this.onNextStep,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.idDocumentImagePath,
    required this.idDocumentImagePath2,
  }) : super(key: key);

  @override
  _IdDocumentCombinedStepState createState() =>
      _IdDocumentCombinedStepState();
}

class _IdDocumentCombinedStepState extends State<IdDocumentCombinedStep> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _frontImage;
  File? _backImage;

  @override
  void initState() {
    super.initState();
    if (widget.idDocumentImagePath.isNotEmpty) {
      _frontImage = File(widget.idDocumentImagePath);
    }
    if (widget.idDocumentImagePath2.isNotEmpty) {
      _backImage = File(widget.idDocumentImagePath2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ImageStateProvider>(context, listen: false);
      if (_frontImage != null && provider.idFrontImage == null) {
        provider.setIdFrontImage(_frontImage!);
      }
      if (_backImage != null && provider.idBackImage == null) {
        provider.setIdBackImage(_backImage!);
      }
    });
  }

  Future<void> _pickImage({required bool isFront}) async {
    try {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isFront
                ? 'Fotografíe la parte frontal'
                : 'Fotografíe la parte trasera',
            style: const TextStyle(
                fontFamily: 'Xpress',
                fontWeight: FontWeight.w700,
                color: Color(0xFF830A09)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar Foto',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 250));
                  final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera);
                  if (image != null) _processImage(XFile(image.path), isFront: isFront);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
  }

  Widget _dialogBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF830A09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Xpress',
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _processImage(XFile image, {required bool isFront}) {
    final file = File(image.path);
    final provider = Provider.of<ImageStateProvider>(context, listen: false);
    setState(() {
      if (isFront) {
        _frontImage = file;
        provider.setIdFrontImage(file);
      } else {
        _backImage = file;
        provider.setIdBackImage(file);
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    final front = _frontImage?.path ?? '';
    final back = _backImage?.path ?? '';
    widget.onImagesSelected(front, back);
    widget.registrationController.updateRegistrationData(
      idDocumentImagePath: front,
      idDocumentImagePath2: back,
      workerType: '',
      certificateImagePaths: [],
      criminalRecordImagePath: '',
      referralCode: '',
      medicalLicenseImagePath: '',
      professionalTitleImagePath: '',
      jobCompletePath: '',
      jobCompletePaths: [],
    );
    widget.isImageCaptured.value =
        _frontImage != null && _backImage != null;
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF830A09).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card,
                      color: Color(0xFF830A09), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documento de Identidad',
                        style: const TextStyle(
                          fontFamily: 'Xpress',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF830A09),
                        ),
                      ),
                      Text(
                        'Fotografíe ambos lados de su carnet',
                        style: TextStyle(
                          fontFamily: 'Xpress',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Frente
          _buildSideCard(
            label: 'Parte Frontal',
            sublabel: 'Lado con su foto y nombre',
            icon: Icons.face_outlined,
            image: _frontImage,
            isFront: true,
          ),
          const SizedBox(height: 16),

          // Reverso
          _buildSideCard(
            label: 'Parte Trasera',
            sublabel: 'Lado con el código de barras',
            icon: Icons.qr_code_outlined,
            image: _backImage,
            isFront: false,
          ),

          if (_frontImage == null || _backImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF830A09).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF830A09), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debe fotografiar ambos lados antes de continuar.',
                        style: TextStyle(
                          color: const Color(0xFF830A09),
                          fontSize: 12,
                          fontFamily: 'Xpress',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideCard({
    required String label,
    required String sublabel,
    required IconData icon,
    required File? image,
    required bool isFront,
  }) {
    final bool hasImage = image != null;
    return GestureDetector(
      onTap: () => _pickImage(isFront: isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF830A09)
                : Colors.grey.withOpacity(0.3),
            width: hasImage ? 2 : 1.5,
          ),
          boxShadow: hasImage
              ? [
                  BoxShadow(
                    color: const Color(0xFF830A09).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    // Overlay oscuro
                    Container(
                      color: Colors.black.withOpacity(0.25),
                    ),
                    // Badge de confirmación
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Color(0xFF830A09), size: 16),
                      ),
                    ),
                    // Label
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF830A09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Repetir',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Xpress',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            size: 36, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Xpress',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sublabel,
                              style: TextStyle(
                                fontFamily: 'Xpress',
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF830A09),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.camera_alt,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tomar foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Xpress',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
