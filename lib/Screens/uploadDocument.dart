import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../Utils/styles.dart';
import '../menu/profilescreen.dart';
import '../provider/providerRegistration.dart';

import 'package:file_picker/file_picker.dart';

import 'Home.dart';


class DocumentsDialog extends StatefulWidget {
  final RegistrationProvider provider;
  final ProfileData profileData;
  final VoidCallback onSaved;

  const DocumentsDialog({
    Key? key,
    required this.provider,
    required this.profileData,
    required this.onSaved,
  }) : super(key: key);

  @override
  _DocumentsDialogState createState() => _DocumentsDialogState();
}

class _DocumentsDialogState extends State<DocumentsDialog> {
  final Map<String, bool> _isUploading = {};
  final List<File> _certificateFiles = [];

  static const Map<String, String> _jsonKeyMap = {
    'profile': 'imagePath',
    'idFront': 'idDocumentImagePath',
    'idBack': 'idDocumentImagePath2',
    'certificate': 'certificateImagePaths',
    'criminal': 'criminalRecordImagePath',
    'professionalTitle': 'professionalTitleImagePath',
    'medicalLicense': 'medicalLicenseImagePath',
  };

  Future<void> _pickAndUpload(String fieldKey) async {
    if (_isUploading[fieldKey] == true) return;
    setState(() => _isUploading[fieldKey] = true);

    try {
      List<File> pickedFiles = [];

      // 1) Selección
      if (fieldKey == 'certificate') {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png', 'pdf'],
        );
        if (result == null) return;
        pickedFiles = result.paths.map((p) => File(p!)).toList();
      } else {
        final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (img == null) return;
        pickedFiles = [File(img.path)];
      }

      // 2) Comprime y sube cada uno
      for (final file in pickedFiles) {
        final compressed = await widget.provider.compressAndResizeImage(file);
        await widget.provider.updateProfileImage(
          fieldKey: fieldKey,
          localPath: compressed.path,
        );
        if (fieldKey == 'certificate') {
          _certificateFiles.add(compressed);
        }
      }

      // 3) Preparamos el valor para el PATCH
      final String jsonKey = _jsonKeyMap[fieldKey]!;
      dynamic jsonValue;
      switch (fieldKey) {
        case 'profile':
          jsonValue = widget.provider.registrationData.imagePath;
          break;
        case 'idFront':
          jsonValue = widget.provider.registrationData.idDocumentImagePath;
          break;
        case 'idBack':
          jsonValue = widget.provider.registrationData.idDocumentImagePath2;
          break;
        case 'criminal':
          jsonValue = widget.provider.registrationData.criminalRecordImagePath;
          break;
        case 'medicalLicense':
          jsonValue = widget.provider.registrationData.medicalLicenseImagePath;
          break;
        case 'professionalTitle':
          jsonValue = widget.provider.registrationData.professionalTitleImagePath;
          break;
        case 'certificate':
          jsonValue = widget.provider.registrationData.certificateImagePaths;
          break;
        default:
          throw StateError('FieldKey desconocido $fieldKey');
      }

      // 4) Actualizamos en backend
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      await widget.provider.apiService.updateUserFields(
        user.uid,
        {jsonKey: jsonValue},
        token!,
      );

      // 5) Reflejamos en profileData
      setState(() {
        switch (fieldKey) {
          case 'profile':
            widget.profileData.userData.imagePath = jsonValue as String;
            break;
          case 'idFront':
            widget.profileData.userData.idDocumentImagePath = jsonValue as String;
            break;
          case 'idBack':
            widget.profileData.userData.idDocumentImagePath2 = jsonValue as String;
            break;
          case 'criminal':
            widget.profileData.userData.criminalRecordImagePath = jsonValue as String;
            break;
          case 'medicalLicense':
            widget.profileData.userData.medicalLicenseImagePath = jsonValue as String;
            break;
          case 'professionalTitle':
            widget.profileData.userData.professionalTitleImagePath = jsonValue as String;
            break;
          case 'certificate':
            widget.profileData.userData.certificateImagePaths = List<String>.from(jsonValue);
            break;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo \$fieldKey: \$e')),
      );
    } finally {
      setState(() => _isUploading[fieldKey] = false);
    }
  }

  bool _isDone(String fieldKey) {
    final reg = widget.provider.registrationData;
    final usr = widget.profileData.userData;
    if (fieldKey == 'certificate') {
      return reg.certificateImagePaths.isNotEmpty || usr.certificateImagePaths.isNotEmpty;
    }
    final localMap = {
      'profile': reg.imagePath,
      'idFront': reg.idDocumentImagePath,
      'idBack': reg.idDocumentImagePath2,
      'criminal': reg.criminalRecordImagePath,
      'professionalTitle': reg.professionalTitleImagePath,
      'medicalLicense': reg.medicalLicenseImagePath,
    };
    final remoteMap = {
      'profile': usr.imagePath,
      'idFront': usr.idDocumentImagePath,
      'idBack': usr.idDocumentImagePath2,
      'criminal': usr.criminalRecordImagePath,
      'professionalTitle': usr.professionalTitleImagePath,
      'medicalLicense': usr.medicalLicenseImagePath,
    };
    return (localMap[fieldKey]?.isNotEmpty ?? false) || (remoteMap[fieldKey]?.isNotEmpty ?? false);
  }

  Widget _buildItem(String label, String key) {
    final done = _isDone(key);
    final uploading = _isUploading[key] == true;
    final bgColor = done ? const Color(0xFFE6F4EA) : const Color(0xFFFFEBE6);
    final iconColor = done ? Colors.green : Colors.redAccent;
    Widget trailing;
    if (uploading) {
      trailing = const SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (key == 'certificate') {
      final count = widget.provider.registrationData.certificateImagePaths.length;
      trailing = Icon(Icons.collections, color: iconColor);
      label += ' ($count)';
    } else {
      trailing = Icon(done ? Icons.check_circle : Icons.error_outline, color: iconColor);
    }

    return GestureDetector(
      onTap: uploading ? null : () => _pickAndUpload(key),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: uploading ? Border.all(color: Colors.blueAccent) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uploading ? 'Subiendo...' : (done ? 'Completado' : 'Requiere atención'),
                    style: MyTextStyles.drawerButtonTextStyle2.copyWith(
                      fontSize: 12,
                      color: uploading ? Colors.blueAccent : (done ? Colors.green[800]! : Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: MyTextStyles.drawerButtonTextStyle3),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': 'profile', 'label': 'Foto de perfil'},
      {'key': 'idFront', 'label': 'Carnet identidad (frontal)'},
      {'key': 'idBack', 'label': 'Carnet identidad (posterior)'},
      {'key': 'certificate', 'label': 'Certificados profesionales'},
      {'key': 'criminal', 'label': 'Antecedentes penales'},
      {'key': 'professionalTitle', 'label': 'Título profesional'},
      {'key': 'medicalLicense', 'label': 'Licencia o matricula profesional'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Cargar Documentos', style: MyTextStyles.buttonTextStyle),
        backgroundColor: const Color(0xFF830A09),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return _buildItem(e['label']!, e['key']!);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Mensaje de privacidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las imágenes de tu carnet de identidad, antecedentes penales y título profesional se utilizan únicamente para validar tu identidad. No se compartirán con clientes salvo en casos de incidentes o requerimientos legales.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSaved();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        registrationData: widget.provider.registrationData,
                        userData: widget.profileData.userData,
                        initialPageIndex: 0,
                        isGuest: false,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF830A09),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Aceptar', style: MyTextStyles.buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
