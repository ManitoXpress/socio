import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:socio/provider/providerImage.dart';

import '../Utils/styles.dart';
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

class _ProfileImageState extends State<ProfileImage> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  late String _persistentImagePath;
  bool _isProcessing = false;

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
        final provider = Provider.of<ImageStateProvider>(context, listen: false);
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
                  WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
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
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      ).timeout(const Duration(seconds: 30));

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

      final persistentFile = File('${directory.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await persistentFile.writeAsBytes(img.encodeJpg(processedImage));

      if (!mounted) return;

      final provider = Provider.of<ImageStateProvider>(context, listen: false);
      provider.setProfileImage(persistentFile);

      widget.onImageSelected(persistentFile.path);
      _persistentImagePath = persistentFile.path;
      widget.isImageCaptured.value = true;

    } catch (e) {
      _showErrorSnackbar('Error procesando imagen: ${e.toString()}');
    }
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
              ),
            ),
            GestureDetector(
              onTap: _isProcessing ? null : _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xA3C9D2D2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildImageWidget(imageFile),
              ),
            ),
            if (imageFile == null && !_isProcessing)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Saca una foto antes de continuar.',
                  style: TextStyle(color: Color(0xFF830A09)),
                ),
              ),
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
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
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() => Center(
    child: Icon(
      Icons.cloud_upload,
      size: 48,
      color: Color(0xA3C9D2D2),
    ),
  );
}