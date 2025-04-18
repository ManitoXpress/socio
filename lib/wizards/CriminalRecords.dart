import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:socio/provider/providerImage.dart';

import '../Utils/styles.dart';
class CriminalRecordImageStep extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String) onImageSelected;
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
  _CriminalRecordImageStepState createState() =>
      _CriminalRecordImageStepState();
}

class _CriminalRecordImageStepState extends State<CriminalRecordImageStep> {
  File? _image;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
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
                        _processImage(image);
                      } else {
                        print('No se capturó ninguna imagen.');
                      }
                    } catch (e) {
                      print('Error al acceder a la cámara: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se pudo acceder a la cámara. Verifica los permisos del dispositivo.',
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
                      final FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null) {
                        final PlatformFile file = result.files.first;
                        final File pdfFile = File(file.path!);
                        print('Archivo PDF seleccionado: ${pdfFile.path}');
                        _processImage(XFile(pdfFile.path));
                      } else {
                        print('No se seleccionó ningún archivo.');
                      }
                    } catch (e) {
                      print('Error al seleccionar el archivo PDF: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Ocurrió un error al seleccionar el archivo PDF: $e'),
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

  void _processImage(XFile? file) {
    if (file != null) {
      setState(() {
        _image = File(file.path);
      });
      widget.onImageSelected(file.path);

      // Actualizamos la información en el RegistrationController
      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: '',
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: '',
        criminalRecordImagePath: file.path,
        referralCode: '',
      );

      // Actualizamos el provider dependiendo del tipo de archivo.
      final imageProvider =
      Provider.of<ImageStateProvider>(context, listen: false);
      if (file.path.toLowerCase().endsWith('.pdf')) {
        imageProvider.setCriminalRecordPdf(File(file.path));
      } else {
        imageProvider.setCriminalRecordImage(File(file.path));
      }

      print('Archivo seleccionado: ${file.path}');
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
            child: _image == null
                ? const Center(
              child: Icon(
                Icons.cloud_upload,
                size: 48,
                color: Color(0xA3C9D2D2),
              ),
            )
                : _image!.path.toLowerCase().endsWith('.pdf')
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
              'Saca una foto o selecciona un PDF antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }
}