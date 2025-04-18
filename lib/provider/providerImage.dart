import 'dart:io';

import 'package:flutter/material.dart';
import 'package:socio/Controller/RegisController.dart';

class ImageStateProvider extends ChangeNotifier {
  // Imágenes de perfil
  File? _profileImage;
  bool _isProfileImageCaptured = false;

  // Imágenes de documentos
  File? _idFrontImage;
  File? _idBackImage;

  // Antecedentes penales
  File? _criminalRecordImage;
  File? _criminalRecordPdf;

  // Certificados profesionales
  File? _certificateImage;
  File? _certificatePdf;

  // Getters
  File? get profileImage => _profileImage;
  bool get isProfileImageCaptured => _isProfileImageCaptured;

  File? get idFrontImage => _idFrontImage;
  File? get idBackImage => _idBackImage;

  // Para antecedentes penales
  File? get criminalRecordImage => _criminalRecordImage;
  File? get criminalRecordPdf => _criminalRecordPdf;

  // Para certificados
  File? get certificateImage => _certificateImage;
  File? get certificatePdf => _certificatePdf;

  // Métodos para imagen de perfil
  void setProfileImage(File image) {
    _profileImage = image;
    _isProfileImageCaptured = true;
    notifyListeners();
  }
  void clearProfileImage() {
    _profileImage = null;
    _isProfileImageCaptured = false;
    notifyListeners();
  }

  // Métodos para imagen frontal del carnet
  void setIdFrontImage(File image) {
    _idFrontImage = image;
    notifyListeners();
  }
  void clearIdFrontImage() {
    _idFrontImage = null;
    notifyListeners();
  }

  // Métodos para imagen trasera del carnet
  void setIdBackImage(File image) {
    _idBackImage = image;
    notifyListeners();
  }
  void clearIdBackImage() {
    _idBackImage = null;
    notifyListeners();
  }

  // Métodos para antecedentes penales (imagen o PDF)
  void setCriminalRecordImage(File image) {
    _criminalRecordImage = image;
    // Si se asigna una imagen, se limpia el PDF
    _criminalRecordPdf = null;
    notifyListeners();
  }
  void clearCriminalRecordImage() {
    _criminalRecordImage = null;
    notifyListeners();
  }
  void setCriminalRecordPdf(File pdf) {
    _criminalRecordPdf = pdf;
    // Si se asigna un PDF, se limpia la imagen
    _criminalRecordImage = null;
    notifyListeners();
  }
  void clearCriminalRecordPdf() {
    _criminalRecordPdf = null;
    notifyListeners();
  }

  // Métodos para certificados (imagen o PDF)
  void setCertificateImage(File image) {
    _certificateImage = image;
    _certificatePdf = null;
    notifyListeners();
  }
  void clearCertificateImage() {
    _certificateImage = null;
    notifyListeners();
  }
  void setCertificatePdf(File pdf) {
    _certificatePdf = pdf;
    _certificateImage = null;
    notifyListeners();
  }
  void clearCertificatePdf() {
    _certificatePdf = null;
    notifyListeners();
  }

  // Método para inicializar las imágenes desde datos ya existentes.
  void initFromRegistrationData(RegistrationData data) {
    if (data.imagePath.isNotEmpty) {
      _profileImage = File(data.imagePath);
      _isProfileImageCaptured = true;
    }
    if (data.idDocumentImagePath.isNotEmpty) {
      _idFrontImage = File(data.idDocumentImagePath);
    }
    if (data.idDocumentImagePath2.isNotEmpty) {
      _idBackImage = File(data.idDocumentImagePath2);
    }
    if (data.criminalRecordImagePath.isNotEmpty) {
      // Detecta si es pdf o imagen
      if (data.criminalRecordImagePath.toLowerCase().endsWith('.pdf')) {
        _criminalRecordPdf = File(data.criminalRecordImagePath);
      } else {
        _criminalRecordImage = File(data.criminalRecordImagePath);
      }
    }
    if (data.certificateImagePaths.isNotEmpty) {
      if (data.certificateImagePaths.toLowerCase().endsWith('.pdf')) {
        _certificatePdf = File(data.certificateImagePaths);
      } else {
        _certificateImage = File(data.certificateImagePaths);
      }
    }
    notifyListeners();
  }
}