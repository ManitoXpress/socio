import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

class Step7FormData {
  final String criminalRecordImagePath;

  Step7FormData({required this.criminalRecordImagePath});
}

class CriminalRecordImageStep extends StatefulWidget {
  final Function(Step7FormData) onImageSelected;
  final RegistrationController registrationController;
  final VoidCallback onNextStep;
  final RegistrationData registrationData;
  final UserData userData;

  CriminalRecordImageStep({
    required this.onImageSelected,
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _CriminalRecordImageStepState createState() =>
      _CriminalRecordImageStepState();
}

class _CriminalRecordImageStepState extends State<CriminalRecordImageStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? capturedImage;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  File? _image;  // Cambiado para una sola imagen
  final ImagePicker _imagePicker = ImagePicker(); // Definición de _imagePicker

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _showImagePreview() async {
    if (_image != null) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(_image!), // Mostrar la única imagen
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _image = null; // Elimina la imagen
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Eliminar imagen"),
                ),
              ],
            ),
          );
        },
      );
    }
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
          title: Text('Saque una foto de sus antecendentes policiales'),
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
           "Paso 7: Saque una foto a sus antecedentes penales(Opcional)",
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
        _image = File(image.path); // Solo guarda una imagen
      });
      widget.onImageSelected(
          Step7FormData(criminalRecordImagePath: capturedImage?.path ?? ''));

      widget.registrationController.updateRegistrationData(
          idDocumentImagePath: capturedImage?.path ?? '',
          workerType: '',
          idDocumentImagePath2: '',
          certificateImagePaths: '');
    } 
     {
      // Marcar como captura finalizada
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showDeleteImageConfirmation() {
    showDialog(
      context: context, // Asegúrate de usar el contexto actual
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Eliminar Imagen Capturada"),
          content: Text("¿Desea eliminar la imagen capturada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImage = null; // Eliminar la imagen capturada
                });
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
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
