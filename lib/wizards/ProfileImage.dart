import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';

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
  File? _image;  // Solo una imagen en lugar de una lista
  ApiService apiService = ApiService(); // Instancia de ApiService

  // Función para seleccionar imagen desde la galería o la cámara
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

  // Procesar y asignar la imagen seleccionada
  void _processImage(XFile? image) {
    if (image != null) {
      setState(() {
        _image = File(image.path); // Asigna la imagen seleccionada
      });

      // Asegúrate de que la ruta de la imagen se pasa correctamente
      widget.onImageSelected(image.path);  // Actualiza la ruta de la imagen en userData
      widget.isImageCaptured.value = true; // Cambia el estado de la imagen capturada
      print('Imagen seleccionada: ${image.path}'); // Verifica la ruta de la imagen
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
            child: _image == null // Si no se ha seleccionado imagen, mostrar ícono
                ? Center(
              child: Icon(
                Icons.cloud_upload,
                size: 48,
                color: Color(0xA3C9D2D2),
              ),
            )
                : Image.file(
              _image!, // Mostrar la imagen seleccionada
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (_image == null) // Mostrar mensaje si no se ha capturado la imagen
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