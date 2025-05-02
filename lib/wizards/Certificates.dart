import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/provider/providerImage.dart';
import '../Controller/RegisController.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import '../Utils/styles.dart';
class CertificateImageStep extends StatefulWidget {
  final RegistrationController registrationController;
  /// Ahora recibe lista de rutas
  final void Function(List<String>) onImageSelected;
  final void Function() onNextStep;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  /// Lista en lugar de String
  final List<String> certificateImagePaths;

  const CertificateImageStep({
    Key? key,
    required this.registrationController,
    required this.onImageSelected,
    required this.onNextStep,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.certificateImagePaths,
  }) : super(key: key);

  @override
  _CertificateImageStepState createState() => _CertificateImageStepState();
}

class _CertificateImageStepState extends State<CertificateImageStep> {
  /// Ahora guardamos *múltiples* certificados en una lista
  final List<File> _certificateFiles = [];

  /// Y un único archivo para el título profesional / matrícula
  File? _titleFile;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Si ya vienen rutas iniciales, poblamos _certificateFiles
    for (final path in widget.certificateImagePaths) {
      _certificateFiles.add(File(path));
    }
  }

  Future<void> _pickDialog({required bool forTitle}) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(forTitle
              ? 'Seleccione su Título Profesional'
              : 'Seleccione un Certificado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    _processPicked(File(image.path), forTitle: forTitle);
                  }
                },
                child: const Text('Tomar Foto'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'png'],
                  );
                  if (result != null && result.files.single.path != null) {
                    _processPicked(File(result.files.single.path!), forTitle: forTitle);
                  }
                },
                child: const Text('Seleccionar Archivo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processPicked(File file, {required bool forTitle}) {
    setState(() {
      if (forTitle) {
        _titleFile = file;
      } else {
        _certificateFiles.add(file);
      }

      // Construye la lista de rutas
      final paths = _certificateFiles.map((f) => f.path).toList();

      // Callback con lista
      widget.onImageSelected(paths);

      // Actualiza el RegistrationController con lista
      widget.registrationController.updateRegistrationData(
        idDocumentImagePath: '',
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: paths, // ahora List<String>
        criminalRecordImagePath: '',
        referralCode: '',
        medicalLicenseImagePath: '',
        professionalTitleImagePath: _titleFile?.path ?? '',
        jobCompletePath: '',
        jobCompletePaths: [],
      );

      // Actualiza el ImageStateProvider
      final imgProv = Provider.of<ImageStateProvider>(context, listen: false);
      if (forTitle) {
        if (file.path.toLowerCase().endsWith('.pdf')) {
          imgProv.setTitlePdf(file);
        } else {
          imgProv.setTitleImage(file);
        }
      } else {
        if (file.path.toLowerCase().endsWith('.pdf')) {
          imgProv.addCertificatePdf(file);
        } else {
          imgProv.addCertificateImage(file);
        }
      }

      // Marcar captura
      widget.isImageCaptured.value =
          _certificateFiles.isNotEmpty || _titleFile != null;
    });
  }

  Widget _buildThumbnail(File file, {required bool isTitle}) {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isPdf
              ? Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent)
              : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isTitle) {
                  _titleFile = null;
                } else {
                  _certificateFiles.remove(file);
                }

                final paths = _certificateFiles.map((f) => f.path).toList();
                widget.onImageSelected(paths);
                widget.registrationController.updateRegistrationData(
                  idDocumentImagePath: '',
                  workerType: '',
                  idDocumentImagePath2: '',
                  certificateImagePaths: paths,
                  criminalRecordImagePath: '',
                  referralCode: '',
                  medicalLicenseImagePath: '',
                  professionalTitleImagePath: _titleFile?.path ?? '',
                  jobCompletePath: '',
                  jobCompletePaths: [],
                );
                widget.isImageCaptured.value =
                    _certificateFiles.isNotEmpty || _titleFile != null;
              });
            },
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.white,
              child: Icon(Icons.close, size: 16, color: Colors.redAccent),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CERTIFICADOS
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 8: Cargue los certificados (imágenes o PDFs)",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._certificateFiles
                  .map((f) => _buildThumbnail(f, isTitle: false))
                  .toList(),
              GestureDetector(
                onTap: () => _pickDialog(forTitle: false),
                child: Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.add, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),

        // TÍTULO PROFESIONAL / MATRÍCULA
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "Paso 9: Cargue título profesional o matrícula (opcional)",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_titleFile != null)
                _buildThumbnail(_titleFile!, isTitle: true),
              GestureDetector(
                onTap: () => _pickDialog(forTitle: true),
                child: Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.add, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),
        // El avance al siguiente paso lo controla el Stepper externo (onNextStep)
      ],
    );
  }
}