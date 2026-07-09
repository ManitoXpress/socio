import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:provider/provider.dart';
import '../provider/providerImage.dart';

/// Paso combinado: Antecedentes Penales + Certificados + Título Profesional
class DocsAndCertificatesStep extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function(String criminalPath) onCriminalSelected;
  final void Function(List<String> certPaths) onCertificatesSelected;
  final ValueNotifier<bool> isImageCaptured;
  final RegistrationData registrationData;
  final UserData userData;
  final String criminalRecordImagePath;
  final List<String> certificateImagePaths;
  final void Function() onNextStep;

  const DocsAndCertificatesStep({
    Key? key,
    required this.registrationController,
    required this.onCriminalSelected,
    required this.onCertificatesSelected,
    required this.isImageCaptured,
    required this.registrationData,
    required this.userData,
    required this.criminalRecordImagePath,
    required this.certificateImagePaths,
    required this.onNextStep,
  }) : super(key: key);

  @override
  State<DocsAndCertificatesStep> createState() =>
      _DocsAndCertificatesStepState();
}

class _DocsAndCertificatesStepState extends State<DocsAndCertificatesStep> {
  File? _criminalFile;
  final List<File> _certificateFiles = [];
  File? _titleFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.criminalRecordImagePath.isNotEmpty) {
      _criminalFile = File(widget.criminalRecordImagePath);
    }
    for (final p in widget.certificateImagePaths) {
      _certificateFiles.add(File(p));
    }
  }

  // ── ANTECEDENTES ────────────────────────────────────────────────

  Future<void> _pickCriminal() async {
    await _showPickDialog(
      title: 'Antecedentes penales',
      allowPdf: true,
      onPicked: (file) {
        setState(() => _criminalFile = file);
        widget.onCriminalSelected(file.path);
        widget.registrationController.updateRegistrationData(
          idDocumentImagePath: '',
          workerType: '',
          idDocumentImagePath2: '',
          certificateImagePaths: _certPaths(),
          criminalRecordImagePath: file.path,
          referralCode: '',
          medicalLicenseImagePath: '',
          professionalTitleImagePath: _titleFile?.path ?? '',
          jobCompletePath: '',
          jobCompletePaths: [],
        );
        final imgProv =
            Provider.of<ImageStateProvider>(context, listen: false);
        if (file.path.toLowerCase().endsWith('.pdf')) {
          imgProv.setCriminalRecordPdf(file);
        } else {
          imgProv.setCriminalRecordImage(file);
        }
        _refreshCaptured();
      },
    );
  }

  // ── CERTIFICADOS ────────────────────────────────────────────────

  Future<void> _pickCertificate() async {
    await _showPickDialog(
      title: 'Certificado',
      allowPdf: true,
      onPicked: (file) {
        setState(() => _certificateFiles.add(file));
        _notifyCerts();
        final imgProv =
            Provider.of<ImageStateProvider>(context, listen: false);
        if (file.path.toLowerCase().endsWith('.pdf')) {
          imgProv.addCertificatePdf(file);
        } else {
          imgProv.addCertificateImage(file);
        }
        _refreshCaptured();
      },
    );
  }

  void _removeCertificate(File file) {
    setState(() => _certificateFiles.remove(file));
    _notifyCerts();
    _refreshCaptured();
  }

  // ── TÍTULO PROFESIONAL ──────────────────────────────────────────

  Future<void> _pickTitle() async {
    await _showPickDialog(
      title: 'Título profesional / Matrícula',
      allowPdf: true,
      onPicked: (file) {
        setState(() => _titleFile = file);
        _notifyCerts();
        final imgProv =
            Provider.of<ImageStateProvider>(context, listen: false);
        if (file.path.toLowerCase().endsWith('.pdf')) {
          imgProv.setTitlePdf(file);
        } else {
          imgProv.setTitleImage(file);
        }
        _refreshCaptured();
      },
    );
  }

  void _removeTitle() {
    setState(() => _titleFile = null);
    _notifyCerts();
    _refreshCaptured();
  }

  // ── HELPERS ─────────────────────────────────────────────────────

  List<String> _certPaths() =>
      _certificateFiles.map((f) => f.path).toList();

  void _notifyCerts() {
    final paths = _certPaths();
    widget.onCertificatesSelected(paths);
    widget.registrationController.updateRegistrationData(
      idDocumentImagePath: '',
      workerType: '',
      idDocumentImagePath2: '',
      certificateImagePaths: paths,
      criminalRecordImagePath: _criminalFile?.path ?? '',
      referralCode: '',
      medicalLicenseImagePath: '',
      professionalTitleImagePath: _titleFile?.path ?? '',
      jobCompletePath: '',
      jobCompletePaths: [],
    );
  }

  void _refreshCaptured() {
    widget.isImageCaptured.value = _criminalFile != null;
  }

  Future<void> _showPickDialog({
    required String title,
    required bool allowPdf,
    required void Function(File) onPicked,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Xpress',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona cómo cargar el documento',
              style: TextStyle(
                fontFamily: 'Xpress',
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            _sheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Tomar foto',
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img =
                    await _picker.pickImage(source: ImageSource.camera);
                if (img != null) onPicked(File(img.path));
              },
            ),
            const SizedBox(height: 10),
            _sheetOption(
              icon: Icons.folder_open_outlined,
              label: 'Seleccionar archivo (PDF / imagen)',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions:
                      allowPdf ? ['pdf', 'jpg', 'jpeg', 'png'] : ['jpg', 'jpeg', 'png'],
                );
                if (result != null &&
                    result.files.single.path != null) {
                  onPicked(File(result.files.single.path!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF830A09).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF830A09), size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Xpress',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SECCIÓN 1: ANTECEDENTES PENALES ──
        _buildSectionHeader(
          icon: Icons.gavel_outlined,
          title: 'Antecedentes penales',
          subtitle: 'Foto o PDF del documento oficial',
          required: true,
        ),
        const SizedBox(height: 12),
        _buildUploadCard(
          file: _criminalFile,
          emptyIcon: Icons.upload_file_outlined,
          emptyLabel: 'Subir antecedentes',
          onTap: _pickCriminal,
          onRemove: () => setState(() {
            _criminalFile = null;
            _refreshCaptured();
          }),
        ),

        const SizedBox(height: 24),
        Divider(color: Colors.grey[200]),
        const SizedBox(height: 16),

        // ── SECCIÓN 2: CERTIFICADOS ──
        _buildSectionHeader(
          icon: Icons.workspace_premium_outlined,
          title: 'Certificados',
          subtitle: 'Imágenes o PDFs (opcional)',
          required: false,
        ),
        const SizedBox(height: 12),
        // Grid de certificados
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._certificateFiles.map(
              (f) => _buildThumbnail(f, onRemove: () => _removeCertificate(f)),
            ),
            _buildAddTile(onTap: _pickCertificate),
          ],
        ),

        const SizedBox(height: 24),
        Divider(color: Colors.grey[200]),
        const SizedBox(height: 16),

        // ── SECCIÓN 3: TÍTULO PROFESIONAL ──
        _buildSectionHeader(
          icon: Icons.school_outlined,
          title: 'Título profesional / Matrícula',
          subtitle: 'Opcional',
          required: false,
        ),
        const SizedBox(height: 12),
        _buildUploadCard(
          file: _titleFile,
          emptyIcon: Icons.file_present_outlined,
          emptyLabel: 'Subir título o matrícula',
          onTap: _pickTitle,
          onRemove: _removeTitle,
        ),

        const SizedBox(height: 16),

        // Aviso campos obligatorios
        if (_criminalFile == null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF830A09).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline,
                    color: Color(0xFF830A09), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los antecedentes penales son obligatorios para continuar.',
                    style: TextStyle(
                      color: Color(0xFF830A09),
                      fontFamily: 'Xpress',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool required,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF830A09).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF830A09), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Xpress',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (required) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFF830A09),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Xpress',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card de carga única (antecedentes / título)
  Widget _buildUploadCard({
    required File? file,
    required IconData emptyIcon,
    required String emptyLabel,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null;
    final bool isPdf = hasFile && file.path.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
            color: hasFile
              ? const Color(0xFF830A09).withOpacity(0.05)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? const Color(0xFF830A09).withOpacity(0.4)
                : Colors.grey[300]!,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  const SizedBox(width: 16),
                  // Thumbnail o icono PDF
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isPdf
                          ? const Icon(Icons.picture_as_pdf,
                              color: Colors.red, size: 32)
                          : Image.file(file, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle,
                                color: Color(0xFF830A09), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Documento cargado',
                              style: TextStyle(
                                fontFamily: 'Xpress',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF830A09),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Xpress',
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón eliminar
                  GestureDetector(
                    onTap: onRemove,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(Icons.close,
                          color: Colors.grey[400], size: 20),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, color: Colors.grey[400], size: 24),
                  const SizedBox(width: 10),
                  Text(
                    emptyLabel,
                    style: TextStyle(
                      fontFamily: 'Xpress',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Thumbnail para la lista de certificados
  Widget _buildThumbnail(File file, {required VoidCallback onRemove}) {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isPdf
                ? const Center(
                    child: Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 36),
                  )
                : Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close,
                  color: Color(0xFF830A09), size: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Tile de "agregar"
  Widget _buildAddTile({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF830A09).withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid),
            color: const Color(0xFF830A09).withOpacity(0.04),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: const Color(0xFF830A09).withOpacity(0.6), size: 28),
            const SizedBox(height: 2),
            Text(
              'Agregar',
              style: TextStyle(
                fontFamily: 'Xpress',
                fontSize: 10,
                color: const Color(0xFF830A09).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
