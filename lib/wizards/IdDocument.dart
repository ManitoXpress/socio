import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step5FormData {
  final String idDocumentImagePath;

  Step5FormData({required this.idDocumentImagePath});
}

class IdCardImageStep extends StatefulWidget {
  final Function(Step5FormData) onImageSelected;
  final RegistrationController registrationController;
  late _IdCardImageStepState _idCardImageStepState;
  final void Function() onNextStep;
  bool isStep5Valid() {
    return _idCardImageStepState.isStep5Valid();
  }

  IdCardImageStep({
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required idDocumentImagePath,
    required Null Function(Step5FormData image2) onImageSelected2,
    required UserData userData,
    required RegistrationData registrationData,
    required Step5FormData formData2,
  });

  @override
  _IdCardImageStepState createState() {
    _idCardImageStepState = _IdCardImageStepState();
    return _idCardImageStepState;
  }
}

class _IdCardImageStepState extends State<IdCardImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  int currentStep = 0;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  File? _image;  // Cambiado para una sola imagen
  final ImagePicker _imagePicker = ImagePicker(); // Definición de _imagePicker

  bool isStep5Valid() {
    return capturedImage != null;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  

  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tomese una foto de perfil', style: MyTextStyles.drawerButtonTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
                  _processImage(image);
                },
                child: Text('Tomar Foto'),
              ),
            ],
          ),
        );
      },
    );
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
            "Paso 5:  Necesitamos una foto de su carnet de la parte frontal",
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
        if (!isStep3Valid())
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Saca una foto antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }

  void _processImage(XFile? image) {
    if (image != null) {
      setState(() {
        _image = File(image.path); // Solo guarda una imagen
      });
      widget.onImageSelected(
          Step5FormData(idDocumentImagePath: capturedImage?.path ?? ''));

      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: capturedImage?.path ?? '',
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: [],
      );
    }
  }

  void _showDeleteImageConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Imagen Capturada"),
          content: Text("¿Desea eliminar la imagen capturada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImage = null; // Eliminar la imagen capturada
                });
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
