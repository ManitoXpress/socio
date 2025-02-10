import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/ServiceResponse/requestExpertise.dart';
import 'package:socio/Utils/Colors.dart';
import 'package:socio/Utils/serviceCategories.dart';
import 'package:socio/Utils/serviceType.dart';
import 'package:socio/Utils/styles.dart';
class EditProfileDialog extends StatefulWidget {
  final String displayName;
  final String idCardNumber;
  final String phoneNumber;
  late List<Expertise> expertises;  // Cambié el tipo a List<Expertises>
  late List<String> expLevel; 
  final Function()? onUpdateProfile;
  final ApiService2 apiService2; 

  EditProfileDialog({
    required this.displayName,
    required this.idCardNumber,
    required this.expLevel,
    required this.expertises,
    required this.phoneNumber,
    required this.apiService2, 
    this.onUpdateProfile,
  });

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController displayNameController;
  late TextEditingController idCardNumberController;
  late TextEditingController phoneNumberController;
  final customColor = CustomColor.materialColor;
  
  @override
  void initState() {
    super.initState();
    displayNameController = TextEditingController(text: widget.displayName);
    idCardNumberController = TextEditingController(text: widget.idCardNumber);
    phoneNumberController = TextEditingController(text: widget.phoneNumber);
  }

  Future<void> _updateUserProfile() async {
    try {
      final apiService = ApiService();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String? token = await user.getIdToken();
        final updatedDisplayName = displayNameController.text;
        final updatedIdCardNumber = idCardNumberController.text;
        final updatedPhoneNumber = phoneNumberController.text;

        // Obtener datos actuales del usuario
        final userData = await ApiService2().fetchUserData(user.uid, token!);

        // Convertir la lista de `Expertises` a una lista de mapas para actualizar
       List<Expertise> expertisesList = widget.expertises.map((e) => Expertise(id: e.id, name: e.name)).toList();

        // Actualizar los datos del usuario
        RegistrationData registrationData = RegistrationData(
          userId: user.uid,
          displayName: updatedDisplayName.isNotEmpty ? updatedDisplayName : userData.displayName,
          idCardNumber: updatedIdCardNumber.isNotEmpty ? updatedIdCardNumber : userData.idCardNumber,
          phoneNumber: updatedPhoneNumber.isNotEmpty ? updatedPhoneNumber : userData.phoneNumber,
          imagePath: userData.imagePath,
          location: userData.location,
          idDocumentImagePath: userData.idDocumentImagePath,
          idDocumentImagePath2: userData.idDocumentImagePath2,
          paymentType: userData.paymentType,
          expertises: expertisesList,  // Ahora se pasa como una lista de mapas
          selectedCountryCode: userData.selectedCountryCode,
          expLevel: widget.expLevel,
          email: userData.email,
          imagePathList: [],
          criminalRecordImagePath: userData.criminalRecordImagePath,
          certificateImagePaths: userData.certificateImagePaths, 
          devicesId: '', 
          fcmToken: '',
        );

        final response = await apiService.updateUser(
          user.uid,
          registrationData,
          token!,
        );

        if (response.statusCode == 200) {
          print('Usuario actualizado con éxito');
          Navigator.pop(context);
          widget.onUpdateProfile?.call();
        } else {
          print('Error en la respuesta del servidor: ${response.statusCode}');
        }
      } else {
        print('Advertencia: usuario es nulo. Asegúrate de que el usuario esté autenticado correctamente.');
      }
    } catch (error) {
      print('Error durante el proceso de registro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Perfil'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: displayNameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              labelStyle: MyTextStyles.formServiceTextStyle,
            ),
            style: MyTextStyles.formServiceTextStyle,
          ),
          TextFormField(
            controller: idCardNumberController,
            decoration: InputDecoration(
              labelText: 'Número de Carnet',
              labelStyle: MyTextStyles.formServiceTextStyle,
            ),
            style: MyTextStyles.formServiceTextStyle,
          ),
          Text('Especialidades seleccionadas: ${widget.expertises.map((e) => e.name).join(", ")}'),
          Text('Experiencia laboral seleccionada: ${widget.expLevel.join(", ")}'),
          TextButton(
            onPressed: () {
              // Abrir la nueva pantalla para seleccionar expertises y expLevel
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceTypeListScreen(
                    registrationController: RegistrationController(),
                    onNextStep: () {},
                    onServiceTypesSelected: (expertises, expLevel) {
                      setState(() {
                        // Actualiza expertises con la lista de `Expertises`
                        widget.expertises = expertises;

                        // Si `expLevel` no es nulo, lo guarda en la lista
                        if (expLevel != null) {
                          widget.expLevel = [expLevel];
                        } else {
                          widget.expLevel = [];
                        }
                      });
                    },
                    categories: ServiceCategories.categories,
                    onServiceTypeSelected: (serviceType) {},
                    fetchExpertises: widget.apiService2.fetchExpertises,
                  ),
                ),
              );
            },
            child: Text('Añadir nueva especialidad'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: customColor,
          ),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            _updateUserProfile(); 
            widget.onUpdateProfile?.call(); 
            Navigator.pop(context);
          },
          child: Text("Guardar Cambios"),
        ),
      ],
    );
  }
}
