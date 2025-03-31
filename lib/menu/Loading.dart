
import 'package:flutter/material.dart';


class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image.asset(
            'assets/pantallaTrabajador.png',
            fit: BoxFit.fill,  // Ajusta la imagen al tamaño de la pantalla
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
