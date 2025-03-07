import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:socio/Metods/RegisController.dart';

import 'package:socio/ServiceResponse/requestUserData.dart';


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
  Future<void> _pickFile() async {
    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Seleccione una opción'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        print('Imagen capturada: ${image.path}');
                        _processFile(image.path);
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
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        print('Imagen seleccionada: ${image.path}');
                        _processFile(image.path);
                      } else {
                        print('No se seleccionó ninguna imagen.');
                      }
                    } catch (e) {
                      print('Error al acceder a la galería: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se pudo acceder a la galería. Por favor, verifica los permisos en la configuración del dispositivo.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Seleccionar de Galería'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        final String? filePath = result.files.single.path;
                        if (filePath != null) {
                          print('Documento PDF seleccionado: $filePath');
                          _processFile(filePath);
                        }
                      } else {
                        print('No se seleccionó ningún documento.');
                      }
                    } catch (e) {
                      print('Error al seleccionar el documento: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se pudo seleccionar el documento. Por favor, inténtalo de nuevo.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Seleccionar PDF'),
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

  // Procesa el archivo seleccionado
  void _processFile(String filePath) {
    setState(() {
      _image = File(filePath);
    });

    widget.onImageSelected(filePath);

    widget.registrationController.updateRegistrationData(
      idDocumentImagePath: '',
      workerType: '',
      idDocumentImagePath2: '',
      certificateImagePaths: filePath,
      criminalRecordImagePath: '',
    );

    print('Archivo seleccionado: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 7: Necesitamos una foto de sus certificados profesionales o un documento PDF (no obligatorio)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: _pickFile,
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
                : _image!.path.endsWith('.pdf')
                ? const Center(
              child: Icon(
                Icons.picture_as_pdf,
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
              'Saca una foto, selecciona una imagen o un documento PDF antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }
}