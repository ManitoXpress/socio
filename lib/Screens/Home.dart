import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Cartscreen.dart';
import 'package:socio/Screens/maps.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/Utils/homeData.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/help.dart';
import 'package:socio/menu/profilescreen.dart';
import 'package:socio/menu/referidos.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ServiceResponse/requestUserData.dart';

class HomeScreen extends StatefulWidget {
  final RegistrationData registrationData;
  final UserData userData;

  const HomeScreen({
    Key? key,
    required this.registrationData,
    required this.userData,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
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

  late Future<HomeData> _verificationFuture;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    _verificationFuture = _verification(widget.registrationData);
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final homeData = await _verification(widget.registrationData);
      setState(() => isVerified = homeData.verificationStatus == 'Verificado');

      if (!isVerified) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text(
                "Cuenta en revisión",
                style: MyTextStyles.inputTextStyle4,
              ),
              content: const Text(
                "Su cuenta está siendo verificada. Por favor espere la confirmación.",
                style: MyTextStyles.formServiceTextStyle,
              ),
              actions: [
                TextButton(
                  onPressed: _openWhatsApp,
                  child: const Text(
                    "Contactar soporte",
                    style: MyTextStyles.linkTextStyle,
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white,
                    foregroundColor: Color(
                        0xFF841813), // Color del texto, el mismo que el borde
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFF841813), // Color del borde
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      }
    } catch (e) {
      print('Error verificando estado: $e');
    }
  }

  Future<HomeData> _verification(RegistrationData registrationData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      final token = await user?.getIdToken();

      if (userId == null || token == null) throw 'Usuario no autenticado';

      final userDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(userId)
          .get();

      // Función auxiliar para obtener un valor seguro, con un valor predeterminado
      String getString(String key, {String defaultValue = ''}) {
        return userDoc[key] is String ? userDoc[key] : defaultValue;
      }

      // Función auxiliar para obtener una lista de strings
      List<String> getListOfStrings(String key) {
        if (userDoc[key] is List) {
          return List<String>.from(
              userDoc[key].where((item) => item is String));
        }
        return [];
      }

      return HomeData(
        displayName: getString('displayName'),
        email: getString('email'),
        phoneNumber: getString('phoneNumber'),
        paymentType: getString('paymentType'),
        verificationStatus: userDoc['verificationStatus'] is String
            ? userDoc['verificationStatus']
            : '',
        expertises: getListOfStrings('expertises'),
        expLevel: getListOfStrings('expLevel'),
        imagePath: getString('imagePath'),
        userData: widget.userData,
        registrationData: registrationData,
        points: userDoc['points'] is int ? userDoc['points'] : 0,
      );
    } catch (e) {
      print('Error en verificación: $e');
      return HomeData(
        displayName: '',
        email: '',
        phoneNumber: '',
        paymentType: '',
        verificationStatus: '',
        expertises: [],
        expLevel: [],
        imagePath: '',
        userData: widget.userData,
        registrationData: registrationData,
        points: 0,
      );
    }
  }

  void _openWhatsApp() async {
    const supportPhoneNumber = "59173666393";
    const message = "Hola, necesito soporte técnico en ManitosXpress.";
    final url = Uri.parse(
        "https://wa.me/$supportPhoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al abrir WhatsApp. Verifica la instalación."),
        ),
      );
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir $url');
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

  Widget _buildBlockedScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Color(0xFF841813)),
            const SizedBox(height: 20),
            const Text(
              "Cuenta en proceso de verificación",
              style: MyTextStyles.inputTextStyle4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openWhatsApp,
              child: const Text(
                "Contactar soporte técnico",
                style: MyTextStyles.linkTextStyle,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white,
                foregroundColor:
                Color(0xFF841813), // Color del texto, el mismo que el borde
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFF841813), // Color del borde
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 200.w,
                    maxHeight: 200.h,
                  ),
                  child: Image.network("https://i.imgur.com/AWrWerE.png"),
                  margin: EdgeInsets.only(top: 70.h, bottom: 40.h),
                ),
                SizedBox(height: 1.h),
              ],
            ),
            SizedBox(height: 10.h),
            _buildDrawerButton(
              icon: Icons.person,
              text: "Perfil",
              color: Color(0xFF84090D), // Establece el color aquí
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
              },
            ),
            _buildDrawerButton(
              icon: Icons.share,
              text: "Referidos",
              color: Color(0xFF84090D), // Establece el color aquí
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
              },
            ),
            _buildDrawerButton(
              icon: Icons.help,
              text: "Ayuda",
              color: Color(0xFF84090D), // Establece el color aquí
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpScreen()),
              ),
            ),
            _buildDrawerButton(
              icon: Icons.support_agent,
              text: "Soporte Técnico",
              color: Color(0xFF84090D), // Establece el color aquí
              onPressed: _openWhatsApp,
            ),
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  url:
                  'fb://facewebmodal/f?href=https://www.facebook.com/ManitosXpress',
                  fallbackUrl: 'https://www.facebook.com/ManitosXpress',
                ),
                SizedBox(width: 18.w),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  url: 'https://www.instagram.com/manitosxpress',
                ),
                SizedBox(width: 18.w),
                _buildSocialButton(
                  icon: Icons.tiktok,
                  url: 'https://www.tiktok.com/@manitosxpress',
                ),
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
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Fondo blanco
          foregroundColor: const Color(0xFF830A09), // Color del icono (rojo)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          icon,
          size: 24.w, // Tamaño del icono
          color: const Color(0xFF830A09), // Establecer color rojo para el icono
        ),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: MyTextStyles.linkTextStyle, // Usar tu estilo predefinido
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSocialButton(
      {required IconData icon, required String url, String? fallbackUrl}) {
    return IconButton(
      icon: Icon(
        icon,
        size: 45.w,
        color: Colors.white, // Establecer el color del icono a blanco
      ),
      onPressed: () => _abrirEnlace(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _verificationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !isVerified) {
          return _buildBlockedScreen();
        }

        return Scaffold(
          appBar: AppBar(
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
            onPageChanged: (index) => setState(() => _currentIndex = index),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              _pageController.jumpToPage(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'SERVICIOS',
                backgroundColor: Color(0xFF1A819A),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.balance),
                label: 'MOVIMIENTOS',
                backgroundColor: Color.fromARGB(166, 50, 196, 233),
              ),
            ],
            selectedItemColor: Colors.white,
            unselectedItemColor: Color.fromARGB(255, 230, 121, 121),
            selectedLabelStyle: MyTextStyles.navBarTextStyle,
            unselectedLabelStyle: MyTextStyles.navBarTextStyle,
            backgroundColor: const Color(0xFF841813),
          ),
        );
      },
    );
  }

  List<Widget> _buildScreens() => [Historial(), WalletScreen()];
}