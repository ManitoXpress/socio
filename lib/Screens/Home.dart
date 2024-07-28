import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Cartscreen.dart';
import 'package:socio/Screens/Historial.dart';
import 'package:socio/Screens/maps.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/ServiceResponse/request.dart';
import 'package:socio/Utils/styles.dart';
import 'package:socio/menu/help.dart';
import 'package:socio/menu/profilescreen.dart';
import 'package:socio/menu/referidos.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final customColor = const MaterialColor(0xFF84090D, {
    50: const Color(0xFF84090D),
    100: const Color(0xFF84090D),
    200: const Color(0xFF84090D),
    300: const Color(0xFF84090D),
    400: const Color(0xFF84090D),
    500: const Color(0xFF84090D),
    600: const Color(0xFF84090D),
    700: const Color(0xFF84090D),
    800: const Color(0xFF84090D),
    900: const Color(0xFF84090D),
  });

  List<PersistentBottomNavBarItem> _navBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.phonelink_ring_sharp),
        title: 'Solicitudes',
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: Colors.black38,
        textStyle: TextStyle(
          fontFamily: 'Xpress Heavy',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.explore),
        title: 'Seguimiento',
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: Colors.black38,
        textStyle: TextStyle(
          fontFamily: 'Xpress Heavy',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.account_circle_outlined),
        title: 'Billetera',
        activeColorPrimary: Colors.white,
        inactiveColorPrimary: Colors.black38,
        textStyle: TextStyle(
          fontFamily: 'Xpress Heavy',
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  List<Widget> _buildScreens() {
    return [
      Historial(),
      ServiceScreen(),
      WalletScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w), // Cambiado a screenutil
                constraints: BoxConstraints(maxWidth: 80.w), // Cambiado a screenutil
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: double.infinity,
                  height: 80.h, // Cambiado a screenutil
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 20.w), // Cambiado a screenutil
            Text(
              'ManitoXpress Socio',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: 18.sp, // Cambiado a screenutil
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(
            color: Colors.white), // Cambia el color del ícono del menú a blanco
      ),
      drawer: Drawer(
        child: Container(
          color: customColor,
          child: ListView(
            padding: const EdgeInsets.all(0.10),
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    constraints:
                        BoxConstraints(maxWidth: 200.w, maxHeight: 200.h), // Cambiado a screenutil
                    child: Image.network("https://i.imgur.com/AWrWerE.png"),
                    margin: EdgeInsets.only(top: 70.h, bottom: 40.h), // Cambiado a screenutil
                  ),
                  SizedBox(height: 1.h), // Cambiado a screenutil
                ],
              ),
              SizedBox(height: 0.10.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    try {
                      final userId = user.uid;
                      final token = await user.getIdToken();

                      final userData =
                          await ApiService2().fetchUserData(userId, token!);

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
                            userData: UserData(
                              userId: userData.userId,
                              displayName: userData.displayName,
                              email: userData.email,
                              idCardNumber: userData.idCardNumber,
                              phoneNumber: userData.phoneNumber,
                              expertises: userData.expertises,
                              imagePath: userData.imagePath,
                              selectedCountryCode: userData.selectedCountryCode,
                              idDocumentImagePath: userData.idDocumentImagePath,
                              idDocumentImagePath2:
                                  userData.idDocumentImagePath2,
                              criminalRecordImagePath:
                                  userData.criminalRecordImagePath,
                              certificateImagePaths:
                                  userData.certificateImagePaths,
                              location: userData.location,
                              paymentType: userData.paymentType,
                              registrationData: RegistrationData(
                                // Aquí debes proporcionar los valores adecuados para RegistrationData
                                userId: '',
                                displayName: '',
                                idCardNumber: '',
                                phoneNumber: '',
                                paymentType: '',

                                expertises: [],
                                imagePath: '',
                                location: {},
                                idDocumentImagePath: '',
                                email: '',
                                imagePathList: [], idDocumentImagePath2: '',
                                criminalRecordImagePath: '',
                                certificateImagePaths: [],
                                expLevel: [],
                                selectedCountryCode: '',
                              ),
                              pdfPathController: '',
                              expLevel: [],
                              getToken: '',
                            ),
                            registrationData: RegistrationData(
                              // Aquí debes proporcionar los valores adecuados para RegistrationData
                              userId: '',
                              displayName: '',
                              idCardNumber: '',
                              phoneNumber: '',
                              paymentType: '',

                              expertises: [],
                              imagePath: '',
                              location: {},
                              idDocumentImagePath: '',
                              email: '',
                              imagePathList: [], idDocumentImagePath2: '',
                              criminalRecordImagePath: '',
                              certificateImagePaths: [],
                              expLevel: [],
                              selectedCountryCode: '',
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Error al obtener datos del usuario: $e');
                    }
                  }
                },
                icon: const Icon(Icons.person, color: Color(0xFF84090D)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Perfil",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84090D),
                      fontFamily: 'Xpress',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReferralScreen(
                              referralCode: '12345',
                            )),
                  );
                },
                icon: const Icon(
                  Icons.share,
                  color: Color(0xFF84090D),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Referidos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84090D),
                      fontFamily: 'Xpress',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
                icon: const Icon(
                  Icons.help,
                  color: Color(0xFF84090D),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Ayuda",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84090D),
                      fontFamily: 'Xpress',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpScreen()),
                  );
                },
                icon: const Icon(
                  Icons.help,
                  color: Color(0xFF84090D),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Ficha de Ingreso",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF84090D),
                      fontFamily: 'Xpress',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil

              GestureDetector(
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: "ManitoXpress",
                    applicationVersion: "1.0.0",
                    applicationIcon: Image.asset(
                      'assets/images/manitoxpress_logo.png',
                      width: 10.w, // Cambiado a screenutil
                      height: 10.h, // Cambiado a screenutil
                    ),
                    children: const [
                      Text(
                        "Esta es una aplicación Demo",
                        style: TextStyle(
                          fontFamily: 'Xpress Heavy',
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                },
                child: Text(
                  "Versión",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'Xpress',
                  ),
                ),
              ),
              SizedBox(height: 3.h), // Cambiado a screenutil
            ],
          ),
        ),
      ),
       body: PageView(
        controller: _pageController,
        children: _buildScreens(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: 'Servicios',
            backgroundColor: Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: 'Favoritos',
            backgroundColor: Color(0xFF1A819A),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            label: 'SOLICITUDES',
            backgroundColor: Color.fromARGB(166, 50, 196, 233),
          ),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Color.fromARGB(255, 230, 121, 121),
        selectedLabelStyle: MyTextStyles.navBarTextStyle,
        unselectedLabelStyle: MyTextStyles.navBarTextStyle,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Color.fromARGB(255, 230, 121, 121)),
        backgroundColor: const Color.fromARGB(255, 183, 21, 10),
      ),
    );
  }

  void _refreshHistorial() {
    // Actualiza el historial aquí
    // Puedes implementar la lógica para actualizar los datos desde el backend
  }
}
