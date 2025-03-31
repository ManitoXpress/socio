import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
import 'package:socio/Utils/styles.dart';
class ServiceDataWizard extends StatefulWidget {
  final RegistrationController registrationController;
  final void Function() onNextStep;
  final RegistrationData registrationData;
  final UserData userData;
  bool isStep1Complete = false;
  String selectedWorkerType = 'Marque aqui';
  late String selectedCountryCode;
  late _Step1FormState _step1FormState;

  bool isStep1Valid() {
    return _step1FormState.isStep1Valid();
  }

  ServiceDataWizard({
    required this.registrationController,
    required this.onNextStep,
    required this.registrationData,
    required this.userData,
  });

  @override
  _Step1FormState createState() {
    _step1FormState = _Step1FormState();
    return _step1FormState;
  }
}

class _Step1FormState extends State<ServiceDataWizard> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController idCardController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  String? verificationId;
  String errorText = '';

  @override
  void initState() {
    super.initState();
    widget.selectedCountryCode = '+591';
  }

  bool isStep1Valid() {
    return fullNameController.text.isNotEmpty &&
        idCardController.text.isNotEmpty &&
        phoneController.text.isNotEmpty;
  }


  Future<void> _verifyReferralCode(String referralCode) async {
    try {
      if (referralCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, ingrese un código de referido.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final workersCollection = FirebaseFirestore.instance.collection('workers');

      // Buscar si existe un trabajador con ese idCardNumber
      final querySnapshot = await workersCollection.where('codeReferral', isEqualTo: referralCode).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Código de referido válido.');
        // Guardamos el ID del trabajador que refirió
        setState(() {
          widget.userData.referrerWorkerId = querySnapshot.docs.first.id;
          widget.userData.referralCode = referralCode;

          // También actualizamos los datos de registro
          widget.registrationController.updateRegistrationData(
              referralCode: referralCode,
              workerType: '',
              idDocumentImagePath: '',
              idDocumentImagePath2: '',
              certificateImagePaths: '',
              criminalRecordImagePath: ''
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido válido.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Código de referido inválido.');
        // Limpiamos el referrerWorkerId si el código es inválido
        setState(() {
          widget.userData.referrerWorkerId = '';
          // Mantenemos el código ingresado por el usuario para que pueda corregirlo
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de referido inválido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al verificar el código de referido: $e');
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
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Text(
            "Paso 1: Rellena el formulario con tus datos",
            style: MyTextStyles.drawerButtonTextStyle2,
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: fullNameController,
                  onTap: () {
                    if (isStep1Valid()) {
                      widget.onNextStep();
                    } else {
                      print(
                          'Complete todos los espacios antes de ir al siguiente paso.');
                    }
                  },
                  onChanged: (value) {
                    setState(() {
                      widget.registrationController.updateRegistrationData(
                          displayName: value,
                          workerType: '',
                          idDocumentImagePath: '',
                          idDocumentImagePath2: '',
                          certificateImagePaths: '',
                          criminalRecordImagePath: '',
                          referralCode: '');
                      widget.userData.displayName = value;
                    });
                  },
                  keyboardType: TextInputType.text,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF830A09),
                  decoration: InputDecoration(
                    hintText: "Nombre completo",
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
                const SizedBox(height: 20),
                TextField(
                  controller: idCardController,
                  onTap: () {},
                  onChanged: (value) {
                    setState(() {
                      widget.registrationController.updateRegistrationData(
                          idCardNumber: value,
                          workerType: '',
                          idDocumentImagePath: '',
                          idDocumentImagePath2: '',
                          certificateImagePaths: '',
                          criminalRecordImagePath: '',
                          referralCode: '');
                      widget.userData.idCardNumber = value;
                    });
                  },
                  keyboardType: TextInputType.phone,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF830A09),
                  decoration: InputDecoration(
                    hintText: "Documento de Identidad",
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
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  onTap: () {},
                  onChanged: (value) {
                    setState(() {
                      // Verifica si el prefijo +591 está presente, si no, lo agrega automáticamente
                      if (!value.startsWith('+591')) {
                        value = '+591$value';
                        phoneController.text =
                            value; // Actualiza el valor del controlador para reflejar el prefijo
                        phoneController.selection = TextSelection.fromPosition(
                          TextPosition(
                              offset: value
                                  .length), // Posiciona el cursor al final del texto
                        );
                      }

                      // Actualiza los datos de registro con el número modificado
                      widget.registrationController.updateRegistrationData(
                          phoneNumber: value,
                          workerType: '',
                          idDocumentImagePath: '',
                          idDocumentImagePath2: '',
                          certificateImagePaths: '',
                          criminalRecordImagePath: '',
                          referralCode: '');
                      widget.userData.phoneNumber = value;
                    });
                  },
                  keyboardType: TextInputType.phone,
                  style: MyTextStyles.inputTextStyle,
                  cursorColor: const Color(0xFF830A09),
                  decoration: InputDecoration(
                    hintText: "Número de Teléfono",
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: referralCodeController,
                        onChanged: (value) {
                          setState(() {
                            // Actualiza los datos de registro con el código de referido
                            widget.registrationController
                                .updateRegistrationData(
                                referralCode: value,
                                workerType: '',
                                idDocumentImagePath: '',
                                idDocumentImagePath2: '',
                                certificateImagePaths: '',
                                criminalRecordImagePath: '');
                            widget.userData.referrerWorkerId = value;
                          });
                        },
                        keyboardType: TextInputType.text,
                        style: MyTextStyles.inputTextStyle,
                        cursorColor: const Color(0xFF830A09),
                        decoration: InputDecoration(
                          hintText: "Código de Referido (opcional)",
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
                    ),
                    const SizedBox(width: 7),
                    ElevatedButton(
                      onPressed: () async {
                        await _verifyReferralCode(referralCodeController.text);
                      },
                      child: Text(
                        'Verificar',
                        style: MyTextStyles.drawerButtonLabelTextStyle,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF830A09),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Aceptaría recibir pagos con QR?',
                        style: MyTextStyles.inputTextStyle.copyWith(
                          color: const Color(0xFF830A09),
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(
                                color: const Color.fromARGB(255, 0, 0, 0)),
                          ),
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10.0),
                            child: DropdownButton<String>(
                              value: widget.selectedWorkerType,
                              onChanged: (value) {
                                setState(() {
                                  widget.selectedWorkerType = value!;
                                  widget.registrationController
                                      .updateRegistrationData(
                                      workerType: value,
                                      idDocumentImagePath: '',
                                      idDocumentImagePath2: '',
                                      certificateImagePaths: '',
                                      criminalRecordImagePath: '',
                                      referralCode: '');
                                  widget.userData.paymentType = value;
                                });
                              },
                              items: ['Marque aqui', 'SI', 'NO']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              style: MyTextStyles.inputTextStyle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isStep1Valid())
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Completa todos los campos obligatorios.',
                      style: TextStyle(color: Color(0xFF830A09)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}