import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:socio/ServiceResponse/request.dart';
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
        _isImageSelected = true; // Indicamos que la imagen ha sido seleccionada
      });
    } else {
      print('No se seleccionó ninguna imagen.');
    }
  }

  void _completeJob() async {
    print('Completar trabajo');
    if (_selectedImageUrl != null) {
      print('Imagen para subir: $_selectedImageUrl');

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
        // Subir la imagen a Firebase Storage
        File imageFile = File(_selectedImageUrl!);
        String fileName = 'completion_${serviceRequest.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImageUrl!)}';
        Reference storageRef = FirebaseStorage.instance.ref().child('completion_images/$fileName');

        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;

        // Obtener la URL de la imagen subida
        String imageUrl = await taskSnapshot.ref.getDownloadURL();
        print('Imagen subida exitosamente. URL: $imageUrl');

        // Buscar la oferta correspondiente al serviceId
        final querySnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('serviceId', isEqualTo: serviceRequest.id)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Obtener el ID del documento de la oferta
          String offerId = querySnapshot.docs.first.id;

          // Actualizar el documento de la oferta con la URL de la imagen
          await FirebaseFirestore.instance
              .collection('offers')
              .doc(offerId)
              .update({'completionImageUrl': imageUrl});

          print('Oferta actualizada con la URL de la imagen');
        } else {
          print('No se encontró una oferta para el serviceId proporcionado');
        }

        // Actualizar estado a "pending_confirmation" mientras se espera la confirmación del cliente
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
          SnackBar(content: Text('Trabajo completado y esperando confirmación del cliente')),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Cerrar el indicador de carga
        print('Error al completar el trabajo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al completar el trabajo. Por favor, intenta de nuevo.')),
        );
      }
    } else {
      print('No se seleccionó ninguna imagen.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona una imagen antes de completar el trabajo.')),
      );
    }
  }

  void show() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Completar Trabajo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      '¿Estás seguro de que deseas completar este trabajo? envie una imagen de su trabajo terminado para confirmar el pago del servicio.'),
                  SizedBox(height: 16.0),
                  _selectedImageUrl == null
                      ? ElevatedButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Seleccionar Imagen'),
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
                                    child: Text('Seleccionar Imagen'),
                                  ),
                                ],
                              );
                            },
                          ),
                          child: Text('Seleccionar Imagen'),
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
                            Text('Imagen seleccionada', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _completeJob,
                  child: Text('Completar Trabajo'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
