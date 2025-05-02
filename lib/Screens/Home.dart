import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:socio/Controller/RegisController.dart';
import 'package:socio/Screens/Cartscreen.dart';
import 'package:socio/Screens/buttonDocument.dart';
import 'package:socio/Screens/maps.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/Utils/homeData.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/help.dart';
import 'package:socio/menu/profilescreen.dart';
import 'package:socio/menu/referidos.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:socio/provider/providerRegistration.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ServiceResponse/requestUserData.dart';
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

  final customColor = const MaterialColor(0xFF841813, {
    50: Color(0xFF841813),
    100: Color(0xFF841813),
    200: Color(0xFF841813),
    300: Color(0xFF841813),
    400: Color(0xFF841813),
    500: Color(0xFF841813),
    600: Color(0xFF841813),
    700: Color(0xFF841813),
    800: Color(0xFF841813),
    900: Color(0xFF841813),
  });

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);

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
      ..imagePath                  = remoteUser.imagePath
      ..idDocumentImagePath        = remoteUser.idDocumentImagePath
      ..idDocumentImagePath2       = remoteUser.idDocumentImagePath2
      ..criminalRecordImagePath    = remoteUser.criminalRecordImagePath
      ..certificateImagePaths      = remoteUser.certificateImagePaths
      ..medicalLicenseImagePath    = remoteUser.medicalLicenseImagePath
      ..professionalTitleImagePath = remoteUser.professionalTitleImagePath;
    regProv.notifyListeners();

    final profileData = ProfileData(
      displayName:      remoteUser.displayName,
      email:            remoteUser.email,
      phoneNumber:      remoteUser.phoneNumber,
      paymentType:      remoteUser.paymentType,
      expertises:       remoteUser.expertises.map((e) => e.name).toList(),
      expLevel:         remoteUser.expLevel,
      imagePath:        remoteUser.imagePath,
      userData:         remoteUser,
      registrationData: regProv.registrationData,
      points:           remoteUser.points,
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentsScreen(
          provider:    regProv,
          profileData: profileData,
          onSaved:     () {},
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
                "Para continuar debes subir las *tres* fotos obligatorias:",
                style: MyTextStyles.inputTextStyle4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                "Este mensaje aparece solo si falta alguna de las tres imágenes obligatorias. "
                    "No es un nuevo requerimiento de fotos completo, sino un recordatorio "
                    "para que completes la que quedó pendiente en el registro.",
                style: MyTextStyles.inputTextStyle4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _openUploadDocuments(remoteUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF841813),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildDrawer() {
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
                    final userData = await ApiService2().fetchUserData(user.uid, token!);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          displayName: userData.displayName,
                          email: userData.email,
                          phoneNumber: userData.phoneNumber,
                          paymentType: userData.paymentType,
                          expertises: userData.expertises,
                          imagePath: userData.imagePath.isNotEmpty ? userData.imagePath[0] : '',
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
                    const SnackBar(content: Text("No se encontró código de referido")),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReferralScreen(codeReferral: codeReferral),
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
              onPressed: () => _abrirEnlace(
                  "https://wa.me/59173666393?text=Necesito%20soporte"),
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


  Widget _buildDrawerButton(
      {required IconData icon,
        required String text,
        required VoidCallback onPressed}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.w, color: const Color(0xFF830A09)),
        label: Text(text, style: MyTextStyles.linkTextStyle),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      {required IconData icon, required String url}) =>
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
        return _buildMainScaffold();
      },
    );
  }

  Widget _buildMainScaffold() {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF841813),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ManitoXpress', style: MyTextStyles.buttonTextStyle),
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
        drawer: _buildDrawer(),
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
              style: MyTextStyles.inputTextStyle4,
            ),
          ),
        ],
      ),
    );
  }
}