import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Metods/editController.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/Colors.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/login.dart';
class ProfileData {
  late final String displayName;
  final String email;
  late final String phoneNumber;
  final String imagePath;
  final String paymentType;
  late final List<String> expertises;
  late final List<String> expLevel;
  final RegistrationData registrationData;
  final UserData userData;

  ProfileData({
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.expertises,
    required this.expLevel,
    required this.paymentType,
    required this.imagePath,
    required this.registrationData,
    required this.userData,
  });
}

class ProfilePage extends StatefulWidget {
  final RegistrationData registrationData;
  String displayName;
  String email;
  List<Expertises> expertises;
  String phoneNumber;
  String paymentType;
  final UserData userData;
  String imagePath;

  ProfilePage({
    Key? key,
    required this.registrationData,
    required this.displayName,
    required this.email,
    required this.expertises,
    required this.phoneNumber,
    required this.paymentType,
    required this.userData,
    required this.imagePath,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final customColor = CustomColor.materialColor;
  late Future<ProfileData> userData;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    userData = _loadUserData(widget.registrationData);
  }

  Future<ProfileData> _loadUserData(RegistrationData registrationData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;
      final token = await currentUser?.getIdToken();

      if (userId != null && token != null) {
        // Fetch user data from API
        final userData = await ApiService2().fetchUserData(userId, token);
        String? profileImageUrl = await ApiService2().fetchProfileImage(userId);

        return ProfileData(
          displayName: userData.displayName,
          email: userData.email,
          phoneNumber: userData.phoneNumber,
          paymentType: userData.paymentType,
          expertises: userData.expertises.map((expertise) => expertise.name).toList(),
          expLevel: userData.expLevel,
          imagePath: profileImageUrl ?? '',
          userData: UserData(
            userId: userData.userId,
            displayName: userData.displayName,
            email: userData.email,
            idCardNumber: userData.idCardNumber,
            phoneNumber: userData.phoneNumber,
            expertises: userData.expertises,
            expLevel: userData.expLevel,
            selectedCountryCode: userData.selectedCountryCode,
            imagePath: userData.imagePath,
            idDocumentImagePath: userData.idDocumentImagePath,
            idDocumentImagePath2: userData.idDocumentImagePath2,
            location: userData.location,
            paymentType: userData.paymentType,
            registrationData: registrationData,
            criminalRecordImagePath: userData.criminalRecordImagePath,
            pdfPathController: userData.pdfPathController,
            certificateImagePaths: userData.certificateImagePaths,
            getToken: '',
          ),
          registrationData: registrationData,
        );
      } else {
        throw 'No se pudo obtener el ID del usuario autenticado.';
      }
    } catch (e) {
      print('Error loading user data: $e');
      return ProfileData(
        displayName: 'Error',
        email: '',
        phoneNumber: '',
        paymentType: '',
        expertises: [],
        imagePath: '',
        userData: UserData(
          userId: '',
          displayName: 'Error',
          email: '',
          idCardNumber: '',
          phoneNumber: '',
          expertises: [],
          imagePath: '',
          idDocumentImagePath: '',
          location: {},
          paymentType: '',
          registrationData: registrationData,
          criminalRecordImagePath: '',
          pdfPathController: '',
          idDocumentImagePath2: '',
          certificateImagePaths: '',
          expLevel: [],
          selectedCountryCode: '',
          getToken: '',
        ),
        registrationData: registrationData,
        expLevel: [],
      );
    }
  }


  Future<void> _loadAndRefreshUserData() async {
    try {
      final updatedUserData = await _loadUserData(widget.registrationData);
      setState(() {
        userData = Future.value(updatedUserData);
      });
    } catch (e) {
      print('Error durante la carga de datos de usuario: $e');
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen(deviceId: '',))
      );
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  Future<void> _editProfile() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (userId != null && token != null) {
      final userData = await ApiService2().fetchUserData(userId, token);

      if (userData == null) {
        throw 'No se pudo obtener los datos del usuario.';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return EditProfileDialog(
            displayName: userData.displayName,
            idCardNumber: userData.idCardNumber,
            phoneNumber: userData.phoneNumber,
            expertises: userData.expertises,
            expLevel: userData.expLevel,
            apiService2: ApiService2(), // Aquí se pasa la instancia de ApiService2
            onUpdateProfile: _loadAndRefreshUserData,
          );
        },
      );
    } else {
      throw 'No se pudo obtener el ID del usuario autenticado.';
    }
  } catch (e) {
    print('Error al obtener datos del usuario: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: FutureBuilder<ProfileData>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final profileData = snapshot.data;
            return SingleChildScrollView(
              child: _buildProfileInfo(profileData),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileInfo(ProfileData? profileData) {
    if (profileData == null) {
      return Text('Error: No se pudo cargar la información del perfil');
    }

    return Container(
      margin: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
              width: 300, // Ajusta el ancho de la imagen según sea necesario
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 24),
              Icon(Icons.star, color: Colors.yellow, size: 24),
              Icon(Icons.star, color: Colors.yellow, size: 24),
              Icon(Icons.star, color: Colors.yellow, size: 24),
              Icon(Icons.star_half, color: Colors.yellow, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '(${Random().nextInt(1000) + 1})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _signOut,
                child: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: customColor,
                ),
              ),
              ElevatedButton(
                onPressed: _editProfile,
                child: const Text('Editar perfil'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: customColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                _buildProfileInfoRow('Nombre:', profileData.displayName),
                const SizedBox(height: 10),
                _buildProfileInfoRow('Número de Teléfono:', profileData.phoneNumber),
                const SizedBox(height: 10),
                _buildProfileInfoRow('Especialidades:', profileData.expertises.join(', ')),
                const SizedBox(height: 10),
                _buildProfileInfoRow('Experiencia laboral:', profileData.expLevel.join(', ')),
                const SizedBox(height: 10),
                _buildProfileInfoRow('Pagos con QR:', profileData.paymentType),
                const SizedBox(height: 10),
                // Boton de documentos debajo del cuadro
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función para construir el ExpansionTile
  Widget _buildExpandableText(String value) {
    List<String> items = value.split(', ');
    return ExpansionTile(
      title: Text(
        'Ver más',
        style: MyTextStyles.servicesButtonTextStyle,
      ),
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            item,
            style: MyTextStyles.servicesButtonTextStyle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: MyTextStyles.inputTextStyle2,
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8.0),
                    child: label == 'Especialidades:'
                        ? _buildExpandableText(value)
                        : Text(
                      value,
                      style: MyTextStyles.inputTextStyle2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
              Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: Divider(
              color: Color(0xFF841813),
              height: 2,
          ),
        ),
      ],
    );
  }
}