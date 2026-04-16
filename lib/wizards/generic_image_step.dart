import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socio/Utils/styles.dart';

class GenericImageStep extends StatefulWidget {
  final String title;
  final String initialImagePath;
  final Function(String path) onImageProcessed;
  final File? displayImage;

  const GenericImageStep({
    Key? key,
    required this.title,
    required this.initialImagePath,
    required this.onImageProcessed,
    required this.displayImage,
  }) : super(key: key);

  @override
  _GenericImageStepState createState() => _GenericImageStepState();
}

class _GenericImageStepState extends State<GenericImageStep> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        widget.onImageProcessed(image.path);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se capturó ninguna imagen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo acceder a la cámara. Verifique los permisos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
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
            child: widget.displayImage == null
                ? const Center(
                    child: Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Color(0xA3C9D2D2),
                    ),
                  )
                : Image.file(
                    widget.displayImage!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (widget.displayImage == null)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Saca una foto antes de continuar.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          ),
      ],
    );
  }
} 