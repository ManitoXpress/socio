import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/provider/providerRegistration.dart';

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

  final List<String> qrOptions = ['Marque aqui', 'SI', 'NO'];
  final List<String> invoiceOptions = ['Marque aqui', 'SI', 'NO'];

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<RegistrationProvider>(context, listen: false);
    fullNameController = TextEditingController(text: prov.registrationData.displayName);
    idCardController = TextEditingController(text: prov.registrationData.idCardNumber);
    phoneController = TextEditingController(text: prov.registrationData.phoneNumber);
    referralController = TextEditingController(text: prov.registrationData.referralCode);
  }

  bool _isValid() {
    return fullNameController.text.isNotEmpty &&
        idCardController.text.isNotEmpty &&
        phoneController.text.isNotEmpty;
  }

  Future<void> _verifyReferralCode(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, ingrese un código de referido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido válido.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        prov.registrationData.referralCode = '';
        prov.userData.referralCode = '';
        prov.notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido inválido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar el código de referido.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<RegistrationProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            "Paso 1: Rellena el formulario con tus datos",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
          SizedBox(height: 20),
          _buildStyledTextField(
            controller: fullNameController,
            hintText: "Nombre completo",
            onChanged: (value) {
              prov.registrationData.displayName = value;
              prov.notifyListeners();
            },
          ),
          SizedBox(height: 20),
          _buildStyledTextField(
            controller: idCardController,
            hintText: "Documento de Identidad (NIT, CI, etc.)",
            keyboardType: TextInputType.text,
            onChanged: (value) {
              prov.registrationData.idCardNumber = value;
              prov.notifyListeners();
            },
          ),
          SizedBox(height: 20),
          _buildStyledTextField(
            controller: phoneController,
            hintText: "Número de Teléfono",
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              if (!value.startsWith('+591')) {
                value = '+591$value';
                phoneController.text = value;
                phoneController.selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length),
                );
              }
              prov.registrationData.phoneNumber = value;
              prov.notifyListeners();
            },
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStyledTextField(
                  controller: referralController,
                  hintText: "Código de Referido (opcional)",
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _verifyReferralCode(referralController.text),
                child: Text('Verificar', style: MyTextStyles.drawerButtonLabelTextStyle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF830A09),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildStyledDropdown(
            label: '¿Aceptaría recibir pagos con QR?',
            value: prov.registrationData.paymentType.isEmpty ? qrOptions[0] : prov.registrationData.paymentType,
            options: qrOptions,
            onChanged: (value) {
              prov.registrationData.paymentType = value!;
              prov.notifyListeners();
            },
          ),
          SizedBox(height: 20),
          _buildStyledDropdown(
            label: '¿Emite factura?',
            value: prov.registrationData.verificationStatus.isEmpty ? invoiceOptions[0] : prov.registrationData.verificationStatus,
            options: invoiceOptions,
            onChanged: (value) {
              prov.registrationData.verificationStatus = value!;
              prov.notifyListeners();
            },
          ),
          SizedBox(height: 20),
          if (!_isValid())
            Text(
              'Completa todos los campos obligatorios.',
              style: TextStyle(color: Color(0xFF830A09)),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: MyTextStyles.inputTextStyle,
      cursorColor: Color(0xFF830A09),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF830A09)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MyTextStyles.inputTextStyle.copyWith(color: Color(0xFF830A09))),
        SizedBox(height: 5),
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            onChanged: onChanged,
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            style: MyTextStyles.inputTextStyle,
          ),
        ),
      ],
    );
  }
}
