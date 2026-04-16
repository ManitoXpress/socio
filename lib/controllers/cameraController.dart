import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraHelper {
  late CameraController _cameraController;

  CameraController get cameraController => _cameraController;

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      await _cameraController.initialize();
    } catch (e) {
    }
  }


  Future<CameraDescription> getCamera(CameraLensDirection direction) async {
    final cameras = await availableCameras();
    return cameras.firstWhere((camera) => camera.lensDirection == direction);
  }

  Future<void> toggleCamera() async {
    try {
      final lensDirection = _cameraController.description.lensDirection;
      CameraDescription newCamera;

      if (lensDirection == CameraLensDirection.front) {
        newCamera = await getCamera(CameraLensDirection.back);
      } else {
        newCamera = await getCamera(CameraLensDirection.front);
      }

      // Detenemos la vista previa actual antes de cambiar la cámara
      if (_cameraController.value.isStreamingImages) {
        await _cameraController.stopImageStream();
      }

      // Esperamos un breve momento para asegurarnos de que la vista previa actual se detenga correctamente
      await Future.delayed(const Duration(milliseconds: 500));

      await _cameraController.dispose();
      _cameraController = CameraController(newCamera, ResolutionPreset.high);

      // Inicializamos la nueva cámara después de cambiar
      await _cameraController.initialize();

      // Reiniciamos la vista previa después de la transición
      await _cameraController.startImageStream((CameraImage image) {
        // Puedes realizar acciones con cada frame de la cámara si es necesario
      });
    } catch (e) {
    }
  }





  Future<void> startCameraPreview(Function(CameraImage) onImageAvailable) async {
    try {
      await _cameraController.startImageStream(onImageAvailable);
    } catch (e) {
    }
  }

  Future<void> stopCameraPreview() async {
    try {
      await _cameraController.stopImageStream();
    } catch (e) {
    }
  }

  Future<XFile?> takePicture({Duration? timeout}) async {
    try {
      // Tomar la foto
      final XFile? file = await _cameraController.takePicture();

      // Cerrar la cámara después de tomar la foto
      await _cameraController.dispose();

      return file;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _cameraController.dispose();
  }
}