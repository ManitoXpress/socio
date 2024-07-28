import 'package:flutter/material.dart';
import 'package:socio/Metods/RegisController.dart';
import 'package:socio/Screens/Validations.dart';
import 'package:socio/ServiceResponse/get.dart';
import 'package:socio/Utils/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FirstTimeLoginScreen extends StatelessWidget {
  final RegistrationController registrationController;

  FirstTimeLoginScreen({required this.registrationController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bienvenido',
          style: MyTextStyles.buttonTextStyle.copyWith(fontSize: 22.sp), // Ajusta el tamaño del texto para el AppBar
        ),
        toolbarHeight: 80.h, // Ajusta la altura del AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Imagen
            Image.asset(
              'assets/manito.png', // Reemplaza 'your_image.png' con la ruta de tu imagen
              width: 0.5.sw, // Ajusta el ancho de la imagen según sea necesario
            ),
            SizedBox(height: 20.h), // Espacio entre la imagen y el texto
            Text(
              '¡Bienvenido!',
              style: MyTextStyles.welcomeTotheJungle.copyWith(fontSize: 24.sp), // Ajusta el tamaño del texto
            ),
            SizedBox(height: 20.h), // Espacio entre los textos
            Text(
              'Presiona "Comenzar registro" para crear la cuenta',
              style: MyTextStyles.drawerButtonTextStyle2.copyWith(fontSize: 16.sp), // Ajusta el tamaño del texto
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h), // Espacio entre el texto y el botón
            ElevatedButton(
              onPressed: () {
                // Iniciar el proceso de registro
                print("Comenzar registro presionado"); // Agrega esta línea para depurar
                registrationController.nextStep();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(
                      registrationController: registrationController,
                      completeRegistrationCallback: () {},
                      apiService2: ApiService2(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h), // Ajusta el tamaño del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r), // Bordes redondeados
                ),
                backgroundColor: Color(0xFF84090D), // Color personalizado
              ),
              child: Text(
                'Comenzar registro',
                style: MyTextStyles.buttonTextStyle.copyWith(fontSize: 18.sp), // Ajusta el tamaño del texto del botón
              ),
            ),
          ],
        ),
      ),
    );
  }
}