import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'package:path/path.dart' as path;

class CompleteJobDialog {
  final BuildContext context;
  final ServiceRequest serviceRequest;
  final Function(String) onStatusChanged;

  CompleteJobDialog({
    required this.context,
    required this.serviceRequest,
    required this.onStatusChanged,
  });

  String? _selectedImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isImageSelected = false;

  void _pickImage(ImageSource source, StateSetter setState) async {
    print('Abriendo el selector de imágenes...');
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      print('Imagen seleccionada: ${pickedFile.path}');
      setState(() {
        _selectedImageUrl = pickedFile.path;
        _isImageSelected = true;
      });
    } else {
      print('No se seleccionó ninguna imagen.');
    }
  }

  void _completeJob() async {
    print('Completar trabajo');
    if (_selectedImageUrl != null) {
      print('Imagen para subir: $_selectedImageUrl');

      // Verificar si el usuario está autenticado
      if (FirebaseAuth.instance.currentUser == null) {
        print('Usuario no autenticado');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debes iniciar sesión para completar el trabajo.')),
        );
        return;
      }

      // Verificar si el usuario es un trabajador
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        print('El usuario no es un trabajador');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debes ser un trabajador para completar el trabajo.')),
        );
        return;
      }

      // Mostrar el indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Enviando datos...'),
              ],
            ),
          );
        },
      );

      try {
        File imageFile = File(_selectedImageUrl!);
        String fileName =
            'completion_${serviceRequest.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImageUrl!)}';
        Reference storageRef =
            FirebaseStorage.instance.ref().child('completion_images/$fileName');

        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;

        String imageUrl = await taskSnapshot.ref.getDownloadURL();
        print('Imagen subida exitosamente. URL: $imageUrl');

        final querySnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('serviceId', isEqualTo: serviceRequest.id)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String offerId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('offers')
              .doc(offerId)
              .update({
            'completionImageUrl': imageUrl,
            'status': 'pending_confirmation',
          });

          print('Oferta actualizada con la URL de la imagen');
        }

        await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceRequest.id)
            .update({
          'status': 'pending_confirmation',
          'completionImageUrl': imageUrl,
        });

        onStatusChanged('pending_confirmation');
        Navigator.of(context).pop(); // Cerrar el indicador de carga
        Navigator.of(context).pop(); // Cerrar el diálogo

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Trabajo completado y esperando confirmación del cliente')),
        );
      } catch (e) {
        Navigator.of(context).pop();
        print('Error al completar el trabajo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al completar el trabajo. Por favor, intenta de nuevo.')),
        );
      }
    } else {
      print('No se seleccionó ninguna imagen.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Por favor, selecciona una imagen antes de completar el trabajo.')),
      );
    }
  }

  // Llamar a este método cuando el estado sea pending_confirmation2
  void show() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Completar Trabajo',
                style: MyTextStyles.linkTextStyle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Estás seguro de que deseas completar este trabajo? Envíe una imagen de su trabajo terminado para confirmar el pago del servicio.',
                    style: MyTextStyles.ButtonTextStyle,
                  ),
                  SizedBox(height: 16.0),
                  _selectedImageUrl == null
                      ? ElevatedButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  'Seleccionar Imagen',
                                  style: MyTextStyles.tittleButton,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _pickImage(ImageSource.camera, setState);
                                    },
                                    child: Text('Capturar Foto'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _pickImage(ImageSource.gallery, setState);
                                    },
                                    child: Text(
                                      'Seleccionar Imagen',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          child: Text(
                            'Seleccionar Imagen',
                            style: MyTextStyles.tittleButton,
                          ),
                        )
                      : Column(
                          children: [
                            Image.file(
                              File(_selectedImageUrl!),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Imagen seleccionada',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.dangerous, color: Color(0xFF84090D)),
                  label: Text(
                    "Cancelar",
                    style: GoogleFonts.karla(
                      color: Color(0xFF84090D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _completeJob,
                  icon: Icon(Icons.check_circle, color: Color(0xFF84090D)),
                  label: Text(
                    "Completar Trabajo",
                    style: GoogleFonts.karla(
                      color: Color(0xFF84090D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF84090D),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
     },
    );
  }
}