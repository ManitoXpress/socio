// Modelo de Provider extendido para manejar múltiples imágenes
import 'package:flutter/material.dart';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:socio/Controller/RegisController.dart';


class ImageStateProvider extends ChangeNotifier {
  // Imágenes de perfil
  File? _profileImage;
  bool _isProfileImageCaptured = false;

  // Imágenes de documentos de identidad
  File? _idFrontImage;
  File? _idBackImage;

  // Antecedentes penales (imagen o PDF)
  File? _criminalRecordImage;
  File? _criminalRecordPdf;

  // Certificados profesionales (múltiples)
  final List<File> _certificateImages = [];
  final List<File> _certificatePdfs = [];

  // Título profesional / matrícula (uno)
  File? _titleImage;
  File? _titlePdf;

  // ─── Getters ─────────────────────────────────────────────────

  File? get profileImage => _profileImage;
  bool get isProfileImageCaptured => _isProfileImageCaptured;

  File? get idFrontImage => _idFrontImage;
  File? get idBackImage => _idBackImage;

  File? get criminalRecordImage => _criminalRecordImage;
  File? get criminalRecordPdf => _criminalRecordPdf;

  List<File> get certificateImages => List.unmodifiable(_certificateImages);
  List<File> get certificatePdfs => List.unmodifiable(_certificatePdfs);

  File? get titleImage => _titleImage;
  File? get titlePdf => _titlePdf;

  // ─── Perfil ────────────────────────────────────────────────────

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

  // ─── Carnet de identidad ───────────────────────────────────────

  void setIdFrontImage(File image) {
    _idFrontImage = image;
    notifyListeners();
  }

  void clearIdFrontImage() {
    _idFrontImage = null;
    notifyListeners();
  }

  void setIdBackImage(File image) {
    _idBackImage = image;
    notifyListeners();
  }

  void clearIdBackImage() {
    _idBackImage = null;
    notifyListeners();
  }

  // ─── Antecedentes penales ─────────────────────────────────────

  void setCriminalRecordImage(File image) {
    _criminalRecordImage = image;
    _criminalRecordPdf = null;
    notifyListeners();
  }

  void clearCriminalRecordImage() {
    _criminalRecordImage = null;
    notifyListeners();
  }

  void setCriminalRecordPdf(File pdf) {
    _criminalRecordPdf = pdf;
    _criminalRecordImage = null;
    notifyListeners();
  }

  void clearCriminalRecordPdf() {
    _criminalRecordPdf = null;
    notifyListeners();
  }

  // ─── Certificados profesionales (múltiples) ───────────────────

  /// Agrega una imagen de certificado y notifica.
  void addCertificateImage(File image) {
    _certificateImages.add(image);
    notifyListeners();
  }

  /// Elimina todas las imágenes de certificado.
  void clearAllCertificateImages() {
    _certificateImages.clear();
    notifyListeners();
  }

  /// Agrega un PDF de certificado y notifica.
  void addCertificatePdf(File pdf) {
    _certificatePdfs.add(pdf);
    notifyListeners();
  }

  /// Elimina todos los PDFs de certificado.
  void clearAllCertificatePdfs() {
    _certificatePdfs.clear();
    notifyListeners();
  }

  // ─── Título profesional / matrícula (uno) ─────────────────────

  void setTitleImage(File image) {
    _titleImage = image;
    _titlePdf = null;
    notifyListeners();
  }

  void clearTitleImage() {
    _titleImage = null;
    notifyListeners();
  }

  void setTitlePdf(File pdf) {
    _titlePdf = pdf;
    _titleImage = null;
    notifyListeners();
  }

  void clearTitlePdf() {
    _titlePdf = null;
    notifyListeners();
  }

  // ─── Inicializar desde datos existentes ────────────────────────

  /// Población inicial usando listas en lugar de CSV
  void initFromRegistrationData(RegistrationData data) {
    // Perfil
    if (data.imagePath.isNotEmpty) {
      _profileImage = File(data.imagePath);
      _isProfileImageCaptured = true;
    }

    // Carnet
    if (data.idDocumentImagePath.isNotEmpty) {
      _idFrontImage = File(data.idDocumentImagePath);
    }
    if (data.idDocumentImagePath2.isNotEmpty) {
      _idBackImage = File(data.idDocumentImagePath2);
    }

    // Penales
    if (data.criminalRecordImagePath.isNotEmpty) {
      final p = data.criminalRecordImagePath;
      if (p.toLowerCase().endsWith('.pdf')) {
        _criminalRecordPdf = File(p);
      } else {
        _criminalRecordImage = File(p);
      }
    }

    // Certificados (lista de rutas)
    for (final p in data.certificateImagePaths) {
      if (p.toLowerCase().endsWith('.pdf')) {
        _certificatePdfs.add(File(p));
      } else {
        _certificateImages.add(File(p));
      }
    }

    // Título profesional
    if (data.professionalTitleImagePath.isNotEmpty) {
      final p = data.professionalTitleImagePath;
      if (p.toLowerCase().endsWith('.pdf')) {
        _titlePdf = File(p);
      } else {
        _titleImage = File(p);
      }
    }

    notifyListeners();
  }
}
