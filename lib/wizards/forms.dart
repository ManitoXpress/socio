import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/providerRegistration.dart';


class ServiceDataWizard extends StatefulWidget {
  final VoidCallback onNextStep;

  const ServiceDataWizard({
    Key? key,
    required this.onNextStep,
  }) : super(key: key);

  @override
  _ServiceDataWizardState createState() => _ServiceDataWizardState();
}

class _ServiceDataWizardState extends State<ServiceDataWizard> {
  late TextEditingController fullNameController;
  late TextEditingController idCardController;
  late TextEditingController phoneController;
  late TextEditingController referralController;

  bool _referralVerified = false;
  bool _verifyingReferral = false;

  final List<String> qrOptions = ['Marque aqui', 'SI', 'NO'];
  final List<String> invoiceOptions = ['Marque aqui', 'SI', 'NO'];

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<RegistrationProvider>(context, listen: false);

    fullNameController =
        TextEditingController(text: prov.registrationData.displayName);
    idCardController =
        TextEditingController(text: prov.registrationData.idCardNumber);
    phoneController =
        TextEditingController(text: prov.registrationData.phoneNumber);
    referralController =
        TextEditingController(text: prov.registrationData.referralCode);

    if (!qrOptions.contains(prov.registrationData.paymentType)) {
      prov.registrationData.paymentType = qrOptions[0];
    }
    if (!invoiceOptions.contains(prov.registrationData.verificationStatus)) {
      prov.registrationData.verificationStatus = invoiceOptions[0];
    }
    prov.notifyListeners();
  }

  bool _isValid() {
    return fullNameController.text.trim().isNotEmpty &&
        idCardController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty;
  }

  Future<void> _verifyReferralCode(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese un código de referido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _verifyingReferral = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('workers')
          .where('codeReferral', isEqualTo: code)
          .limit(1)
          .get();
      final prov = Provider.of<RegistrationProvider>(context, listen: false);
      if (snapshot.docs.isNotEmpty) {
        prov.registrationData.referralCode = code;
        prov.userData.referralCode = snapshot.docs.first.id;
        prov.notifyListeners();
        setState(() => _referralVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Código de referido válido.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        prov.registrationData.referralCode = '';
        prov.userData.referralCode = '';
        prov.notifyListeners();
        setState(() => _referralVerified = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de referido inválido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al verificar el código de referido.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _verifyingReferral = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<RegistrationProvider>(context);

    final safePaymentType = qrOptions.contains(prov.registrationData.paymentType)
        ? prov.registrationData.paymentType
        : qrOptions[0];
    final safeVerificationStatus =
        invoiceOptions.contains(prov.registrationData.verificationStatus)
            ? prov.registrationData.verificationStatus
            : invoiceOptions[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sección
        _buildSectionHeader(
          icon: Icons.person_outline,
          title: 'Datos personales',
          subtitle: 'Ingresa tu información básica',
        ),
        const SizedBox(height: 20),

        // Nombre completo
        _buildLabeledField(
          label: 'Nombre completo *',
          child: _buildTextField(
            controller: fullNameController,
            hint: 'Ej: Juan Pérez',
            icon: Icons.badge_outlined,
            onChanged: (v) {
              prov.registrationData.displayName = v;
              prov.notifyListeners();
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 16),

        // Documento
        _buildLabeledField(
          label: 'Documento de identidad *',
          child: _buildTextField(
            controller: idCardController,
            hint: 'NIT, CI, Pasaporte...',
            icon: Icons.credit_card_outlined,
            onChanged: (v) {
              prov.registrationData.idCardNumber = v;
              prov.notifyListeners();
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 16),

        // Teléfono
        _buildLabeledField(
          label: 'Número de teléfono *',
          child: _buildTextField(
            controller: phoneController,
            hint: '+591 700000000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (v) {
              if (!v.startsWith('+591')) {
                v = '+591$v';
                phoneController.text = v;
                phoneController.selection = TextSelection.fromPosition(
                  TextPosition(offset: v.length),
                );
              }
              prov.registrationData.phoneNumber = v;
              prov.notifyListeners();
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[200])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Opcional',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Xpress',
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[200])),
          ],
        ),
        const SizedBox(height: 16),

        // Código de referido inline
        _buildLabeledField(
          label: 'Código de referido',
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: referralController,
                  hint: 'Ingresa el código',
                  icon: _referralVerified
                      ? Icons.check_circle_outline
                      : Icons.card_giftcard_outlined,
                  iconColor:
                      _referralVerified ? Colors.green : null,
                ),
              ),
              const SizedBox(width: 10),
              _verifyingReferral
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF830A09),
                      ),
                    )
                  : GestureDetector(
                      onTap: () =>
                          _verifyReferralCode(referralController.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF830A09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Xpress',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Toggles QR / Factura — más compactos como segmented buttons
        _buildLabeledField(
          label: '¿Acepta pagos con QR?',
          child: _buildSegmentedSelector(
            options: qrOptions.sublist(1),
            selected: safePaymentType,
            onSelected: (v) {
              prov.registrationData.paymentType = v;
              prov.notifyListeners();
            },
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: '¿Emite factura?',
          child: _buildSegmentedSelector(
            options: invoiceOptions.sublist(1),
            selected: safeVerificationStatus,
            onSelected: (v) {
              prov.registrationData.verificationStatus = v;
              prov.notifyListeners();
            },
          ),
        ),
        const SizedBox(height: 16),

        // Validación
        AnimatedOpacity(
          opacity: !_isValid() ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF830A09).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_outlined,
                    color: Color(0xFF830A09), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completa todos los campos obligatorios (*).',
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
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF830A09).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF830A09), size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Xpress',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Xpress',
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledField(
      {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Xpress',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? iconColor,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Xpress',
        fontSize: 14,
        color: Color(0xFF1A1A1A),
      ),
      cursorColor: const Color(0xFF830A09),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Xpress',
          fontSize: 13,
          color: Colors.grey[400],
        ),
        prefixIcon: Icon(icon,
            color: iconColor ?? const Color(0xFF830A09).withOpacity(0.6),
            size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF830A09), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSegmentedSelector({
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
  }) {
    return Row(
      children: options
          .map((opt) => Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected == opt
                          ? const Color(0xFF830A09)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected == opt
                            ? const Color(0xFF830A09)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Xpress',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected == opt
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}