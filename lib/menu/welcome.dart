import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socio/ServiceResponse/post.dart';

import '../Controller/RegisController.dart';
import '../Screens/Validations.dart';
import '../ServiceResponse/get.dart';
import '../Utils/styles.dart';

class FirstTimeLoginScreen extends StatelessWidget {
  final RegistrationController registrationController;

  FirstTimeLoginScreen({required this.registrationController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribuir elementos
          children: [
            // Texto en la parte izquierda
            Text(
              'ManitoXpress',
              style: MyTextStyles.buttonTextStyle,
            ),
            // Logo en la parte derecha
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
        color: Colors.white, // Fondo blanco de la pantalla
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Imagen
              Image.asset(
                'assets/images/manito.png', 
                width: 300, 
              ),
              const SizedBox(height: 20), 
              const Text(
                '¡Bienvenido!',
                style: MyTextStyles.welcomeTotheJungle2,
              ),
              const SizedBox(height: 20), // Espacio entre los textos
              const Text(
                'Presiona "Comenzar registro" para crear la cuenta',
                style: MyTextStyles.drawerButtonTextStyle3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // Espacio entre el texto y el botón
              ElevatedButton(
                onPressed: () {
                  // Iniciar el proceso de registro
                  print("Comenzar registro presionado");

                  registrationController.nextStep();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationScreen(
                        registrationController: registrationController,
                        completeRegistrationCallback: () {},
                        apiService2: ApiService2(), apiService: ApiService(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16), // Ajusta el tamaño del botón
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30.0), // Bordes redondeados
                  ),
                  backgroundColor:
                      const Color(0xFF84090D), // Color personalizado
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
