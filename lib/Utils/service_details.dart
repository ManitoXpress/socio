import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Home.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';
class ServiceRequest extends StatefulWidget {
  final String buttonText;

  ServiceRequest(
      {required this.buttonText,
      required String serviceName,
      required String address});

  @override
  _ServiceRequestState createState() => _ServiceRequestState();
}

class _ServiceRequestState extends State<ServiceRequest> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  void submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form validation successful
      print('Servicio: ${_serviceNameController.text}');
      print('Direccion: ${_addressController.text}');
      print('Ciudad: ${_cityController.text}');
      print('Tipo de servicio: ${_stateController.text}');
      print('Precio: ${_zipCodeController.text}');
      print('Additional Notes: ${_additionalNotesController.text}');

      // Create a new ServiceRequest object with the form data
      ServiceRequest newRequest = ServiceRequest(
        buttonText: widget.buttonText,
        serviceName: _serviceNameController.text,
        address: _addressController.text,
      );

      // TODO: Add code to handle saving the request or sending it to the server

      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Solicitud enviada'),
          content: Text('Tu solicitud ha sido enviada correctamente.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Closes the dialog
                _navigateToHomeService(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHomeService(BuildContext context) async {
    try {
      // Obtén el usuario actual
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Obtén los datos del usuario y de registro
        UserData userData = await fetchUserData(user.uid);
        RegistrationData registrationData = userData.registrationData;

        // Navega a HomeScreen con los datos obtenidos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userData: userData,
              registrationData: registrationData,
            ),
          ),
        );
      } else {
        print('Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error de autenticación. Intente nuevamente.')));
      }
    } catch (error) {
      print('Error al navegar a HomeScreen: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar la pantalla principal. Intente nuevamente.')));
    }
  }

// Ejemplo de función para obtener los datos del usuario
  Future<UserData> fetchUserData(String userId) async {
    // Aquí debes implementar la lógica para obtener los datos del usuario
    // Por ejemplo, desde una base de datos o un servicio web
    // Este es solo un ejemplo de retorno
    return UserData(
      userId: userId,
      displayName: '',
      idCardNumber: '',
      phoneNumber: '',
      getToken: null,
      imagePath: '',
      pdfPathController: '',
      criminalRecordImagePath: '',
      idDocumentImagePath: '',
      idDocumentImagePath2: '',
      selectedCountryCode: '',
      expertises: [],
      expLevel: [],
      certificateImagePaths: '',
      location: null,
      paymentType: '',
      email: '',
      registrationData: RegistrationData(
        userId: userId,
        devicesId: '',
        fcmToken: '',
        displayName: '',
        idCardNumber: '',
        phoneNumber: '',
        paymentType: '',
        expertises: [],
        expLevel: [],
        selectedCountryCode: '',
        imagePath: '',
        location: null,
        idDocumentImagePath: '',
        idDocumentImagePath2: '',
        email: '',
        imagePathList: [],
        criminalRecordImagePath: '',
        certificateImagePaths: '',
        referralCode: '',
        points: 0,
        codeReferral: '', verificationStatus: '',
      ),
      referrerWorkerId: '',
      referralCode: '',
      points: 0, verificationStatus: '',
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buttonText),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Detalles del servicio: ${widget.buttonText}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aquí puedes mostrar más información sobre el servicio seleccionado.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(labelText: 'Nombre del servicio'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Ingrese el nombre del servicio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Dirección'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Ingrese la dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(labelText: 'Ciudad'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Ingrese la ciudad';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: InputDecoration(labelText: 'Estado'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Ingrese el estado';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: InputDecoration(labelText: 'Precio'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Ingrese el precio';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _additionalNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Notas adicionales'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      submitForm();
                    }
                  },
                  child: Text('Enviar'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}