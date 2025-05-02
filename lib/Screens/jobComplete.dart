import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camera/camera.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';

class Step9FormData {
  final List<String> jobCompleteImagePaths;
  Step9FormData({required this.jobCompleteImagePaths});
}

class PhotoStep extends StatefulWidget {
  final Function(Step9FormData) onImagesSelected;
  final RegistrationController registrationController;
  final VoidCallback onNextStep;
  final RegistrationData registrationData;
  final UserData userData;

  PhotoStep({
    required this.onImagesSelected,
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _PhotoStepState createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  List<XFile> capturedImages = [];
  bool _isCameraReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController.initialize();

      await _initializeControllerFuture;

      setState(() {
        _isCameraReady = true;
      });

      print("Cámara inicializada correctamente");
    } catch (e) {
      print("Error al inicializar la cámara: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Saque fotos a su trabajo terminado",
              style: MyTextStyles.formServiceTextStyle,
            ),
          ),
          Container(
            height: 300,
            width: double.maxFinite,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _isCameraReady ? _captureAndShowImage : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: _isCameraReady
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              CameraPreview(_cameraController),
                            ],
                          )
                        : Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed:
                _isCameraReady && !_isCapturing ? _captureAndShowImage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF830A09),
            ),
            child: Text(
              "Capturar Imagen",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          if (capturedImages.isNotEmpty)
            ElevatedButton(
              onPressed: _isCameraReady && !_isCapturing
                  ? _showDeleteImageConfirmation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF830A09),
              ),
              child: Text(
                "Eliminar Imagen Seleccionada",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          // Muestra las miniaturas en grupos de tres
          if (capturedImages.isNotEmpty)
            Container(
              height: 100.0, // Altura de las miniaturas
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: capturedImages.map((image) {
                    return Container(
                      width: (screenWidth - 32) / 3,
                      margin: EdgeInsets.only(right: 8.0),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          // Botón Completar Trabajo
          ElevatedButton(
            onPressed: capturedImages.isNotEmpty
                ? _showCompleteWorkConfirmation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF84090D),
            ),
            child: Text(
              "Completar Trabajo",
              style: MyTextStyles.buttonTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteWorkConfirmation() {
    TextEditingController observationsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Confirmación",
            style: MyTextStyles.welcomeTotheJungle,
          ),
          content: Column(
            children: [
              Text(
                "¿Deseas finalizar el trabajo y estar de acuerdo con el pago?",
                style: MyTextStyles.drawerButtonTextStyle5,
              ),
              SizedBox(height: 20),
              TextField(
                controller: observationsController,
                style: MyTextStyles.inputTextStyle,
                decoration: InputDecoration(
                  labelText: "Observaciones",
                  hintText:
                      "Por favor, indique las observaciones o inconvenientes que tuvo durante la realización del trabajo",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusColor: Color(0xFF830A09),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF830A09),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Coloca aquí la lógica para confirmar el trabajo
                      _completeWork(observationsController.text);
                      Navigator.of(dialogContext).pop(); // Cerrar el diálogo
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFC3543),
                    ),
                    child: Text(
                      "Confirmar",
                      style: MyTextStyles.buttonTextStyle,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Cerrar el diálogo
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text(
                      "Cancelar",
                      style: MyTextStyles.buttonTextStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeWork(String text) {
    // Aquí puedes agregar la lógica para enviar la información al backend
    // Puedes utilizar widget.registrationController, widget.registrationData, widget.userData, etc.
    // para obtener la información necesaria y enviarla al backend
    // ...
    // Después de completar el trabajo, puedes realizar alguna acción como navegar a la siguiente pantalla.

    // Cerrar ambos cuadros de diálogo
    Navigator.of(context, rootNavigator: true)
        .pop('complete'); // Cerrar cuadro de diálogo de confirmación
    Navigator.of(context)
        .pop(); // Cerrar cuadro de diálogo del formulario de servicio
    widget.onNextStep();
  }

  Future<void> _captureAndShowImage() async {
    try {
      // Bloquear la captura si ya está en progreso
      if (_isCapturing) return;

      // Marcar como captura en progreso
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController.takePicture();
      print("Foto capturada en: ${image.path}");

      // Guardar la imagen
      setState(() {
        capturedImages.add(image);
      });
      widget.onImagesSelected(Step9FormData(
          jobCompleteImagePaths:
              capturedImages.map((image) => image.path).toList()));

      widget.registrationController.updateRegistrationData(
        jobCompletePath: capturedImages.isNotEmpty ? capturedImages.last.path : '',
        jobCompletePaths:
            capturedImages.map((image) => image.path).toList(),
        idDocumentImagePath: '',
        workerType: '',
        idDocumentImagePath2: '',
        certificateImagePaths: [],
        criminalRecordImagePath: '',
        referralCode: '',
        medicalLicenseImagePath: '', // Provide the appropriate value here
        professionalTitleImagePath: '', // Provide the appropriate value here
      );
    } catch (e) {
      print("Error al tomar la foto: $e");
    } finally {
      // Marcar como captura finalizada
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showDeleteImageConfirmation() {
    showDialog(
      context: context, // Asegúrate de usar el contexto actual
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Eliminar Imagen Seleccionada"),
          content: Text("¿Desea eliminar la imagen seleccionada?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF84090D),
              ),
              child: Text(
                "Cancelar",
                style: MyTextStyles.buttonTextStyle,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  capturedImages
                      .removeLast(); // Eliminar la última imagen capturada
                });
                widget.onImagesSelected(Step9FormData(
                    jobCompleteImagePaths:
                        capturedImages.map((image) => image.path).toList()));
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF84090D),
              ),
              child: Text(
                "Eliminar",
                style: MyTextStyles.buttonTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
