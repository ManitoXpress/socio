import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'dart:io';

import '../Metods/RegisController.dart';

import 'package:flutter/cupertino.dart';

class Step8FormData {
  final String certificateImagePaths;


  Step8FormData({required this.certificateImagePaths});
}

class CertificateImageStep extends StatefulWidget {
  final Function(Step8FormData) onImageSelected;
  final RegistrationController registrationController;
  final VoidCallback onNextStep;
  final RegistrationData registrationData;

  final UserData userData;

  CertificateImageStep({
    required this.onImageSelected,
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _CertificateImageStepState createState() => _CertificateImageStepState();
}

class _CertificateImageStepState extends State<CertificateImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  List<XFile> capturedImages = [];
  bool _isCameraReady = false;
  XFile? capturedImage;
  bool _isCapturing = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }


  Future<void> _pickImage() async {
  final ImagePicker _picker = ImagePicker();

  // Verifica y solicita permiso de cámara
  PermissionStatus status = await Permission.camera.status;

  if (!status.isGranted) {
    status = await Permission.camera.request(); // Solicitar permiso
  }

  if (status.isGranted) {
    // Muestra opciones para seleccionar la imagen
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Saque una foto de perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  _processImage(image);
                },
                child: Text('Tomar Foto'),
              ),
            ],
          ),
        );
      },
    );
  } else {
    // Muestra un mensaje si el usuario denegó el permiso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Por favor, habilita el acceso a la cámara.')),
    );
  }
}

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }

      print("Cámara inicializada correctamente");
    } catch (e) {
      print("Error al inicializar la cámara: $e");
    }
  }

  bool isStep3Valid() {
    return capturedImage != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 8: Tomese una foto a sus Certificados o título profesional(Opcional)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 400,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickImage(),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xA3C9D2D2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image == null
                      ? Center(
                    child: Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Color(0xA3C9D2D2),
                    ),
                  )
                      : Image.file(
                    _image!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  void _processImage(XFile? image) {
    if (image != null) {
      setState(() {
        _image = File(image.path); // Actualiza la imagen mostrada
        capturedImage = image; // Actualiza la referencia de la imagen capturada
      });

      // Llama a los métodos con la ruta correcta
      widget.onImageSelected(
        Step8FormData(certificateImagePaths: image.path), // Usa la ruta capturada
      );

      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: '', // Este campo queda vacío según el contexto
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: image.path, // Usa la ruta capturada
      );
    }

    // Marcar como captura finalizada
    setState(() {
      _isCapturing = false;
    });
  }



  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}