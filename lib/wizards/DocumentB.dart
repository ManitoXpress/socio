import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socio/provider/providerImage.dart';

import '../Utils/styles.dart';
import '../controllers/RegisController.dart';
class IdCardImageStepB extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String)
      onImageSelected; // Cambié el tipo a String (ruta de la imagen)
  final void Function() onNextStep;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  final String idDocumentImagePath2;

  const IdCardImageStepB({
    Key? key,
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.idDocumentImagePath2,
  }) : super(key: key);

  @override
  _IdCardImageStepState createState() => _IdCardImageStepState();
}


class _IdCardImageStepState extends State<IdCardImageStepB> {

  File? _image; // Imagen seleccionada o capturada
  final ImagePicker _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // Si ya existe una ruta para la imagen del documento, inicializa el provider
    if (widget.idDocumentImagePath2.isNotEmpty) {
      final provider = Provider.of<ImageStateProvider>(context, listen: false);
      if (provider.idBackImage == null) {
        provider.setIdBackImage(File(widget.idDocumentImagePath2));
      }

    }
  }

  // Función para seleccionar o capturar imagen
  Future<void> _pickImage() async {
    try {
      // Mostrar cuadro de diálogo para tomar una foto
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tome una foto a su carnet'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Cierra el cuadro de diálogo

                    // Agregamos un pequeño delay para asegurarnos de que el diálogo se cierre completamente
                    await Future.delayed(Duration(milliseconds: 300));

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
                      if (mounted) { // Verificar si el widget sigue montado
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No se pudo acceder a la cámara. Por favor, verifica los permisos.',
                            ),
                          ),
                        );
                      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error: $e'),
          ),
        );
      }
    }
  }
  // Procesa la imagen seleccionada o capturada
  void _processImage(XFile? image) {
    if (image != null) {
      try {
        final imageFile = File(image.path);

        // Usar Provider para mantener el estado incluso si la app se minimiza
        final provider = Provider.of<ImageStateProvider>(context, listen: false);
        provider.setIdBackImage(imageFile);

        // Llama al callback para notificar la selección de la ruta de la imagen
        widget.onImageSelected(image.path);

        // Actualiza el estado en RegistrationController
        widget.registrationController.updateRegistrationData(
          idDocumentImagePath: '',
          workerType: '',
          idDocumentImagePath2: image.path,
          certificateImagePaths: [],
          criminalRecordImagePath: '',
          referralCode: '',
          medicalLicenseImagePath: '', // Provide appropriate value
          professionalTitleImagePath: '', // Provide appropriate value
          jobCompletePath: '', // Provide appropriate value
          jobCompletePaths: [], // Provide appropriate value
        );

        print('Imagen de documento seleccionada: ${image.path}');

        // Notificar que la imagen fue capturada
        widget.isImageCaptured.value = true;
      } catch (e) {
        print('Error al procesar la imagen: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la imagen: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar Consumer para escuchar cambios en el provider
    return Consumer<ImageStateProvider>(
      builder: (context, imageProvider, child) {
        final File? displayImage = imageProvider.idBackImage ??
            (widget.idDocumentImagePath2.isNotEmpty ? File(widget.idDocumentImagePath2) : null);


        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Paso 6: Necesitamos una foto de su carnet de la parte trasera",
                style: MyTextStyles.drawerButtonTextStyle2,
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
                child: displayImage == null
                    ? const Center(
                  child: Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Color(0xA3C9D2D2),
                  ),
                )
                    : Image.file(
                  displayImage,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (displayImage == null)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Saca una foto antes de continuar.',
                  style: TextStyle(color: Color(0xFF830A09)),
                ),
              ),
          ],
        );
      },
    );
  }
}