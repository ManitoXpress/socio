import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:url_launcher/url_launcher.dart';

import '../ServiceResponse/get.dart';
import '../ServiceResponse/requestUserData.dart';
import '../Utils/fcmToken.dart';
import '../Utils/debt_blocker_wrapper.dart';
import '../Utils/maps.dart';
import '../Utils/styles.dart';
import '../controllers/RegisController.dart';
import '../menu/help.dart';
import '../menu/profilescreen.dart';
import '../menu/referidos.dart';
import 'Cartscreen.dart';
import 'documentScreen.dart';
import 'homeData.dart';
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/providerRegistration.dart';

class HomeScreen extends StatefulWidget {
  final RegistrationData registrationData;
  final UserData userData;
  final int initialPageIndex;
  final bool isGuest;

  const HomeScreen({
    Key? key,
    required this.registrationData,
    required this.userData,
    this.initialPageIndex = 0,
    this.isGuest = false,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool isVerified = false;
  late Future<UserData> _remoteUserFuture;

  final customColor = const MaterialColor(0xFF830A09, {
    50: Color(0xFF830A09),
    100: Color(0xFF830A09),
    200: Color(0xFF830A09),
    300: Color(0xFF830A09),
    400: Color(0xFF830A09),
    500: Color(0xFF830A09),
    600: Color(0xFF830A09),
    700: Color(0xFF830A09),
    800: Color(0xFF830A09),
    900: Color(0xFF830A09),
  });

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService().registerTokenForUser(widget.userData.userId);
    });

