import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FileManager {
  static final FileManager _instance = FileManager._internal();
  final Uuid _uuid = const Uuid();

  factory FileManager() {
    return _instance;
  }

  FileManager._internal();

  /// Guarda un archivo (imagen o PDF) y devuelve la ruta donde se guardó
  Future<String> saveFile(File file) async {
    try {
      // Obtener el directorio de documentos de la aplicación
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      // Crear un ID único para el archivo
      final String uniqueId = _uuid.v4();

      // Obtener la extensión del archivo original
      final String extension = path.extension(file.path);

      // Crear una nueva ruta para el archivo con nombre único
      final String newFilePath = path.join(appDocPath, 'certificate_$uniqueId$extension');

      // Copiar el archivo a la nueva ubicación
      final File newFile = await file.copy(newFilePath);

      print('Archivo guardado exitosamente en: ${newFile.path}');
      return newFile.path;
    } catch (e) {
      print('Error al guardar el archivo: $e');
      // Si ocurre un error, devolvemos la ruta original
      return file.path;
    }
  }

  /// Guarda un PDF específicamente, asegurando que tenga la extensión correcta
  Future<String> savePdf(File pdfFile) async {
    try {
      // Verificar que el archivo sea un PDF
      if (!path.extension(pdfFile.path).toLowerCase().endsWith('.pdf')) {
        throw Exception('El archivo no es un PDF válido');
      }

      // Obtener el directorio de documentos de la aplicación
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;

      // Crear un ID único para el archivo
      final String uniqueId = _uuid.v4();

      // Crear una nueva ruta para el archivo con nombre único
      final String newFilePath = path.join(appDocPath, 'certificate_pdf_$uniqueId.pdf');

      // Copiar el archivo a la nueva ubicación
      final File newFile = await pdfFile.copy(newFilePath);

      print('PDF guardado exitosamente en: ${newFile.path}');
      return newFile.path;
    } catch (e) {
      print('Error al guardar el PDF: $e');
      // Si ocurre un error, devolvemos la ruta original
      return pdfFile.path;
    }
  }

  /// Elimina un archivo si existe
  Future<bool> deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Archivo eliminado exitosamente: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar el archivo: $e');
      return false;
    }
  }
}