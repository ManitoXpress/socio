import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

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

class _ProfileImageState extends State<ProfileImage> {
  File? _image;
  final ImagePicker _imagePicker = ImagePicker();

  // Función para manejar la selección de imagen
 Future<void> _pickImage() async {
  try {
    // Mostrar cuadro de diálogo para tomar una foto
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tome una foto de perfil'),
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
                          'No se pudo acceder a la cámara. Por favor, verifique los permisos en la configuración del dispositivo.',
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
    print('Error al manejar la cámara: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocurrió un error: $e'),
      ),
    );
  }
}


  // Procesa la imagen seleccionada
  Future<void> _processImage(XFile? image) async {
    if (image != null) {
      final originalFile = File(image.path);
      final originalImage = img.decodeImage(await originalFile.readAsBytes());

      if (originalImage != null) {
        // Corrige la orientación de la imagen
        final correctedImage = img.bakeOrientation(originalImage);
        final correctedFile = await originalFile.writeAsBytes(img.encodeJpg(correctedImage));

        setState(() {
          _image = correctedFile; // Asigna la imagen corregida
        });

        // Notifica al controlador y actualiza los datos
        widget.onImageSelected(correctedFile.path);
        widget.isImageCaptured.value = true;
        print('Imagen seleccionada: ${correctedFile.path}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 3: Saque una foto de perfil sin gafas ni gorra",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
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
        if (_image == null)
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
}