    if (widget.isGuest) {
      isVerified = true;
    } else {
      _remoteUserFuture = _fetchRemoteUser();
    }
  }

  Future<UserData> _fetchRemoteUser() async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken();
    return await ApiService2().fetchUserData(user.uid, token!);
  }

  void _openUploadDocuments(UserData remoteUser) async {
    final regProv = Provider.of<RegistrationProvider>(context, listen: false);

    // Sincroniza los paths
    regProv.registrationData
      ..imagePath = remoteUser.imagePath
      ..idDocumentImagePath = remoteUser.idDocumentImagePath
      ..idDocumentImagePath2 = remoteUser.idDocumentImagePath2
      ..criminalRecordImagePath = remoteUser.criminalRecordImagePath
      ..certificateImagePaths = remoteUser.certificateImagePaths
      ..medicalLicenseImagePath = remoteUser.medicalLicenseImagePath
      ..professionalTitleImagePath = remoteUser.professionalTitleImagePath;
    regProv.notifyListeners();

    final profileData = ProfileData(
      displayName: remoteUser.displayName,
      email: remoteUser.email,
      phoneNumber: remoteUser.phoneNumber,
      paymentType: remoteUser.paymentType,
      expertises: remoteUser.expertises.map((e) => e.name).toList(),
      expLevel: remoteUser.expLevel,
      imagePath: remoteUser.imagePath,
      userData: remoteUser,
      registrationData: regProv.registrationData,
      points: remoteUser.points,
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentsScreen(
          provider: regProv,
          profileData: profileData,
          onSaved: () {},
        ),
      ),
    );

    // ✅ Recargar datos y actualizar estado
    if (result == true) {
      final updatedUser = await _fetchRemoteUser();

      final ok = updatedUser.imagePath.isNotEmpty &&
          updatedUser.idDocumentImagePath.isNotEmpty &&
          updatedUser.idDocumentImagePath2.isNotEmpty;

      setState(() {
        isVerified = ok;
        _remoteUserFuture = Future.value(updatedUser);
        if (ok) _pageController.jumpToPage(0);
      });
    }
  }

  Future<String?> getCodeReferral() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(userId)
        .get();

    return doc.data()?['codeReferral'] as String?;
  }

  Widget _buildBlockedScreen(UserData remoteUser) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFF841813),
              ),
              const SizedBox(height: 24),
              Text(
                "Para continuar te invitamos a completar tu registro:",
                style: MyTextStyles.inputTextStyle5.copyWith(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Lista de requisitos
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BulletItem(text: "Foto de perfil"),
                  _BulletItem(text: "Carnet de identidad (frontal)"),
                  _BulletItem(text: "Carnet de identidad (posterior)"),
                ],
              ),
              const SizedBox(height: 16),
              // Mensaje aclaratorio
              Text(
                "Este mensaje solo aparece si te falta una de esas fotos. "
                "Haz clic en 'Subir fotos' para completar tu registro.",
                style: MyTextStyles.inputTextStyle5,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _openUploadDocuments(remoteUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF841813),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Subir fotos",
                  style: MyTextStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScreens() => [
        HistorialScreen(userData: widget.userData),
        WalletScreen(),
      ];

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDrawer(UserData remoteUser) {
    final name = Uri.encodeComponent(remoteUser.displayName);
    final supportUrl =
        'https://wa.me/59173666393?text=Hola%20Soy%20$name,%20Necesito%20soporte%20';
    return Drawer(
      child: Container(
        color: customColor,
        child: ListView(
          padding: EdgeInsets.all(10.w),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 200.w,
                    maxHeight: 200.h,
                  ),
                  child: Image.network("https://i.imgur.com/AWrWerE.png"),
                  margin: EdgeInsets.only(top: 70.h, bottom: 40.h),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildDrawerButton(
              icon: Icons.person,
              text: "Perfil",
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    final token = await user.getIdToken();
                    final userData =
                        await ApiService2().fetchUserData(user.uid, token!);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          displayName: userData.displayName,
                          email: userData.email,
                          phoneNumber: userData.phoneNumber,
                          paymentType: userData.paymentType,
                          expertises: userData.expertises,
                          imagePath: userData.imagePath.isNotEmpty
                              ? userData.imagePath[0]
                              : '',
                          userData: widget.userData,
                          registrationData: widget.registrationData,
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error al obtener datos del usuario: $e');
                  }
                }
                // ... tu navegación a ProfilePage ...
              },
            ),
            _buildDrawerButton(
              icon: Icons.share,
              text: "Referidos",
              onPressed: () async {
                final codeReferral = await getCodeReferral();
                if (codeReferral == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("No se encontró código de referido")),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReferralScreen(codeReferral: codeReferral),
                  ),
                );
                // ... tu navegación a ReferralScreen ...
              },
            ),
            _buildDrawerButton(
              icon: Icons.help,
              text: "Ayuda",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpScreen()),
              ),
            ),
            _buildDrawerButton(
              icon: Icons.support_agent,
              text: "Soporte Técnico",
              onPressed: () => _abrirEnlace(supportUrl),
            ),
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                    icon: Icons.facebook,
                    url:
                        'fb://facewebmodal/f?href=https://www.facebook.com/ManitosXpress'),
                SizedBox(width: 18.w),
                _buildSocialButton(
                    icon: Icons.camera_alt,
                    url: 'https://www.instagram.com/manitosxpress'),
                SizedBox(width: 18.w),
                _buildSocialButton(
                    icon: Icons.tiktok,
                    url: 'https://www.tiktok.com/@manitosxpress'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.start, // Alinea el contenido a la izquierda
          crossAxisAlignment:
              CrossAxisAlignment.center, // Centra el contenido verticalmente
          children: [
            Icon(icon, size: 24.w, color: const Color(0xFF830A09)),
            SizedBox(width: 8.w), // Espacio entre el icono y el texto
            Text(text, style: MyTextStyles.linkTextStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required String url}) =>
      IconButton(
        icon: Icon(icon, size: 45.w, color: Colors.white),
        onPressed: () => _abrirEnlace(url),
      );

  @override
  Widget build(BuildContext context) {
    // De lo contrario, esperamos el fetch de UserData remoto
    return FutureBuilder<UserData>(
      future: _remoteUserFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return Center(child: Text('Error cargando usuario'));
        }
        final remoteUser = snap.data!;

        // Si faltan las 3 fotos, bloquea
        final ok = remoteUser.imagePath.isNotEmpty &&
            remoteUser.idDocumentImagePath.isNotEmpty &&
            remoteUser.idDocumentImagePath2.isNotEmpty;
        if (!ok) {
          return _buildBlockedScreen(remoteUser);
        }

        // Ya pasó la verificación
        // <-- aquí le pasamos el remoteUser
        return _buildMainScaffold(remoteUser);
      },
    );
  }

  Widget _buildMainScaffold(UserData remoteUser) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF841813),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ManitosXpress', style: MyTextStyles.buttonTextStyle),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(remoteUser),
      body: PageView(
        controller: _pageController,
        children: _buildScreens(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _pageController.jumpToPage(i);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'SERVICIOS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.balance), label: 'MOVIMIENTOS'),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Color.fromARGB(255, 230, 121, 121),
        backgroundColor: const Color(0xFF841813),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 20)),
          Expanded(
            child: Text(
              text,
              style: MyTextStyles.inputTextStyle7,
            ),
          ),
        ],
      ),
    );
  }
}
