import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/ServiceResponse/post.dart';
import 'package:socio/ServiceResponse/requestUserData.dart';

import '../Controller/RegisController.dart';
import '../Screens/Validations.dart';
import '../ServiceResponse/get.dart';
import '../Utils/styles.dart';
class FirstTimeLoginScreen extends StatelessWidget {
  final RegistrationController registrationController;
  final UserData userData; // 👉 Agregado

  const FirstTimeLoginScreen({
    Key? key,
    required this.registrationController,
    required this.userData, // 👉 Requerido
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ManitoXpress',
              style: MyTextStyles.buttonTextStyle,
            ),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.22.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.22.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/manito.png',
                width: 300,
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Bienvenido!',
                style: MyTextStyles.welcomeTotheJungle2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Presiona "Comenzar registro" para crear la cuenta',
                style: MyTextStyles.drawerButtonTextStyle3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  registrationController.nextStep();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationScreen(
                        registrationController: registrationController,
                        completeRegistrationCallback: () {},
                        apiService2: ApiService2(),
                        apiService: ApiService(),
                        userData: userData, // 👉 Pasar userData a la siguiente pantalla
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  backgroundColor: const Color(0xFF84090D),
                ),
                child: const Text(
                  'Comenzar registro',
                  style: MyTextStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
