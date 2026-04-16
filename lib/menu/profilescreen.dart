import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socio/controllers/RegisController.dart';
import 'package:socio/menu/login.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Screens/documentScreen.dart';
import '../controllers/editController.dart';
import '../ServiceResponse/get.dart';
import '../ServiceResponse/requestExpertise.dart';
import '../ServiceResponse/requestUserData.dart';
import '../Utils/Colors.dart';
import '../Utils/styles.dart';
import '../provider/providerRegistration.dart';

class ProfileData {
  String displayName;
  String email;
  String phoneNumber;
  String paymentType;
  List<String> expertises;
  List<String> expLevel;
  String imagePath;
  UserData userData;
  RegistrationData registrationData;
  int points; // Nuevo campo para los puntos

  ProfileData({
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.paymentType,
    required this.expertises,
    required this.expLevel,
    required this.imagePath,
    required this.userData,
    required this.registrationData,
    required this.points, // Inicializa el campo points
  });
}

class ProfilePage extends StatefulWidget {
  final RegistrationData registrationData;
  String displayName;
  String email;
  List<Expertise> expertises;
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

        // Fetch points from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(userId)
            .get();
        final points = userDoc.data()?['points'] ?? 0;

        return ProfileData(
          displayName: userData.displayName,
          email: userData.email,
          phoneNumber: userData.phoneNumber,
          paymentType: userData.paymentType,
          expertises:
              userData.expertises.map((expertise) => expertise.name).toList(),
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
            referrerWorkerId: userData.referrerWorkerId,
            referralCode: userData.referralCode,
            points: userData.points,
            verificationStatus: userData.verificationStatus,
            medicalLicenseImagePath: userData.medicalLicenseImagePath,
            professionalTitleImagePath: userData.professionalTitleImagePath,
          ),
          registrationData: registrationData,
          points: points, // Asigna los puntos al campo points
        );
      } else {
        throw 'No se pudo obtener el ID del usuario autenticado.';
      }
    } catch (e) {
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
          certificateImagePaths: [],
          expLevel: [],
          selectedCountryCode: '',
          getToken: '',
          referrerWorkerId: '',
          referralCode: '',
          points: 0,
          verificationStatus: '',
          medicalLicenseImagePath: '',
          professionalTitleImagePath: '',
        ),
        registrationData: registrationData,
        expLevel: [],
        points: 0, // Valor predeterminado en caso de error
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
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginScreen(
                deviceId: '',
              )));
    } catch (e) {
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil', style: MyTextStyles.buttonTextStyle),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<ProfileData>(
        future: userData,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final profile = snap.data!;
          final supportUrl =
              'https://wa.me/59173666393?text=Hola%20Soy%20${Uri.encodeComponent(profile.displayName)},%20Necesito%20modificar%20mi%20perfil%20en%20Manito%20Socio';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset('assets/manito.png', width: 300),
                ),
                const SizedBox(height: 10),
                Text('Puntos: ${profile.points}',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: customColor),
                      child: const Text('Cerrar Sesión',
                          style: MyTextStyles.buttonTextStyle),
                    ),
                    ElevatedButton(
                      onPressed: () => _abrirEnlace(supportUrl),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: customColor),
                      child: const Text('Editar Perfil',
                          style: MyTextStyles.buttonTextStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final regProv = Provider.of<RegistrationProvider>(context,
                        listen: false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentsScreen(
                          provider: regProv,
                          profileData: profile,
                          onSaved: _loadAndRefreshUserData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: customColor),
                  child: const Text('Cargar Documentos',
                      style: MyTextStyles.buttonTextStyle),
                ),
                const SizedBox(height: 20),
                _buildInfoCard(profile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(ProfileData profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Nombre:', profile.displayName),
          _buildRow('Teléfono:', profile.phoneNumber),
          _buildRow('Especialidades:', profile.expertises.join(', '),
              expandable: true),
          _buildRow('Experiencia:', profile.expLevel.join(', '),
              expandable: true),
          _buildRow('Pagos con QR:', profile.paymentType),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool expandable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: MyTextStyles.inputTextStyle3),
            Flexible(
              child: expandable
                  ? _buildExpandableText(value)
                  : Text(value,
                      style: MyTextStyles.formsdetails,
                      overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        Divider(color: Color(0xFF841813), height: 2),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpandableText(String value) {
    final items = value.split(', ');
    return ExpansionTile(
      title: Text('Ver más', style: MyTextStyles.formsdetails),
      children: items
          .map((t) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(t, style: MyTextStyles.servicesButtonTextStyle),
              ))
          .toList(),
    );
  }
}
