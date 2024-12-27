import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
class IdCardImageStep extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String) onImageSelected; // Cambié el tipo a String (ruta de la imagen)
  final void Function() onNextStep;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  final String idDocumentImagePath;

  const IdCardImageStep({
    Key? key,
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.idDocumentImagePath,
  }) : super(key: key);

  @override
  _IdCardImageStepState createState() => _IdCardImageStepState();
}

class _IdCardImageStepState extends State<IdCardImageStep> {
  File? _image; // Imagen seleccionada o capturada
  final ImagePicker _imagePicker = ImagePicker();

  // Función para seleccionar o capturar imagen
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
          title: Text('Saque una foto de la parte anversa de su carnet'),
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

  // Procesa la imagen seleccionada o capturada
  void _processImage(XFile? image) {
    if (image != null) {
      setState(() {
        _image = File(image.path); // Guarda la imagen seleccionada
      });

      // Llama al callback para notificar la selección de la ruta de la imagen
      widget.onImageSelected(image.path);

      // Actualiza el estado en RegistrationController (si es necesario)
      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: image.path,
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: '',
      );

      print('Imagen de documento seleccionada: ${image.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 5: Necesitamos una foto de la parte frontal de su carnet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xA3C9D2D2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _image == null
                ? const Center(
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
        if (_image == null)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Saca una foto antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }
}