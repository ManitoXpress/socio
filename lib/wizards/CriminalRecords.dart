import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';

import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';


class CriminalRecordImageStep extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String) onImageSelected; // Cambié el tipo a String (ruta de la imagen)
  final void Function() onNextStep;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  final String criminalRecordImagePath;

  const CriminalRecordImageStep({
    Key? key,
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.criminalRecordImagePath,
  }) : super(key: key);

  @override
  _CriminalRecordImageStepState createState() => _CriminalRecordImageStepState();
}

class _CriminalRecordImageStepState extends State<CriminalRecordImageStep> {
  File? _image; // Imagen seleccionada o capturada
  final ImagePicker _imagePicker = ImagePicker();

  // Función para seleccionar o capturar imagen
  Future<void> _pickImage() async {
  try {
    // Mostrar cuadro de diálogo para tomar una foto
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tome una foto a su antecedentes penales'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Cierra el cuadro de diálogo
                  try {
                    // Intentar capturar una imagen desde la cámara
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      print('Imagen capturada: ${image.path}');
                      _processImage(image); // Procesa la imagen capturada
                    } else {
                      print('No se capturó ninguna imagen.');
                    }
                  } catch (e) {
                    print('Error al acceder a la cámara: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No se pudo acceder a la cámara. Por favor, verifica los permisos en la configuración del dispositivo.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Tomar Foto'),
              ),
            ],
          ),
        );
      },
    );
  } catch (e) {
    print('Error al mostrar el cuadro de diálogo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocurrió un error: $e'),
      ),
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
        idDocumentImagePath: '',
        workerType: '',
        idDocumentImagePath2:'',
        certificateImagePaths:  '', criminalRecordImagePath: image.path,
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
            "Paso 7: Necesitamos una foto de sus antecedentes penales",
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