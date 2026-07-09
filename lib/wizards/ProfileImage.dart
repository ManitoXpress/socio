import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';


import '../Utils/styles.dart';
import '../provider/providerImage.dart';
class ProfileImage extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String imagePath) onImageSelected;
  final String imagePath;
  final RegistrationData registrationData;
  final UserData userData;
  final ValueNotifier<bool> isImageCaptured;
  final void Function() onNextStep;

  const ProfileImage({
    Key? key,
    required this.registrationController,
    required this.onImageSelected,
    required this.imagePath,
    required this.registrationData,
    required this.userData,
    required this.isImageCaptured,
    required this.onNextStep,
  }) : super(key: key);

  @override
  _ProfileImageState createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  late String _persistentImagePath;
  bool _isProcessing = false;
  bool _faceDetected = false;
  String? _faceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _persistentImagePath = widget.imagePath;
    _initializeImage();
  }

  @override
  void didUpdateWidget(ProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _persistentImagePath = widget.imagePath;
      _initializeImage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeImage() async {
    if (_persistentImagePath.isNotEmpty) {
      final file = File(_persistentImagePath);
      if (await file.exists()) {
        final provider =
            Provider.of<ImageStateProvider>(context, listen: false);
        provider.setProfileImage(file);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkImageState();
    }
  }

  Future<void> _checkImageState() async {
    final provider = Provider.of<ImageStateProvider>(context, listen: false);
    if (provider.profileImage == null && _persistentImagePath.isNotEmpty) {
      final file = File(_persistentImagePath);
      if (await file.exists()) {
        provider.setProfileImage(file);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Tome una foto de perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _captureImage());
                },
                child: const Text('Tomar Foto'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('No se pudo abrir la cámara');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker
          .pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
          )
          .timeout(const Duration(seconds: 30));

      if (image != null && mounted) {
        await _processImage(image);
      }
    } on TimeoutException {
      _showErrorSnackbar('Tiempo de espera agotado para la cámara');
    } catch (e) {
      _showErrorSnackbar('Error al acceder a la cámara: ${e.toString()}');
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final originalFile = File(image.path);
      final originalBytes = await originalFile.readAsBytes();

      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) throw Exception('Error decodificando imagen');

      // Procesamiento de imagen optimizado
      final processedImage = _applyImageProcessing(originalImage);

      final persistentFile = File(
          '${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await persistentFile.writeAsBytes(img.encodeJpg(processedImage));

      // Detección de rostro mejorada
      final faceValidationResult = await _detectFaceAdvanced(persistentFile, processedImage.width, processedImage.height);
      if (!faceValidationResult['accepted']) {
        setState(() {
          _faceDetected = false;
          _faceError = faceValidationResult['message'];
        });
        persistentFile.delete();
        return;
      }

      if (!mounted) return;

      final provider = Provider.of<ImageStateProvider>(context, listen: false);
      provider.setProfileImage(persistentFile);

      widget.onImageSelected(persistentFile.path);
      _persistentImagePath = persistentFile.path;
      widget.isImageCaptured.value = true;
      setState(() {
        _faceDetected = true;
        _faceError = null;
      });
    } catch (e) {
      _showErrorSnackbar('Error procesando imagen: ${e.toString()}');
    }
  }

  /// Valida que haya exactamente un rostro, que no esté en el borde y que sea suficientemente grande
  Future<Map<String, dynamic>> _detectFaceAdvanced(File imageFile, int imgWidth, int imgHeight) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: false,
      enableLandmarks: false,
    );
    final faceDetector = FaceDetector(options: options);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    if (faces.isEmpty) {
      return {'accepted': false, 'message': 'No se detectó un rostro en la imagen. Intenta nuevamente.'};
    }
    if (faces.length > 1) {
      return {'accepted': false, 'message': 'Se detectaron múltiples rostros en la imagen. Por favor, asegúrate de que solo tú aparezcas en la foto.'};
    }
    final face = faces.first;
    final boundingBox = face.boundingBox;
    // Validar tamaño mínimo del rostro (al menos 20% del ancho y alto de la imagen)
    final minWidth = imgWidth * 0.2;
    final minHeight = imgHeight * 0.2;
    if (boundingBox.width < minWidth || boundingBox.height < minHeight) {
      return {'accepted': false, 'message': 'El rostro detectado es muy pequeño. Acércate más a la cámara y asegúrate de que tu cara ocupe una parte importante de la imagen.'};
    }
    // Validar que el rostro no esté en el borde (al menos 5% de margen)
    final margin = 0.05;
    if (boundingBox.left < imgWidth * margin ||
        boundingBox.top < imgHeight * margin ||
        boundingBox.right > imgWidth * (1 - margin) ||
        boundingBox.bottom > imgHeight * (1 - margin)) {
      return {'accepted': false, 'message': 'El rostro está demasiado cerca del borde de la imagen. Por favor, centra tu cara en la foto.'};
    }
    return {'accepted': true};
  }

  img.Image _applyImageProcessing(img.Image image) {
    return img.bakeOrientation(
      img.copyResize(
        image,
        width: 800,
        maintainAspect: true,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageStateProvider>(
      builder: (context, provider, _) {
        final imageFile = provider.profileImage ??
            (widget.imagePath.isNotEmpty ? File(widget.imagePath) : null);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Paso 3: Saque una foto de perfil sin gafas ni gorra",
                style: MyTextStyles.drawerButtonTextStyle2,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _isProcessing ? null : _pickImage,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _faceDetected
                            ? Color(0xFF830A09)
                            : (_faceError != null
                                ? Colors.red
                                : Color(0xA3C9D2D2)),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildImageWidget(imageFile),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_isProcessing && imageFile == null)
                  Positioned(
                    bottom: 16,
                    child: Icon(Icons.camera_alt,
                        size: 40, color: Color(0xFF830A09)),
                  ),
                if (!_isProcessing && imageFile != null)
                  Positioned(
                    bottom: 16,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.refresh, color: Colors.white),
                      label: Text('Repetir',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF830A09),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (_faceError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _faceError!,
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            if (imageFile == null && !_isProcessing)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Toca el círculo para tomar una foto antes de continuar.',
                  style: TextStyle(color: Color(0xFF830A09)),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildImageWidget(File? imageFile) {
    if (imageFile != null) {
      return Image.file(
        imageFile,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.person_outline,
            size: 80,
            color: Color(0xA3C9D2D2),
          ),
     ),
  );
}